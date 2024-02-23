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
	"fmt"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func TestIMCloudBuildWorkspaceGitHub(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		projectID := bpt.GetStringOutput("project_id")

		// cloud build triggers
		triggers := []string{"preview", "apply"}
		for _, trigger := range triggers {
			triggerOP := lastElem(bpt.GetStringOutput(fmt.Sprintf("cloudbuild_%s_trigger_id", trigger)), "/")
			cloudBuildOP := gcloud.Runf(t, "beta builds triggers describe %s --project %s", triggerOP, projectID)
			// TODO Verify the trigger name
			assert.Equal(fmt.Sprintf("projects/%s/serviceAccounts/cb-sa-im-git-ci-cd@%s.iam.gserviceaccount.com", projectID, projectID), cloudBuildOP.Get("serviceAccount").String(), "uses expected SA")
		}
	})

	bpt.Test()
}

// lastElem gets the last element in a string separated by sep.
// Typically used to grab a resource ID from a full resource name.
func lastElem(name, sep string) string {
	return strings.Split(name, sep)[len(strings.Split(name, sep))-1]
}
