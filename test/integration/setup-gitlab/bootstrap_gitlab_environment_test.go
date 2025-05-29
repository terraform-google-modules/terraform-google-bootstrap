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

package bootstrap_gitlab

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/gruntwork-io/terratest/modules/shell"
)

// connects to a Google Cloud VM instance using SSH and retrieves the logs from the VM's Startup Script service
func readLogsFromVm(t *testing.T, instanceName string, instanceZone string, instanceProject string) (string, error) {
	args := []string{"compute", "ssh", instanceName, fmt.Sprintf("--zone=%s", instanceZone), fmt.Sprintf("--project=%s", instanceProject), "-q", "--command=journalctl -u google-startup-scripts.service -n 20"}
	gcloudCmd := shell.Command{
		Command: "gcloud",
		Args:    args,
	}
	return shell.RunCommandAndGetStdOutE(t, gcloudCmd)
}

func TestValidateStartupScript(t *testing.T) {
	// Retrieve output values from test setup
	setup := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../setup"),
	)
	instanceName := setup.GetStringOutput("gitlab_instance_name")
	instanceZone := setup.GetStringOutput("gitlab_instance_zone")
	gitlabSecretProject := setup.GetStringOutput("gitlab_secret_project")
	// Periodically read logs from startup script running on the VM instance
	for count := 0; count < 100; count++ {
		logs, err := readLogsFromVm(t, instanceName, instanceZone, gitlabSecretProject)
		if err != nil {
			t.Fatal(err)
		}

		if strings.Contains(logs, "Finished Google Compute Engine Startup Scripts") {
			if strings.Contains(logs, "exit status 1") {
				t.Fatal("ERROR: Startup Script finished with invalid exit status.")
			}
			break
		}
		time.Sleep(12 * time.Second)
	}
}
