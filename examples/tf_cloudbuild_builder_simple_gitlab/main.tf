/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "cloudbuilder" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_builder"
  version = "~> 8.0"

  project_id                  = module.enabled_google_apis.project_id
  dockerfile_repo_id          = var.cloudbuildv2_repository_id
  dockerfile_repo_type        = "UNKNOWN" // "GITLAB" is not one of the options available so we need to use "UNKNOWN"
  use_cloudbuildv2_repository = true
  trigger_location            = "us-central1"
  gar_repo_location           = "us-central1"
  bucket_name                 = "tf-cloudbuilder-build-logs-${var.project_id}-gl"
  gar_repo_name               = "tf-runners-gl"
  workflow_name               = "terraform-runner-workflow-gl"

  # allow logs bucket to be destroyed
  cb_logs_bucket_force_destroy = true
}

# Bootstrap GitLab with Dockerfile
module "bootstrap_gitlab_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"
  upgrade = false

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${var.gitlab_pat} ${var.repository_uri} ${path.module}/Dockerfile"
}
