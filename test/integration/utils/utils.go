package utils

import (
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
)

// GetRandomStringFromSetup gets a random string output variable setup.
func GetRandomStringFromSetup(t *testing.T) string {
	t.Helper()
	setup := tft.NewTFBlueprintTest(t)
	return setup.GetTFSetupStringOutput("random_testing_string")
}
