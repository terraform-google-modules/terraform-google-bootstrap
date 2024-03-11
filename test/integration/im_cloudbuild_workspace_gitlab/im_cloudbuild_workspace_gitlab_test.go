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
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/xanzy/go-gitlab"
)

type GitLabClient struct {
	t      *testing.T
	client *gitlab.Client
	owner  string
	repo   string
}

func NewGitLabClient(t *testing.T, token, owner, repo string) *GitLabClient {
	t.Helper()
	client, err := gitlab.NewClient(token)
	if err != nil {
		t.Fatalf(err.Error())
	}
	return &GitLabClient{
		t:      t,
		client: client,
		owner:  owner,
		repo:   repo,
	}
}

func (gl *GitLabClient) ProjectName() string {
	return fmt.Sprintf("%s/%s", gl.owner, gl.repo)
}

// GetOpenMergeRequest gets an open merge request for a given branch if it exists.
func (gl *GitLabClient) GetOpenMergeRequest(branch string) *gitlab.MergeRequest {
	state := "opened"
	opts := gitlab.ListProjectMergeRequestsOptions{
		State:        &state,
		SourceBranch: &branch,
	}
	mergeRequests, _, err := gl.client.MergeRequests.ListProjectMergeRequests(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatalf(err.Error(), err)
	}
	if len(mergeRequests) == 0 {
		return nil
	}
	return mergeRequests[len(mergeRequests)-1]
}

func (gl *GitLabClient) CreateMergeRequest(title, branch, base string) *gitlab.MergeRequest {
	squash := true
	opts := gitlab.CreateMergeRequestOptions{
		Title:        &title,
		SourceBranch: &branch,
		TargetBranch: &base,
		Squash:       &squash,
	}
	mergeRequest, _, err := gl.client.MergeRequests.CreateMergeRequest(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatalf(err.Error(), err)
	}
	return mergeRequest
}

func (gl *GitLabClient) CloseMergeRequest(mr *gitlab.MergeRequest) {
	stateEvent := "close"
	opts := gitlab.UpdateMergeRequestOptions{
		StateEvent: &stateEvent,
	}
	_, _, err := gl.client.MergeRequests.UpdateMergeRequest(gl.ProjectName(), mr.IID, &opts)
	if err != nil {
		gl.t.Fatalf(err.Error(), err)
	}
}

func (gl *GitLabClient) AcceptMergeRequest(mr *gitlab.MergeRequest, commitMessage string) *gitlab.MergeRequest {
	squash := true
	removeSourceBranch := true
	opts := gitlab.AcceptMergeRequestOptions{
		Squash:                   &squash,
		SquashCommitMessage:      &commitMessage,
		ShouldRemoveSourceBranch: &removeSourceBranch,
	}
	merged, resp, err := gl.client.MergeRequests.AcceptMergeRequest(gl.ProjectName(), mr.IID, &opts)
	if err != nil {
		gl.t.Fatalf(err.Error(), err)
	}
	if resp.StatusCode != 200 {
		gl.t.Fatalf("failed to accept merge request %v", resp)
	}
	return merged
}

