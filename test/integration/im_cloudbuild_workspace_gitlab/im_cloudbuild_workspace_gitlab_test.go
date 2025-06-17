// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package im_cloudbuild_workspace_gitlab

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-google-modules/terraform-google-bootstrap/test/integration/utils"
	"github.com/xanzy/go-gitlab"
)

const (
	gitlabProjectName = "im-cloudbuild-workspace-gitlab"
)

func TestIMCloudBuildWorkspaceGitLab(t *testing.T) {
	gitlabPAT := cftutils.ValFromEnv(t, "IM_GITLAB_PAT")
	client := utils.NewGitLabClient(t, gitlabPAT, gitlabProjectName)
	client.GetProject()

	vars := map[string]interface{}{
		"im_gitlab_pat":  gitlabPAT,
		"repository_url": client.Project.HTTPURLToRepo,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		t.Cleanup(func() {
			// Close existing pull requests (if they exist)
			mr := client.GetOpenMergeRequest("preview")
			if mr != nil {
				client.CloseMergeRequest(mr)
			}
		})

		projectID := bpt.GetStringOutput("project_id")
		apiSecretID := bpt.GetStringOutput("gitlab_api_secret_id")
		readApiSecretID := bpt.GetStringOutput("gitlab_read_api_secret_id")
		triggerLocation := "us-central1"
		repoURLSplit := strings.Split(client.Project.HTTPURLToRepo, "/")

		// CB P4SA IAM for the two secrets
		projectNum := gcloud.Runf(t, "projects describe %s --format='value(projectNumber)'", projectID).Get("projectNumber")
		iamOP := gcloud.Runf(t, "secrets get-iam-policy %s --project %s --flatten bindings --filter bindings.members:'serviceAccount:service-%s@gcp-sa-cloudbuild.iam.gserviceaccount.com'", apiSecretID, projectID, projectNum).Array()
		cftutils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/secretmanager.secretAccessor")
		iamOP = gcloud.Runf(t, "secrets get-iam-policy %s --project %s --flatten bindings --filter bindings.members:'serviceAccount:service-%s@gcp-sa-cloudbuild.iam.gserviceaccount.com'", readApiSecretID, projectID, projectNum).Array()
		cftutils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/secretmanager.secretAccessor")

		// CB SA IAM
		cbSA := utils.LastElement(bpt.GetStringOutput("cloudbuild_sa"), "/")
		iamOP = gcloud.Runf(t, "projects get-iam-policy %s --flatten bindings --filter bindings.members:'serviceAccount:%s'", projectID, cbSA).Array()
		cftutils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/config.admin")

		// IM SA IAM
		imSA := utils.LastElement(bpt.GetStringOutput("infra_manager_sa"), "/")
		iamOP = gcloud.Runf(t, "projects get-iam-policy %s --flatten bindings --filter bindings.members:'serviceAccount:%s'", projectID, imSA).Array()
		cftutils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/config.agent")

		// e2e test for testing actuation through both preview/apply branches
		previewTrigger := utils.LastElement(bpt.GetStringOutput("cloudbuild_preview_trigger_id"), "/")
		applyTrigger := utils.LastElement(bpt.GetStringOutput("cloudbuild_apply_trigger_id"), "/")

		// set up repo
		tmpDir := t.TempDir()
		git := git.NewCmdConfig(t, git.WithDir(tmpDir))
		gitRun := func(args ...string) {
			_, err := git.RunCmdE(args...)
			if err != nil {
				t.Fatal(err)
			}
		}

		repo := strings.TrimSuffix(repoURLSplit[len(repoURLSplit)-1], ".git")
		user := repoURLSplit[len(repoURLSplit)-2]
		gitRun("clone", fmt.Sprintf("https://gitlab-bot:%s@gitlab.com/%s/%s", gitlabPAT, user, repo), tmpDir)
		gitRun("config", "user.email", "tf-robot@example.com")
		gitRun("config", "user.name", "TF Robot")

		// push commits on preview and main branches
		// preview branch should trigger preview trigger
		// main branch should trigger apply trigger
		var mergeRequest *gitlab.MergeRequest
		branches := []string{"preview", "main"}
		for _, branch := range branches {
			_, err := git.RunCmdE("checkout", branch)
			if err != nil {
				git.RunCmdE("checkout", "-b", branch)
			}

			var lastCommit string
			switch branch {
			case "preview":
				git.CommitWithMsg(fmt.Sprintf("%s commit", branch), []string{"--allow-empty"})
				gitRun("push", "-u", fmt.Sprintf("https://gitlab-bot:%s@gitlab.com/%s/%s.git", gitlabPAT, user, repo), branch, "-f")
				// Close existing pull requests (if they exist)
				mr := client.GetOpenMergeRequest(branch)
				if mr != nil {
					client.CloseMergeRequest(mr)
				}
				mergeRequest = client.CreateMergeRequest("preview PR", branch, "main")
				lastCommit = git.GetLatestCommit()
			case "main":
				client.AcceptMergeRequest(mergeRequest, "commit message")
				gitRun("pull")
				lastCommit = git.GetLatestCommit()
			}

			// filter builds triggered based on pushed commit sha
			buildListCmd := fmt.Sprintf("builds list --filter substitutions.COMMIT_SHA='%s' --project %s --region %s --limit 1", lastCommit, projectID, triggerLocation)
			// poll build until complete
			pollCloudBuild := func(cmd string) func() (bool, error) {
				return func() (bool, error) {
					build := gcloud.Run(t, cmd, gcloud.WithLogger(logger.Discard)).Array()
					if len(build) < 1 {
						return true, nil
					}

					latestWorkflowRunStatus := build[0].Get("status").String()
					if latestWorkflowRunStatus == "SUCCESS" {
						t.Logf("%v", build)
						return false, nil
					}
					if latestWorkflowRunStatus == "TIMEOUT" || latestWorkflowRunStatus == "FAILURE" {
						t.Logf("%v", build[0])
						t.Fatalf("workflow %s failed with status %s", build[0].Get("id"), latestWorkflowRunStatus)
						return false, nil
					}
					return true, nil
				}
			}
			cftutils.Poll(t, pollCloudBuild(buildListCmd), 40, 15*time.Second)
			build := gcloud.Run(t, buildListCmd, gcloud.WithLogger(logger.Discard)).Array()[0]

			switch branch {
			case "preview":
				assert.Equal(previewTrigger, build.Get("buildTriggerId").String(), "was triggered by preview trigger")
			case "main":
				assert.Equal(applyTrigger, build.Get("buildTriggerId").String(), "was triggered by apply trigger")
			}
		}
	})

	bpt.DefineTeardown(func(assert *assert.Assertions) {
		// Guarantee clean up even if the normal gcloud/teardown run into errors
		t.Cleanup(func() {
			bpt.DefaultTeardown(assert)
		})
		projectID := bpt.GetStringOutput("project_id")
		gcloud.Runf(t, "infra-manager deployments delete projects/%s/locations/us-central1/deployments/im-example-gitlab-deployment --project %s --quiet", projectID, projectID)
	})

	bpt.Test()
}
