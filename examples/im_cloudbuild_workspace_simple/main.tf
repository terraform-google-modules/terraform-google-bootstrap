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

  project_id    = var.project_id
  deployment_id = var.deployment_id

  tf_repo_type    = var.tf_repo_type
  im_deployment_repo_uri = var.im_repo_uri
  im_deployment_repo_dir = var.im_repo_directory
  im_deployment_ref   = var.im_repo_ref

  im_tf_variables = "project_id=${var.project_id},network_name=test-network"


  github_app_installation_id   = var.github_app_installation_id
  github_personal_access_token = var.repo_pat

  gitlab_api_access_token      = var.gitlab_api_token
  gitlab_read_api_access_token = var.gitlab_read_api_token
}
