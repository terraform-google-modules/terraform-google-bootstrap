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

module "cloudbuilder" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_builder"
  version = "~> 8.0"

  project_id                  = module.enabled_google_apis.project_id
  dockerfile_repo_uri         = google_cloudbuildv2_repository.repository_connection.id
  dockerfile_repo_type        = "UNKNOWN" // "GITLAB" is not one of the options available so we need to use "UNKNOWN"
  use_cloudbuildv2_repository = true
  trigger_location            = "us-central1"
  gar_repo_location           = "us-central1"
  bucket_name                 = "tf-cloudbuilder-build-logs-${var.project_id}-gl"
  gar_repo_name               = "tf-runners-gl"
  workflow_name               = "terraform-runner-workflow-gl"
  trigger_name                = "tf-cloud-builder-build-gl"

  # allow logs bucket to be destroyed
  cb_logs_bucket_force_destroy = true
}

// Create a secret containing the personal access token and grant permissions to the Service Agent.
resource "google_secret_manager_secret" "gitlab_api_secret" {
  project   = var.project_id
  secret_id = "builder-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-api-access-token"

  labels = {
    label = "b-${random_id.gitlab_resources_random_id.dec}"
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
  secret_id = "builder-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-read-api-access-token"
  labels = {
    label = "b-${random_id.gitlab_resources_random_id.dec}"
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
  secret_id = "builder-gl-${local.gl_name}-${random_id.gitlab_resources_random_id.dec}-webhook-secret"
  labels = {
    label = "b-${random_id.gitlab_resources_random_id.dec}"
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
  name     = "builder-gl-${random_id.gitlab_resources_random_id.dec}-${var.project_id}"
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

# Bootstrap GitLab with Dockerfile
module "bootstrap_gitlab_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"
  upgrade = false

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${var.gitlab_api_access_token} ${var.repository_uri} ${path.module}/Dockerfile"
}
