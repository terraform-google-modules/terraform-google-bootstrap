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
	"regexp"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
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
	resp, err := gl.client.Projects.DeleteProject(gl.ProjectName(), utils.GetDeleteProjectOptions())
	if resp.StatusCode != 404 && err != nil {
		gl.t.Errorf("error deleting project with status %s and error %s", resp.Status, err.Error())
	}
	gl.project = nil
}

func TestCloudBuildRepoConnectionGitLab(t *testing.T) {
	repoName := fmt.Sprintf("conn-gl-%s", utils.GetRandomStringFromSetup(t))
	gitlabPAT := cftutils.ValFromEnv(t, "IM_GITLAB_PAT")
	owner := "infrastructure-manager"

	client := NewGitLabClient(t, gitlabPAT, owner, repoName)
	proj := client.GetProject()
	if proj == nil {
		client.CreateProject()
	}

	resourcesLocation := "us-central1"
	vars := map[string]interface{}{
		"gitlab_read_authorizer_credential": gitlabPAT,
		"gitlab_authorizer_credential":      gitlabPAT,
		"repository_name":                   repoName,
		"repository_url":                    client.project.HTTPURLToRepo,
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
		projectId := bpt.GetTFSetupStringOutput("project_id")
		connectionId := bpt.GetStringOutput("cloud_build_repositories_2nd_gen_connection")

		connectionIdRegexPattern := `^projects/[^/]+/locations/[^/]+/connections/[^/]+$`
		re := regexp.MustCompile(connectionIdRegexPattern)
		assert.True(re.MatchString(connectionId), "Connection ID should be in format projects/{{project}}/locations/{{location}}/connections/{{name}}")

		connectionSlice := strings.Split(connectionId, "/")
		// Extract the project, location and connection name from the connection_id
		connectionProjectId := connectionSlice[1]
		connectionLocation := connectionSlice[3]
		connectionName := connectionSlice[len(connectionSlice)-1]

		// Assert that the resource was created in the specified project and region
		assert.Equal(projectId, connectionProjectId, "Connection project id should be the same as input project id.")
		assert.Equal(resourcesLocation, connectionLocation, fmt.Sprintf("Connection location should be '%s'.", resourcesLocation))

		repository := gcloud.Runf(t, "builds repositories describe %s --project %s --region %s --connection %s", repoName, projectId, resourcesLocation, connectionName)

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
