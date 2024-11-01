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

package utils

import (
	"os"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/xanzy/go-gitlab"
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

// GetDeleteProjectOptions returns default DeleteProjectOptions
func GetDeleteProjectOptions() *gitlab.DeleteProjectOptions {
	return &gitlab.DeleteProjectOptions{}
}
