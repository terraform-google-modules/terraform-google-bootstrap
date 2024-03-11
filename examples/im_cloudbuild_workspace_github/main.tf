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
  source = "../../modules/im_cloudbuild_workspace"

  project_id    = var.project_id
  deployment_id = "im-example-github-deployment"

  tf_repo_type           = "GITHUB"
  im_deployment_repo_uri = "https://github.com/im-goose/infra-manager-git-example.git"
  im_deployment_ref      = "main"
  im_tf_variables        = "project_id=${var.project_id}"
  infra_manager_sa_roles = ["roles/compute.networkAdmin"]

  github_app_installation_id   = "47590865"
  github_personal_access_token = var.im_github_pat
}
