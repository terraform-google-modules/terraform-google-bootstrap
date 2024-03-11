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

package im_cloudbuild_workspace_github

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/google/go-github/v60/github"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
)

type GitHubClient struct {
	t      *testing.T
	client *github.Client
	owner  string
	repo   string
}

func NewGitHubClient(t *testing.T, token, owner, repo string) *GitHubClient {
	t.Helper()
	client := github.NewClient(nil).WithAuthToken(token)
	return &GitHubClient{
		t:      t,
		client: client,
		owner:  owner,
		repo:   repo,
	}
}

// GetOpenPullRequest gets an open pull request for a given branch if it exists.
func (gh *GitHubClient) GetOpenPullRequest(ctx context.Context, branch string) *github.PullRequest {
	opts := &github.PullRequestListOptions{
		State: "open",
		Base:  branch,
	}
	prs, _, err := gh.client.PullRequests.List(ctx, gh.owner, gh.repo, opts)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	if len(prs) == 0 {
		return nil
	}
	return prs[0]
}

func (gh *GitHubClient) CreatePullRequest(ctx context.Context, title, branch, base string) *github.PullRequest {
	newPR := &github.NewPullRequest{
		Title: &title,
		Head:  &branch,
		Base:  &base,
	}
	pr, _, err := gh.client.PullRequests.Create(ctx, gh.owner, gh.repo, newPR)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return pr
}

func (gh *GitHubClient) MergePullRequest(ctx context.Context, pr *github.PullRequest, commitTitle, commitMessage string) *github.PullRequestMergeResult {
	result, _, err := gh.client.PullRequests.Merge(ctx, gh.owner, gh.repo, *pr.Number, commitMessage, nil)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return result
}

func (gh *GitHubClient) ClosePullRequest(ctx context.Context, pr *github.PullRequest) {
	updatedState := "closed"
	pr.State = &updatedState
	_, _, err := gh.client.PullRequests.Edit(ctx, gh.owner, gh.repo, *pr.Number, pr)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
}

func TestIMCloudBuildWorkspaceGitHub(t *testing.T) {
	var ctx = context.Background()
	githubPAT := utils.ValFromEnv(t, "IM_GITHUB_PAT")
	vars := map[string]interface{}{
		"im_github_pat": githubPAT,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		projectID := bpt.GetStringOutput("project_id")
		triggerLocation := bpt.GetStringOutput("trigger_location")
		repoURL := bpt.GetStringOutput("repo_url")
		repoURLSplit := strings.Split(repoURL, "/")

		// cloud build triggers
		triggers := []string{"preview", "apply"}
		for _, trigger := range triggers {
			triggerOP := lastElem(bpt.GetStringOutput(fmt.Sprintf("cloudbuild_%s_trigger_id", trigger)), "/")
			cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --project %s --region %s", triggerOP, projectID, triggerLocation)
			assert.Equal(fmt.Sprintf("im-infra-manager-git-example-%s", trigger), cloudBuildOP.Get("name").String(), "has the correct name")
			assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/cb-sa-infra-manager-git-exampl@%s.iam.gserviceaccount.com", projectID, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
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
		gitRun("clone", fmt.Sprintf("https://%s@github.com/%s/%s", githubPAT, user, repo), tmpDir)
		gitRun("config", "user.email", "tf-robot@example.com")
		gitRun("config", "user.name", "TF Robot")

		client := NewGitHubClient(t, githubPAT, user, repo)

		// push commits on preview and main branches
		// preview branch should trigger preview trigger
		// main branch should trigger apply trigger
		var pullRequest *github.PullRequest
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
				gitRun("push", "--set-upstream", "origin", branch, "-f")

				// Close existing pull requests (if they exist)
				pr := client.GetOpenPullRequest(ctx, branch)
				if pr != nil {
					client.ClosePullRequest(ctx, pr)
				}
				pullRequest = client.CreatePullRequest(ctx, "preview PR", branch, "main")
				lastCommit = git.GetLatestCommit()
			case "main":
				mergedPr := client.MergePullRequest(ctx, pullRequest, "main commit", "main message")
				lastCommit = *mergedPr.SHA
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
						return false, nil
					}
					if latestWorkflowRunStatus == "TIMEOUT" || latestWorkflowRunStatus == "FAILURE" {
						t.Errorf("workflow %s failed with status %s", build[0].Get("id"), latestWorkflowRunStatus)
						return false, nil
					}
					return true, nil
				}
			}
			utils.Poll(t, pollCloudBuild(buildListCmd), 20, 10*time.Second)
			build := gcloud.Run(t, buildListCmd, gcloud.WithLogger(logger.Discard)).Array()[0]

			switch branch {
			case "preview":
				assert.Equal(previewTrigger, build.Get("buildTriggerId").String(), "was triggered by preview trigger")
			case "main":
				assert.Equal(applyTrigger, build.Get("buildTriggerId").String(), "was triggered by apply trigger")
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
