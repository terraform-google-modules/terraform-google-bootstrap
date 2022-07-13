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

package tf_cloudbuild_source_simple

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func TestTFCloudBuildSourceSimple(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		projectID := bpt.GetStringOutput("cloudbuild_project_id")

		// cloudbuild buckets
		cloudbuildBucket := bpt.GetStringOutput("gcs_cloudbuild_default_bucket")
		// we can't use runf since we need to override --format json with --json for alpha storage
		bucketOP := gcloud.Run(t, fmt.Sprintf("alpha storage ls --buckets gs://%s", cloudbuildBucket), gcloud.WithCommonArgs([]string{"--project", projectID, "--json"})).Array()
		assert.Equalf(1, len(bucketOP), "%s bucket should exist", cloudbuildBucket)
		assert.Truef(bucketOP[0].Get("metadata.iamConfiguration.uniformBucketLevelAccess.enabled").Bool(), "%s bucket uniformBucketLevelAccess should be enabled", cloudbuildBucket)
		assert.Truef(bucketOP[0].Get("metadata.versioning.enabled").Bool(), "%s bucket versioning should be enabled", cloudbuildBucket)

		//source repos
		repos := []string{
			"gcp-policies",
			"gcp-org",
			"gcp-envs",
			"gcp-networks",
			"gcp-projects",
		}
		for _, repo := range repos {
			url := fmt.Sprintf("https://source.developers.google.com/p/%s/r/%s", projectID, repo)
			repoOP := gcloud.Runf(t, "source repos describe %s --project %s", repo, projectID)
			assert.Equalf(url, repoOP.Get("url").String(), "source repo %s should have url %s", repo, url)
		}
	})

	bpt.Test()
}
