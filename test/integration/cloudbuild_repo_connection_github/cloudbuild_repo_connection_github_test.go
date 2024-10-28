// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cloudbuild_repo_connection_github

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	cftutils "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/google/go-github/v66/github"
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
		Private:    github.Bool(true),
		Visibility: github.String("private"),
	}
	repo, _, err := gh.client.Repositories.Create(ctx, org, newRepo)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	gh.repository = repo
	return repo
}

func (gh *GitHubClient) DeleteRepository(ctx context.Context) {
	resp, err := gh.client.Repositories.Delete(ctx, gh.owner, *gh.repository.Name)
	if resp.StatusCode != 404 && err != nil {
		gh.t.Fatal(err.Error())
	}
}

func TestCloudBuildRepoConnectionGithub(t *testing.T) {
	ctx := context.Background()

	repoName := fmt.Sprintf("conn-gh-%s", utils.GetRandomStringFromSetup(t))

	githubPAT := cftutils.ValFromEnv(t, "IM_GITHUB_PAT")

	owner := "im-goose"
	client := NewGitHubClient(t, githubPAT, owner, repoName)

	repo := client.GetRepository(ctx)
	if repo == nil {
		client.CreateRepository(ctx, client.owner, client.repoName)
	}

	repoURL := client.repository.GetCloneURL()

	resourcesLocation := "us-central1"
	vars := map[string]interface{}{
		"github_pat":      githubPAT,
		"github_app_id":   "47590865",
		"repository_name": repoName,
		"repository_url":  repoURL,
	}

	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		t.Cleanup(func() {
			// Delete the repository if we hit a failed state
			if t.Failed() {
				client.DeleteRepository(ctx)
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

		assert.Equal(repoURL, repository.Get("remoteUri").String(), "Git clone URL must be the same on the created resource.")
	})

	bpt.DefineTeardown(func(assert *assert.Assertions) {
		// Guarantee clean up even if the normal gcloud/teardown run into errors
		t.Cleanup(func() {
			client.DeleteRepository(ctx)
			bpt.DefaultTeardown(assert)
		})
	})

	bpt.Test()
}
