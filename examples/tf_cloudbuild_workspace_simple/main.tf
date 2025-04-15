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

module "tf_workspace" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_workspace"
  version = "~> 11.0"

  project_id       = module.enabled_google_apis.project_id
  tf_repo_uri      = google_sourcerepo_repository.tf_config_repo.url
  trigger_location = "global"
  # allow log/state buckets to be destroyed
  buckets_force_destroy = true
  cloudbuild_sa_roles = { (module.enabled_google_apis.project_id) = {
    project_id = module.enabled_google_apis.project_id,
    roles      = ["roles/compute.networkAdmin"]
    }
  }
  cloudbuild_env_vars = ["TF_VAR_project_id=${var.project_id}"]

}

# CSR for storing TF configs
resource "google_sourcerepo_repository" "tf_config_repo" {
  project = module.enabled_google_apis.project_id
  name    = "tf-configs"
}

# # Bootstrap CSR with TF configs
module "bootstrap_csr_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  upgrade = false

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${module.enabled_google_apis.project_id} ${split("/", google_sourcerepo_repository.tf_config_repo.id)[3]} ${path.module}/files"
}
