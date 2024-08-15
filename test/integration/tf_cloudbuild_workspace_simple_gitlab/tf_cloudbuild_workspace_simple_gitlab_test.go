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

package tf_cloudbuild_workspace_simple_gitlab

import (
	"fmt"
	"path"
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
		NamespaceID: gitlab.Ptr(gl.namespace),
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
	resp, err := gl.client.Projects.DeleteProject(gl.ProjectName())
	if resp.StatusCode != 404 && err != nil {
		gl.t.Errorf("error deleting project with status %s and error %s", resp.Status, err.Error())
	}
	gl.project = nil
}

func TestCloudBuildWorkspaceSimpleGitLab(t *testing.T) {
	repoName := fmt.Sprintf("cb-bp-gl-%s", utils.GetRandomStringFromSetup(t))
	gitlabPAT := cftutils.ValFromEnv(t, "IM_GITLAB_PAT")
	owner := "infrastructure-manager"

	client := NewGitLabClient(t, gitlabPAT, owner, repoName)
	proj := client.GetProject()
	if proj == nil {
		client.CreateProject()
	}

	vars := map[string]interface{}{
		"gitlab_api_access_token":      gitlabPAT,
		"gitlab_read_api_access_token": gitlabPAT,
		"repository_uri":               client.project.HTTPURLToRepo,
	}
	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		t.Cleanup(func() {
			// Delete the repository if we hit a failed state
			if t.Failed() {
				client.DeleteProject()
			}
		})

		location := bpt.GetStringOutput("location")
		projectID := bpt.GetStringOutput("project_id")

		// cloud build triggers
		triggers := []string{"plan", "apply"}
		for _, trigger := range triggers {
			triggerOP := utils.LastElement(bpt.GetStringOutput(fmt.Sprintf("cloudbuild_%s_trigger_id", trigger)), "/")
			cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --region %s --project %s", triggerOP, location, projectID)
			assert.Equal(fmt.Sprintf("%s-%s", repoName, trigger), cloudBuildOP.Get("name").String(), "should have the correct name")
			assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/tf-cb-%s@%s.iam.gserviceaccount.com", projectID, repoName, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
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

		gitRun("clone", fmt.Sprintf("https://gitlab-bot:%s@gitlab.com/%s/%s", gitlabPAT, owner, repoName), tmpDir)
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
			gitRun("push", "-u", fmt.Sprintf("https://gitlab-bot:%s@gitlab.com/%s/%s.git", gitlabPAT, owner, repoName), branch, "-f")
			lastCommit := git.GetLatestCommit()
			// filter builds triggered based on pushed commit sha
			buildListCmd := fmt.Sprintf("builds list --filter substitutions.COMMIT_SHA='%s' --project %s --region %s --limit 1 --sort-by ~createTime", lastCommit, projectID, location)
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
						logs, err := gcloud.RunCmdE(t, fmt.Sprintf("builds log %s --region %s", build[0].Get("id"), location))
						t.Logf("err %v", err)
						t.Logf("logs %s", logs)
						t.Fatalf("workflow %s failed with status %s", build[0].Get("id"), latestWorkflowRunStatus)
						return false, nil
					}
					return true, nil
				}
			}
			cftutils.Poll(t, pollCloudBuild(buildListCmd), 20, 15*time.Second)
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
			client.DeleteProject()
			bpt.DefaultTeardown(assert)
		})
	})

	bpt.Test()
}
