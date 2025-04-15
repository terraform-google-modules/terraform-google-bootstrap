/**
 * Copyright 2022 Google LLC
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
  version = "~> 11.0"

  project_id          = module.enabled_google_apis.project_id
  dockerfile_repo_uri = google_sourcerepo_repository.builder_dockerfile_repo.url
  trigger_location    = "us-central1"
  gar_repo_location   = "us-central1"
  build_timeout       = "1200s"
  # allow logs bucket to be destroyed
  cb_logs_bucket_force_destroy = true
  # allow workflow to be destroyed
  workflow_deletion_protection = false
}

# CSR for storing Dockerfile
resource "google_sourcerepo_repository" "builder_dockerfile_repo" {
  project = module.enabled_google_apis.project_id
  name    = "tf-cloudbuilder"
}

# Bootstrap CSR with Dockerfile
module "bootstrap_csr_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  upgrade           = false
  module_depends_on = [module.cloudbuilder]

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${module.enabled_google_apis.project_id} ${split("/", google_sourcerepo_repository.builder_dockerfile_repo.id)[3]} ${path.module}/Dockerfile"
}
