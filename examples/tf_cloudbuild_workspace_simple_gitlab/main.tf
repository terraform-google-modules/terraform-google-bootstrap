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

locals {
  # GitLab repo url of form "gitlab.com/owner/name"
  repoURL              = endswith(var.repository_uri, ".git") ? var.repository_uri : "${var.repository_uri}.git"
  repoURLWithoutSuffix = trimsuffix(local.repoURL, ".git")
  gl_repo_url_split    = split("/", local.repoURLWithoutSuffix)
  gl_name              = local.gl_repo_url_split[length(local.gl_repo_url_split) - 1]

  location = "us-central1"
}

module "tf_workspace" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_workspace"
  version = "~> 10.0"

  project_id               = module.enabled_google_apis.project_id
  tf_repo_type             = "CLOUDBUILD_V2_REPOSITORY"
  tf_repo_uri              = module.git_repo_connection.cloud_build_repositories_2nd_gen_repositories["test_repo"].id
  location                 = "us-central1"
  trigger_location         = "us-central1"
  artifacts_bucket_name    = "tf-configs-build-artifacts-${var.project_id}-gl"
  log_bucket_name          = "tf-configs-build-logs-${var.project_id}-gl"
  create_state_bucket_name = "tf-configs-build-state-${var.project_id}-gl"

  # allow log/state buckets to be destroyed
  buckets_force_destroy = true
  cloudbuild_sa_roles = { (module.enabled_google_apis.project_id) = {
    project_id = module.enabled_google_apis.project_id,
    roles      = ["roles/compute.networkAdmin"]
    }
  }
  cloudbuild_env_vars = ["TF_VAR_project_id=${var.project_id}"]

  depends_on = [
    module.enabled_google_apis,
    time_sleep.propagation,
  ]
}

resource "time_sleep" "propagation" {
  create_duration = "30s"

  depends_on = [module.git_repo_connection]
}

module "git_repo_connection" {
  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild_repo_connection"
  version = "~> 10.0"

  project_id = var.project_id
  connection_config = {
    connection_type                             = "GITLABv2"
    gitlab_authorizer_credential_secret_id      = var.gitlab_authorizer_secret_id
    gitlab_read_authorizer_credential_secret_id = var.gitlab_read_authorizer_secret_id
    gitlab_webhook_secret_id                    = var.gitlab_webhook_secret_id
  }

  cloud_build_repositories = {
    "test_repo" = {
      repository_name = local.gl_name
      repository_url  = var.repository_uri
    },
  }

  depends_on = [time_sleep.propagation_secret_version]
}

resource "time_sleep" "propagation_secret_version" {
  create_duration = "30s"
}

data "google_secret_manager_secret_version_access" "gitlab_api_access_token" {
  secret = var.gitlab_authorizer_secret_id

  depends_on = [time_sleep.propagation_secret_version]
}

module "bootstrap_github_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  upgrade           = false
  module_depends_on = [module.tf_workspace]

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${data.google_secret_manager_secret_version_access.gitlab_api_access_token.secret_data} ${var.repository_uri} ${path.module}/files"
}
