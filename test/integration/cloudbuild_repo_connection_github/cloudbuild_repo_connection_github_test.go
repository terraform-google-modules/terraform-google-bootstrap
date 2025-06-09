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
	"github.com/stretchr/testify/assert"
	"github.com/terraform-google-modules/terraform-google-bootstrap/test/integration/utils"
)

const (
	repoName = "cb-repo-conn-gh"
)

func TestCloudBuildRepoConnectionGithub(t *testing.T) {
	ctx := context.Background()
	githubPAT := cftutils.ValFromEnv(t, "IM_GITHUB_PAT")
	client := utils.NewGitHubClient(t, githubPAT, repoName)

	client.GetRepository(ctx)
	repoURL := client.Repository.GetCloneURL()

	resourcesLocation := "us-central1"
	vars := map[string]interface{}{
		"github_pat":      githubPAT,
		"github_app_id":   utils.GitHubAppID,
		"repository_name": repoName,
		"repository_url":  repoURL,
	}

	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

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
			bpt.DefaultTeardown(assert)
		})
	})

	bpt.Test()
}
