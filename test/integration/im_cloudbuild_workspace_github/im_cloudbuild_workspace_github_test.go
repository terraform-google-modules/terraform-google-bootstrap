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
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/google/go-github/v66/github"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-google-modules/terraform-google-bootstrap/test/integration/utils"
)

type GitHubClient struct {
	t          *testing.T
	client     *github.Client
	owner      string
	repoName   string
	repository *github.Repository
}

func NewGitHubClient(t *testing.T, token, owner, repo string) *GitHubClient {
	t.Helper()
	client := github.NewClient(nil).WithAuthToken(token)
	return &GitHubClient{
		t:        t,
		client:   client,
		owner:    owner,
		repoName: repo,
	}
}

// GetOpenPullRequest gets an open pull request for a given branch if it exists.
func (gh *GitHubClient) GetOpenPullRequest(ctx context.Context, branch string) *github.PullRequest {
	opts := &github.PullRequestListOptions{
		State: "open",
		Head:  branch,
	}
	prs, resp, err := gh.client.PullRequests.List(ctx, gh.owner, gh.repoName, opts)
	if resp.StatusCode != 422 && err != nil {
		gh.t.Fatal(err.Error())
	}
	if len(prs) == 0 {
		return nil
	}
	return prs[0]
}

func (gh *GitHubClient) CreatePullRequest(ctx context.Context, title, branch, base string) *github.PullRequest {
	newPR := &github.NewPullRequest{
		Title: github.String(title),
		Head:  github.String(branch),
		Base:  github.String(base),
	}
	pr, _, err := gh.client.PullRequests.Create(ctx, gh.owner, gh.repoName, newPR)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return pr
}

func (gh *GitHubClient) MergePullRequest(ctx context.Context, pr *github.PullRequest, commitTitle, commitMessage string) *github.PullRequestMergeResult {
	result, _, err := gh.client.PullRequests.Merge(ctx, gh.owner, gh.repoName, *pr.Number, commitMessage, nil)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return result
}

func (gh *GitHubClient) ClosePullRequest(ctx context.Context, pr *github.PullRequest) {
	pr.State = github.String("closed")
	_, _, err := gh.client.PullRequests.Edit(ctx, gh.owner, gh.repoName, *pr.Number, pr)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
}

func (gh *GitHubClient) GetRepository(ctx context.Context) *github.Repository {
	repo, resp, err := gh.client.Repositories.Get(ctx, gh.owner, gh.repoName)
	if resp.StatusCode != 404 && err != nil {
		gh.t.Fatal(err.Error())
	}
	gh.repository = repo
	return repo
}

func (gh *GitHubClient) CreateRepository(ctx context.Context, org, repoName string) *github.Repository {
	newRepo := &github.Repository{
		Name:       github.String(repoName),
		AutoInit:   github.Bool(true),
		Visibility: github.String("private"),
	}
	repo, _, err := gh.client.Repositories.Create(ctx, org, newRepo)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	gh.repository = repo
	return repo
}

func (gh *GitHubClient) AddFileToRepository(ctx context.Context, file []byte) {
	opts := &github.RepositoryContentFileOptions{
		Content: file,
		Message: github.String("Setup commit"),
	}
	_, _, err := gh.client.Repositories.CreateFile(ctx, gh.owner, gh.repoName, "main.tf", opts)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
}

func (gh *GitHubClient) DeleteRepository(ctx context.Context) {
	_, err := gh.client.Repositories.Delete(ctx, gh.owner, *gh.repository.Name)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
}

func TestIMCloudBuildWorkspaceGitHub(t *testing.T) {
	ctx := context.Background()

	githubPAT := cftutils.ValFromEnv(t, "IM_GITHUB_PAT")
	client := NewGitHubClient(t, githubPAT, "im-goose", fmt.Sprintf("im-blueprint-test-%s", utils.GetRandomStringFromSetup(t)))

	repo := client.GetRepository(ctx)
	if repo == nil {
		client.CreateRepository(ctx, client.owner, client.repoName)
		client.AddFileToRepository(ctx, utils.GetFileContents(t, "files/main.tf"))
	}

	// Testing the module's feature of appending the ".git" suffix if it's missing
	repoURL := strings.TrimSuffix(client.repository.GetCloneURL(), ".git")
	vars := map[string]interface{}{
		"im_github_pat":  githubPAT,
		"repository_url": repoURL,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		t.Cleanup(func() {
			// Close the preview pull request if it was still left open
			pr := client.GetOpenPullRequest(ctx, "preview")
			if pr != nil {
				client.ClosePullRequest(ctx, pr)
			}
			// Delete the repository if we hit a failed state
			if t.Failed() {
				client.DeleteRepository(ctx)
			}
		})

		projectID := bpt.GetStringOutput("project_id")
		secretID := bpt.GetStringOutput("github_secret_id")
		triggerLocation := "us-central1"
		repoURLSplit := strings.Split(client.repository.GetCloneURL(), "/")

		// CB P4SA IAM
		projectNum := gcloud.Runf(t, "projects describe %s --format='value(projectNumber)'", projectID).Get("projectNumber")
		iamOP := gcloud.Runf(t, "secrets get-iam-policy %s --project %s --flatten bindings --filter bindings.members:'serviceAccount:service-%s@gcp-sa-cloudbuild.iam.gserviceaccount.com'", secretID, projectID, projectNum).Array()
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
		gitRun("clone", fmt.Sprintf("https://%s@github.com/%s/%s", githubPAT, user, repo), tmpDir)
		gitRun("config", "user.email", "tf-robot@example.com")
		gitRun("config", "user.name", "TF Robot")

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
						t.Logf("%v", build[0])
						t.Fatalf("workflow %s failed with failureInfo %s", build[0].Get("id"), build[0].Get("failureInfo"))
					}
					return true, nil
				}
			}
			cftutils.Poll(t, pollCloudBuild(buildListCmd), 20, 10*time.Second)
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
			client.DeleteRepository(ctx)
			bpt.DefaultTeardown(assert)
		})
		projectID := bpt.GetStringOutput("project_id")
		gcloud.Runf(t, "infra-manager deployments delete projects/%s/locations/us-central1/deployments/im-example-github-deployment --project %s --quiet", projectID, projectID)
	})

	bpt.Test()
}
