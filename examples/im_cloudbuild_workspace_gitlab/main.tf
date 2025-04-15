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
  source  = "terraform-google-modules/bootstrap/google//modules/im_cloudbuild_workspace"
  version = "~> 11.0"

  project_id    = var.project_id
  deployment_id = "im-example-gitlab-deployment"

  tf_repo_type           = "GITLAB"
  im_deployment_repo_uri = var.repository_url
  im_deployment_ref      = "main"
  im_tf_variables        = "project_id=${var.project_id}"
  infra_manager_sa_roles = ["roles/compute.networkAdmin"]
  tf_version             = "1.5.7"

  gitlab_api_access_token      = var.im_gitlab_pat
  gitlab_read_api_access_token = var.im_gitlab_pat
}