func TestIMCloudBuildWorkspaceGitLab(t *testing.T) {
	gitlabPAT := utils.ValFromEnv(t, "IM_GITLAB_PAT")
	vars := map[string]interface{}{
		"im_gitlab_pat": gitlabPAT,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		projectID := bpt.GetStringOutput("project_id")
		// deploymentID := bpt.GetStringOutput("deployment_id")
		// deploymentLocation := bpt.GetStringOutput("location")
		triggerLocation := bpt.GetStringOutput("trigger_location")
		repoURL := bpt.GetStringOutput("repo_url")
		repoURLSplit := strings.Split(repoURL, "/")

		// Clean up IM deployment after test finishes
		//t.Cleanup(func() {
		// jgcloud.Runf(t, "infra-manager deployments delete projects/%s/locations/%s/deployments/%s --project %s --quiet", projectID, deploymentLocation, deploymentID, projectID)
		//})

		// cloud build triggers
		triggers := []string{"preview", "apply"}
		for _, trigger := range triggers {
			triggerOP := lastElem(bpt.GetStringOutput(fmt.Sprintf("cloudbuild_%s_trigger_id", trigger)), "/")
			cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --project %s --region %s", triggerOP, projectID, triggerLocation)
			assert.Equal(fmt.Sprintf("im-im-git-ci-cd-%s", trigger), cloudBuildOP.Get("name").String(), "has the correct name")
			assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/cb-sa-im-git-ci-cd@%s.iam.gserviceaccount.com", projectID, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
		}

		// CB SA IAM
		cbSA := lastElem(bpt.GetStringOutput("cloudbuild_sa"), "/")
		iamOP := gcloud.Runf(t, "projects get-iam-policy %s --flatten bindings --filter bindings.members:'serviceAccount:%s'", projectID, cbSA).Array()
		utils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/config.admin")

		// IM SA IAM
		imSA := lastElem(bpt.GetStringOutput("infra_manager_sa"), "/")
		iamOP = gcloud.Runf(t, "projects get-iam-policy %s --flatten bindings --filter bindings.members:'serviceAccount:%s'", projectID, imSA).Array()
		utils.GetFirstMatchResult(t, iamOP, "bindings.role", "roles/config.agent")

		// e2e test for testing actuation through both preview/apply branches
		previewTrigger := lastElem(bpt.GetStringOutput("cloudbuild_preview_trigger_id"), "/")
		applyTrigger := lastElem(bpt.GetStringOutput("cloudbuild_apply_trigger_id"), "/")

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
		gitRun("clone", fmt.Sprintf("https://%s@gitlab.com/%s/%s", gitlabPAT, user, repo), tmpDir)
		gitRun("config", "user.email", "tf-robot@example.com")
		gitRun("config", "user.name", "TF Robot")

		client := NewGitLabClient(t, gitlabPAT, user, repo)

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

				// Close existing pull requests (if they exist)
				mr := client.GetOpenMergeRequest(branch)
				if mr != nil {
					client.CloseMergeRequest(mr)
				}

				gitRun("push", "-u", fmt.Sprintf("https://gitlab-bot:%s@gitlab.com/%s/%s.git", gitlabPAT, user, repo), branch, "-f")
				mergeRequest = client.CreateMergeRequest("preview PR", branch, "main")
				lastCommit = git.GetLatestCommit()
			case "main":
				client.AcceptMergeRequest(mergeRequest, "commit message")
				gitRun("checkout main")
				gitRun("pull")
				lastCommit = git.GetLatestCommit()
				// lastCommit = mr.SHA
			}

			// filter builds triggered based on pushed commit sha
			buildListCmd := fmt.Sprintf("builds list --filter substitutions.COMMIT_SHA='%s' --project %s --region %s --limit 1", lastCommit, projectID, triggerLocation)
			// poll build until complete
			pollCloudBuild := func(cmd string) func() (bool, error) {
				t.Logf("josephdthomas - Beginning polling for build related to commit %s", lastCommit)
				return func() (bool, error) {
					build := gcloud.Run(t, cmd, gcloud.WithLogger(logger.Discard)).Array()
					if len(build) < 1 {
						return true, nil
					}

					t.Logf("josephdthomas - logging builds")
					t.Logf("%d", len(build))

					latestWorkflowRunStatus := build[0].Get("status").String()
					if latestWorkflowRunStatus == "SUCCESS" {
						t.Logf("josephdthomas - logging the build at end of polling")
						t.Logf("%v", build)
						return false, nil
					}
					if latestWorkflowRunStatus == "TIMEOUT" || latestWorkflowRunStatus == "FAILURE" {
						t.Logf("josephdthomas - logging the failed build at end of polling")
						t.Logf("%v", build)
						t.Errorf("workflow %s failed with status %s", build[0].Get("id"), latestWorkflowRunStatus)
						return false, nil
					}
					return true, nil
				}
			}
			utils.Poll(t, pollCloudBuild(buildListCmd), 20, 15*time.Second)
			build := gcloud.Run(t, buildListCmd, gcloud.WithLogger(logger.Discard)).Array()[0]

			t.Logf("josephdthomas - logging build selected at end")
			t.Logf("%v", build)

			switch branch {
			case "preview":
				assert.Equal(previewTrigger, build.Get("buildTriggerId").String(), "was triggered by preview trigger")
				// TODO What else to test about the triggers?
			case "main":
				assert.Equal(applyTrigger, build.Get("buildTriggerId").String(), "was triggered by apply trigger")
				// TODO What else to test about the triggers?
			}
		}
	})

	bpt.Test()
}

// lastElem gets the last element in a string separated by sep.
// Typically used to grab a resource ID from a full resource name.
func lastElem(name, sep string) string {
	return strings.Split(name, sep)[len(strings.Split(name, sep))-1]
}
