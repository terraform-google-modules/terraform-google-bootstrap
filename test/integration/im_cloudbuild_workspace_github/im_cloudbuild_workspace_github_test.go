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
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/cli/go-gh/v2/pkg/api"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
)

type PullRequest struct {
	Url    string `json:"url"`
	ID     int    `json:"id"`
	State  string `json:"state"`
	Number int    `json:"number"`
}

type MergedPullRequestResponse struct {
	SHA     string `json:"sha"`
	Merged  bool   `json:"merged"`
	Message string `json:"messsage"`
}

type GitHubClient struct {
	t      *testing.T
	client *api.RESTClient
	owner  string
	repo   string
}

func NewGitHubClient(t *testing.T, token, owner, repo string) *GitHubClient {
	t.Helper()
	opts := api.ClientOptions{
		Host:      "github.com",
		AuthToken: token,
	}
	client, err := api.NewRESTClient(opts)
	if err != nil {
		t.Fatalf(err.Error())
	}
	return &GitHubClient{
		t:      t,
		client: client,
		owner:  owner,
		repo:   repo,
	}
}

// GetOpenPullRequest gets an open pull request for a given branch if it exists.
func (gh *GitHubClient) GetOpenPullRequest(branch string) *PullRequest {
	resp := []PullRequest{}
	path := fmt.Sprintf("repos/%s/%s/pulls?state=open&head=%s", gh.owner, gh.repo, branch)
	err := gh.client.Get(path, &resp)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	if len(resp) == 0 {
		return nil
	}
	// There should only be single pull request for a specified HEAD branch
	return &resp[len(resp)-1]
}

func (gh *GitHubClient) CreatePullRequest(title, branch, base string) PullRequest {
	body := map[string]interface{}{
		"title": title,
		"head":  branch,
		"base":  "main",
	}
	jsonBody, err := json.Marshal(body)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	resp := PullRequest{}
	err = gh.client.Post(fmt.Sprintf("repos/%s/%s/pulls", gh.owner, gh.repo), bytes.NewBuffer(jsonBody), &resp)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	return resp
}

func (gh *GitHubClient) ClosePullRequest(pr *PullRequest) {
	body := map[string]interface{}{
		"state": "closed",
	}
	jsonBody, err := json.Marshal(body)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	_, err = gh.client.Request(http.MethodPatch, fmt.Sprintf("repos/%s/%s/pulls/%d", gh.owner, gh.repo, pr.Number), bytes.NewBuffer(jsonBody))
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
}

func (gh *GitHubClient) MergePullRequest(pr *PullRequest, commitTitle, commitMessage string) MergedPullRequestResponse {
	body := map[string]interface{}{
		"commit_title":   commitTitle,
		"commit_message": commitMessage,
	}
	jsonBody, err := json.Marshal(body)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	resp := MergedPullRequestResponse{}
	err = gh.client.Put(fmt.Sprintf("repos/%s/%s/pulls/%d/merge", gh.owner, gh.repo, pr.Number), bytes.NewBuffer(jsonBody), &resp)
	if err != nil {
		gh.t.Fatalf(err.Error(), err)
	}
	return resp
}

func TestIMCloudBuildWorkspaceGitHub(t *testing.T) {
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
		var pullRequest PullRequest
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
				pr := client.GetOpenPullRequest(branch)
				if pr != nil {
					client.ClosePullRequest(pr)
				}
				pullRequest = client.CreatePullRequest("preview PR", branch, "main")
				lastCommit = git.GetLatestCommit()
			case "main":
				mergedPr := client.MergePullRequest(&pullRequest, "main commit", "main message")
				lastCommit = mergedPr.SHA
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
					return true, nil
				}
			}
			utils.Poll(t, pollCloudBuild(buildListCmd), 20, 10*time.Second)
			build := gcloud.Run(t, buildListCmd, gcloud.WithLogger(logger.Discard)).Array()[0]

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
