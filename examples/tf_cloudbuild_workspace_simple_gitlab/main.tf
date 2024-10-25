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

data "google_project" "project" {
  project_id = var.project_id
}

// Added to various IDs to prevent potential conflicts for deployments targeting the same repository.
resource "random_id" "gitlab_resources_random_id" {
  byte_length = 8
}

resource "random_uuid" "random_webhook_secret" {
}

module "tf_workspace" {
  source = "../../modules/tf_cloudbuild_workspace"

  project_id               = module.enabled_google_apis.project_id
  tf_repo_type             = "CLOUDBUILD_V2_REPOSITORY"
  tf_repo_uri              = google_cloudbuildv2_repository.repository_connection.id
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

  depends_on = [module.enabled_google_apis]
}

// Create a secret containing the personal access token and grant permissions to the Service Agent.
resource "google_secret_manager_secret" "gitlab_api_secret" {
  project   = var.project_id
  secret_id = "cb-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-api-access-token"

  labels = {
    label = "cb-${random_id.gitlab_resources_random_id.dec}"
  }

  replication {
    auto {}
  }
}

// Personal access token from VCS.
resource "google_secret_manager_secret_version" "gitlab_api_secret_version" {
  secret      = google_secret_manager_secret.gitlab_api_secret.id
  secret_data = var.gitlab_api_access_token
}

resource "google_secret_manager_secret" "gitlab_read_api_secret" {
  project   = var.project_id
  secret_id = "cb-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-read-api-access-token"
  labels = {
    label = "cb-${random_id.gitlab_resources_random_id.dec}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_read_api_secret_version" {
  secret      = google_secret_manager_secret.gitlab_read_api_secret.id
  secret_data = var.gitlab_read_api_access_token
}

resource "google_secret_manager_secret" "gitlab_webhook_secret" {
  project   = var.project_id
  secret_id = "cb-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-webhook-secret"
  labels = {
    label = "cb-${random_id.gitlab_resources_random_id.dec}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_webhook_secret_version" {
  secret      = google_secret_manager_secret.gitlab_webhook_secret.id
  secret_data = random_uuid.random_webhook_secret.result
}

resource "google_secret_manager_secret_iam_member" "gitlab_token_iam_member" {
  for_each = {
    "api"      = google_secret_manager_secret.gitlab_api_secret.id,
    "read_api" = google_secret_manager_secret.gitlab_read_api_secret.id,
    "webhook"  = google_secret_manager_secret.gitlab_webhook_secret.id
  }

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_cloudbuildv2_connection" "vcs_connection" {
  project  = var.project_id
  name     = "cb-gl-${random_id.gitlab_resources_random_id.dec}-${var.project_id}"
  location = local.location

  gitlab_config {
    host_uri = null
    authorizer_credential {
      user_token_secret_version = google_secret_manager_secret_version.gitlab_api_secret_version.name
    }
    read_authorizer_credential {
      user_token_secret_version = google_secret_manager_secret_version.gitlab_read_api_secret_version.name
    }
    webhook_secret_secret_version = google_secret_manager_secret_version.gitlab_webhook_secret_version.name
  }

  depends_on = [google_secret_manager_secret_iam_member.gitlab_token_iam_member]
}

// Create the repository connection.
resource "google_cloudbuildv2_repository" "repository_connection" {
  project  = var.project_id
  name     = local.gl_name
  location = local.location

  parent_connection = google_cloudbuildv2_connection.vcs_connection.name
  remote_uri        = local.repoURL
}

module "bootstrap_github_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"
  upgrade = false

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${var.gitlab_api_access_token} ${var.repository_uri} ${path.module}/files"
}
