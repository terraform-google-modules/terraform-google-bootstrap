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

package cloudbuild_repo_connection_gitlab

import (
	"fmt"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
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
		group:     "mygroup5691232",
		namespace: 91694854,
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

func TestCloudBuildRepoConnectionGitLab(t *testing.T) {
	// repoName := fmt.Sprintf("cb-bp-gl-%s", utils.GetRandomStringFromSetup(t))
	repoName := fmt.Sprintf("cb-bp-gl-%s", "testeee")
	gitlabPAT := cftutils.ValFromEnv(t, "IM_GITLAB_PAT")

	owner := "infrastructure-manager"
	owner = "ccolin-automation"

	client := NewGitLabClient(t, gitlabPAT, owner, repoName)
	proj := client.GetProject()
	if proj == nil {
		client.CreateProject()
	}

	vars := map[string]interface{}{
		"gitlab_read_authorizer_credential": gitlabPAT,
		"gitlab_authorizer_credential":      gitlabPAT,
		"project_id":                        "ccolin-experiments",
		"test_repo_name":                    "name1",
		"test_repo_url":                     client.project.HTTPURLToRepo,
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

		// validate if repository was created using the connection
		connection_id := bpt.GetStringOutput("cloudbuild_2nd_gen_connection")
		connection_slice := strings.Split(connection_id, "/")

		assert.True(len(connection_slice) > 0, "Connection ID should be in format projects/{{project}}/locations/{{location}}/connections/{{name}}")

		connection_name := connection_slice[len(connection_slice)-1]
		repository := gcloud.Run(t, fmt.Sprintf("builds repositories describe %s", "name1"), gcloud.WithCommonArgs([]string{"--project", "ccolin-experiments", "--region", "us-central1", "--connection", connection_name, "--format", "json"}))

		assert.Equal(client.project.HTTPURLToRepo, repository.Get("remoteUri").String(), "Git clone URL must be the same on the created resource.")
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