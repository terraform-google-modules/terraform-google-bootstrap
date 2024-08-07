// Copyright 2022 Google LLC
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

// define test package name
package tf_cloudbuild_builder_simple

import (
	"fmt"
	"log"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
)

func TestTFCloudBuildBuilder(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		location := "us-central1"
		projectID := bpt.GetStringOutput("project_id")
		artifactRepo := bpt.GetStringOutput("artifact_repo")
		artifactRepoDockerRegistry := fmt.Sprintf("%s-docker.pkg.dev/%s/%s/terraform", location, projectID, artifactRepo)
		schedulerID := bpt.GetStringOutput("scheduler_id")
		workflowID := bpt.GetStringOutput("workflow_id")
		triggerFQN := bpt.GetStringOutput("cloudbuild_trigger_id")
		triggerId := strings.Split(triggerFQN, "/")[len(strings.Split(triggerFQN, "/"))-1]
		csrURL := bpt.GetStringOutput("csr_repo_url")

		schedulerOP := gcloud.Runf(t, "scheduler jobs describe %s", schedulerID)
		assert.Contains(schedulerOP.Get("name").String(), "trigger-terraform-runner-workflow", "has the correct name")
		assert.Equal("0 8 * * *", schedulerOP.Get("schedule").String(), "has the correct schedule")
		assert.Equal(fmt.Sprintf("https://workflowexecutions.googleapis.com/v1/%s/executions", workflowID), schedulerOP.Get("httpTarget.uri").String(), "has the correct target")

		workflowOP := gcloud.Runf(t, "workflows describe %s", workflowID)
		assert.Contains(workflowOP.Get("name").String(), "terraform-runner-workflow", "has the correct name")
		assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/terraform-runner-workflow-sa@%s.iam.gserviceaccount.com", projectID, projectID), workflowOP.Get("serviceAccount").String(), "uses expected SA")

		cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --project %s --region %s", triggerId, projectID, location)
		log.Print(cloudBuildOP)
		assert.Equal("tf-cloud-builder-build", cloudBuildOP.Get("name").String(), "has the correct name")
		assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/tf-cb-builder-sa@%s.iam.gserviceaccount.com", projectID, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
		assert.Equal(csrURL, cloudBuildOP.Get("sourceToBuild.uri").String(), "is connected to expected repo")
		expectedSubsts := []string{"_TERRAFORM_FULL_VERSION", "_TERRAFORM_MAJOR_VERSION", "_TERRAFORM_MINOR_VERSION"}
		gotSubsts := cloudBuildOP.Get("substitutions").Map()
		imgs := utils.GetResultStrSlice(cloudBuildOP.Get("build.images").Array())
		for _, subst := range expectedSubsts {
			_, found := gotSubsts[subst]
			assert.Truef(found, "has %s substituion", found)
			assert.Contains(imgs, fmt.Sprintf("%s:v${%s}", artifactRepoDockerRegistry, subst), "tags correct image")
		}

		// e2e test
		oldWorkflowRuns := gcloud.Runf(t, "workflows executions list %s", workflowID).Array()
		// sometimes scheduler takes a minute to kick off workflow due to eventually consistent IAM
		// continue to retrigger a few times until a new workflow is kicked off
		triggerWorkflowFn := func() (bool, error) {
			gcloud.Runf(t, "scheduler jobs run %s", schedulerID)
			// workflow may take a few secs to trigger
			time.Sleep(10 * time.Second)
			newWorkflowRuns := gcloud.Runf(t, "workflows executions list %s", workflowID).Array()
			// new workflow is kicked off since list has an additional workflow run
			if len(newWorkflowRuns)-len(oldWorkflowRuns) > 0 {
				return false, nil
			}
			return true, nil
		}
		utils.Poll(t, triggerWorkflowFn, 10, 10*time.Second)

		// poll until workflow complete
		// workflow will poll CB LRO to completion
		pollWorkflowFn := func() (bool, error) {
			latestWorkflowRun := gcloud.Runf(t, "workflows executions list %s --sort-by=startTime --limit=1", workflowID).Array()
			latestWorkflowRunStatus := latestWorkflowRun[0].Get("state").String()
			if latestWorkflowRunStatus == "SUCCEEDED" {
				return false, nil
			}
			// if failed it maybe due to eventually consistent IAM, retry trigger
			if latestWorkflowRunStatus == "FAILED" {
				triggerWorkflowFn()
			}
			return true, nil
		}
		utils.Poll(t, pollWorkflowFn, 100, 20*time.Second)

		// Poll the build to wait for it to run
		buildListCmd := fmt.Sprintf("builds list --filter buildTriggerId='%s' --region %s --project %s --limit 1 --sort-by ~createTime", triggerId, location, projectID)
		// poll build until complete
		pollCloudBuild := func(cmd string) func() (bool, error) {
			return func() (bool, error) {
				build := gcloud.Runf(t, cmd).Array()
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
		utils.Poll(t, pollCloudBuild(buildListCmd), 100, 10*time.Second)

		images := gcloud.Runf(t, "artifacts docker images list %s --include-tags", artifactRepoDockerRegistry).Array()
		assert.Equal(1, len(images), "only one image is in registry")
		imageTags := strings.Split(images[0].Get("tags").String(), ",")
		assert.Equal(3, len(imageTags), "image has three tags")
	})

	bpt.Test()
}
