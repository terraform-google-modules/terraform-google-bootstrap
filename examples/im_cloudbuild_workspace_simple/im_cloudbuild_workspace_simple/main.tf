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

module "im_workspace" {
  # TODO Need to hardcode source location until published
  # source = "terraform-google-modules/bootstrap/google//modules/im_cloudbuild_workspace"
  source = "../../modules/im_cloudbuild_workspace"

  project_id = "${var.project_id}"
  deployment_id = "${var.deployment_id}"

  # TODO Add these as variables for the example.
  im_deployment_repo_uri = var.im_repo_uri
  im_deployment_repo_uri = "https://github.com/josephdt12/terraform-google-cloud-storage.git"
  im_deployment_repo_dir = "examples/simple_bucket"
  im_deployment_branch = "master"
  im_tf_variables = "project_id=${var.project_id}"
  
  # Having to explicitly set this boolean to false is a little annoying
  # Perhaps check if either the SA has been set, or this is set to false?
  create_infra_manager_sa = false
  infra_manager_sa = "projects/${var.project_id}/serviceAccounts/${var.service_account}"

  tf_repo_type = "GITHUB"
  github_app_installation_id = "${var.github_app_installation_id}"
  repo_personal_access_token = "${var.repo_pat}"

  tf_cloudbuilder = var.cb_tf_builder_version
}