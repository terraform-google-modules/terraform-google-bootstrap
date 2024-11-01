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

type GitLabClient struct {
	t         *testing.T
	client    *gitlab.Client
	group     string
	namespace int
	repo      string
	project   *gitlab.Project
}

func NewGitLabClient(t *testing.T, token, owner, repo string) *GitLabClient {
	t.Helper()
	client, err := gitlab.NewClient(token)
	if err != nil {
		t.Fatal(err.Error())
	}
	return &GitLabClient{
		t:         t,
		client:    client,
		group:     "infrastructure-manager",
		namespace: 84326276,
		repo:      repo,
	}
}

func (gl *GitLabClient) ProjectName() string {
	return fmt.Sprintf("%s/%s", gl.group, gl.repo)
}

func (gl *GitLabClient) GetProject() *gitlab.Project {
	proj, resp, err := gl.client.Projects.GetProject(gl.ProjectName(), nil)
	if resp.StatusCode != 404 && err != nil {
		gl.t.Fatalf("got status code %d, error %s", resp.StatusCode, err.Error())
	}
	gl.project = proj
	return proj
}

func (gl *GitLabClient) CreateProject() {
	opts := &gitlab.CreateProjectOptions{
		Name: gitlab.Ptr(gl.repo),
		// ID of the the Infrastructure Manager group (gitlab.com/infrastructure-manager)
		NamespaceID: gitlab.Ptr(84326276),
		// Required otherwise Cloud Build errors on creating the connection
		InitializeWithReadme: gitlab.Ptr(true),
	}
	proj, _, err := gl.client.Projects.CreateProject(opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	gl.project = proj
}

func (gl *GitLabClient) AddFileToProject(file []byte) {
	opts := &gitlab.CreateFileOptions{
		Branch:        gitlab.Ptr("main"),
		CommitMessage: gitlab.Ptr("Initial config commit"),
		Content:       gitlab.Ptr(string(file)),
	}
	_, _, err := gl.client.RepositoryFiles.CreateFile(gl.ProjectName(), "main.tf", opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
}

func (gl *GitLabClient) DeleteProject() {
	resp, err := gl.client.Projects.DeleteProject(gl.ProjectName(), utils.GetDeleteProjectOptions())
	if err != nil {
		gl.t.Errorf("error deleting project with status %s and error %s", resp.Status, err.Error())
	}
	gl.project = nil
}

// GetOpenMergeRequest gets the last opened merge request for a given branch if it exists.
func (gl *GitLabClient) GetOpenMergeRequest(branch string) *gitlab.MergeRequest {
	opts := gitlab.ListProjectMergeRequestsOptions{
		State:        gitlab.Ptr("opened"),
		SourceBranch: gitlab.Ptr(branch),
	}
	mergeRequests, _, err := gl.client.MergeRequests.ListProjectMergeRequests(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	if len(mergeRequests) == 0 {
		return nil
	}
	return mergeRequests[len(mergeRequests)-1]
}

func (gl *GitLabClient) CreateMergeRequest(title, branch, base string) *gitlab.MergeRequest {
	opts := gitlab.CreateMergeRequestOptions{
		Title:        gitlab.Ptr(title),
		SourceBranch: gitlab.Ptr(branch),
		TargetBranch: gitlab.Ptr(base),
	}
	mergeRequest, _, err := gl.client.MergeRequests.CreateMergeRequest(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	return mergeRequest
}

func (gl *GitLabClient) CloseMergeRequest(mr *gitlab.MergeRequest) {
	_, err := gl.client.MergeRequests.DeleteMergeRequest(gl.ProjectName(), mr.IID)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
}

func (gl *GitLabClient) AcceptMergeRequest(mr *gitlab.MergeRequest, commitMessage string) *gitlab.MergeRequest {
	opts := gitlab.AcceptMergeRequestOptions{
		ShouldRemoveSourceBranch: gitlab.Ptr(true),
	}
	merged, resp, err := gl.client.MergeRequests.AcceptMergeRequest(gl.ProjectName(), mr.IID, &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	if resp.StatusCode != 200 {
		gl.t.Fatalf("failed to accept merge request %v", resp)
	}
	return merged
}

func TestIMCloudBuildWorkspaceGitLab(t *testing.T) {
	gitlabPAT := cftutils.ValFromEnv(t, "IM_GITLAB_PAT")
	client := NewGitLabClient(t, gitlabPAT, "infrastructure-manager", fmt.Sprintf("blueprint-test-%s", utils.GetRandomStringFromSetup(t)))

	proj := client.GetProject()
	if proj == nil {
		client.CreateProject()
		client.AddFileToProject(utils.GetFileContents(t, "files/main.tf"))
	}

	vars := map[string]interface{}{
		"im_gitlab_pat":  gitlabPAT,
		"repository_url": client.project.HTTPURLToRepo,
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
			// Delete the repository if we hit a failed state
			if t.Failed() {
				client.DeleteProject()
			}
		})

		projectID := bpt.GetStringOutput("project_id")
		apiSecretID := bpt.GetStringOutput("gitlab_api_secret_id")
		readApiSecretID := bpt.GetStringOutput("gitlab_read_api_secret_id")
		triggerLocation := "us-central1"
		repoURLSplit := strings.Split(client.project.HTTPURLToRepo, "/")

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
			cftutils.Poll(t, pollCloudBuild(buildListCmd), 20, 15*time.Second)
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
			client.DeleteProject()
			bpt.DefaultTeardown(assert)
		})
		projectID := bpt.GetStringOutput("project_id")
		gcloud.Runf(t, "infra-manager deployments delete projects/%s/locations/us-central1/deployments/im-example-gitlab-deployment --project %s --quiet", projectID, projectID)
	})

	bpt.Test()
}
