package utils

import (
	"os"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
)

// GetRandomStringFromSetup gets a random string output variable setup.
func GetRandomStringFromSetup(t *testing.T) string {
	t.Helper()
	setup := tft.NewTFBlueprintTest(t)
	return setup.GetTFSetupStringOutput("random_testing_string")
}

// GetFileContents returns the contents of a given file.
func GetFileContents(t *testing.T, path string) []byte {
	t.Helper()
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err.Error())
	}
	return contents
}

// LastElement gets the last element in a string separated by sep.
// Typically used to grab a resource ID from a full resource name.
func LastElement(str, sep string) string {
	return strings.Split(str, sep)[len(strings.Split(str, sep))-1]
}
