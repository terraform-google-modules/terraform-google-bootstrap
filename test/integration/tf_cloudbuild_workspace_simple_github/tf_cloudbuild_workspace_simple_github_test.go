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

package tf_cloudbuild_workspace_simple_github

import (
	"context"
	"fmt"
	"path"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-google-modules/terraform-google-bootstrap/test/integration/utils"
)

const (
	githubRepo = "cb-bp-gh"
)

func TestCloudBuildWorkspaceSimpleGitHub(t *testing.T) {
	ctx := context.Background()
	githubPAT := cftutils.ValFromEnv(t, "IM_GITHUB_PAT")
	client := utils.NewGitHubClient(t, githubPAT, githubRepo)
	client.GetRepository(ctx)

	// Testing the module's feature of appending the ".git" suffix if it's missing
	repoURL := strings.TrimSuffix(client.Repository.GetCloneURL(), ".git")
	vars := map[string]interface{}{
		"github_pat":     githubPAT,
		"repository_uri": repoURL,
		"github_app_id":  utils.GitHubAppID,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		location := bpt.GetStringOutput("location")
		projectID := bpt.GetStringOutput("project_id")

		// cloud build triggers
		triggers := []string{"plan", "apply"}
		for _, trigger := range triggers {
			triggerOP := utils.LastElement(bpt.GetStringOutput(fmt.Sprintf("cloudbuild_%s_trigger_id", trigger)), "/")
			cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --region %s --project %s", triggerOP, location, projectID)
			assert.Equal(fmt.Sprintf("%s-%s", githubRepo, trigger), cloudBuildOP.Get("name").String(), "should have the correct name")
			assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/tf-gh-%s@%s.iam.gserviceaccount.com", projectID, githubRepo, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
		}

		// artifacts, state and log buckets
		logsBucket := utils.LastElement(bpt.GetStringOutput("logs_bucket"), "/")
		stateBucket := utils.LastElement(bpt.GetStringOutput("state_bucket"), "/")
		artifactsBucket := utils.LastElement(bpt.GetStringOutput("artifacts_bucket"), "/")
		buckets := []string{artifactsBucket, logsBucket, stateBucket}
		for _, bucket := range buckets {
			// we can't use runf since we need to override --format json with --json for alpha storage
			bucketOP := gcloud.Run(t, fmt.Sprintf("alpha storage ls --buckets gs://%s", bucket), gcloud.WithCommonArgs([]string{"--project", projectID, "--json"})).Array()
			assert.Equalf(1, len(bucketOP), "%s bucket should exist", bucket)
			assert.Truef(bucketOP[0].Get("metadata.iamConfiguration.uniformBucketLevelAccess.enabled").Bool(), "%s bucket uniformBucketLevelAccess should be enabled", bucket)
			assert.Truef(bucketOP[0].Get("metadata.versioning.enabled").Bool(), "%s bucket versioning should be enabled", bucket)
		}

		// CB SA IAM
		cbSA := utils.LastElement(bpt.GetStringOutput("cloudbuild_sa"), "/")
		iamOP := gcloud.Runf(t, "projects get-iam-policy %s --flatten bindings --filter bindings.members:'serviceAccount:%s'", projectID, cbSA).Array()
		cftutils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/compute.networkAdmin")

		// e2e test for testing actuation through both plan/apply branches
		applyTrigger := utils.LastElement(bpt.GetStringOutput("cloudbuild_apply_trigger_id"), "/")
		planTrigger := utils.LastElement(bpt.GetStringOutput("cloudbuild_plan_trigger_id"), "/")

		// set up repo
		tmpDir := t.TempDir()
		git := git.NewCmdConfig(t, git.WithDir(tmpDir))
		gitRun := func(args ...string) {
			_, err := git.RunCmdE(args...)
			if err != nil {
				t.Fatal(err)
			}
		}

		gitRun("clone", fmt.Sprintf("https://%s@github.com/%s/%s", githubPAT, utils.GitHubOwner, githubRepo), tmpDir)
		gitRun("config", "user.email", "tf-robot@example.com")
		gitRun("config", "user.name", "TF Robot")

		// push commits on plan and main branches
		// plan branch should trigger plan trigger
		// main branch should trigger apply trigger
		branches := []string{"plan", "main"}
		for _, branch := range branches {
			_, err := git.RunCmdE("checkout", branch)
			if err != nil {
				git.RunCmdE("checkout", "-b", branch)
			}
			git.CommitWithMsg(fmt.Sprintf("%s commit", branch), []string{"--allow-empty"})
			gitRun("push", "--set-upstream", "origin", branch, "-f")
			lastCommit := git.GetLatestCommit()
			// filter builds triggered based on pushed commit sha
			buildListCmd := fmt.Sprintf("builds list --filter substitutions.COMMIT_SHA='%s' --region %s --project %s --limit 1 --sort-by ~createTime", lastCommit, location, projectID)
			// poll build until complete
			pollCloudBuild := func(cmd string) func() (bool, error) {
				return func() (bool, error) {
					build := gcloud.Runf(t, cmd).Array()
					if len(build) < 1 {
						return true, nil
					}
					latestWorkflowRunStatus := build[0].Get("status").String()
					if latestWorkflowRunStatus == "SUCCESS" {
						return false, nil
					}
					if latestWorkflowRunStatus == "TIMEOUT" || latestWorkflowRunStatus == "FAILURE" {
						t.Logf("%v", build[0])
						t.Fatalf("workflow %s failed with failureInfo %s", build[0].Get("id"), build[0].Get("failureInfo"))
					}
					return true, nil
				}
			}
			cftutils.Poll(t, pollCloudBuild(buildListCmd), 20, 10*time.Second)
			build := gcloud.Runf(t, buildListCmd).Array()[0]
			switch branch {
			case "plan":
				assert.Equal(planTrigger, build.Get("buildTriggerId").String(), "was triggered by plan trigger")
				assert.Contains(build.Get("artifacts.objects.location").String(), path.Join(artifactsBucket, "plan"), "artifacts were uploaded to the correct location")
			case "main":
				assert.Equal(applyTrigger, build.Get("buildTriggerId").String(), "was triggered by apply trigger")
				assert.Contains(build.Get("artifacts.objects.location").String(), path.Join(artifactsBucket, "apply"), "artifacts were uploaded to the correct location")
			}
		}
	})

	bpt.DefineTeardown(func(assert *assert.Assertions) {
		// Guarantee clean up even if the normal gcloud/teardown run into errors
		t.Cleanup(func() {
			bpt.DefaultTeardown(assert)
		})
	})

	bpt.Test()
}
