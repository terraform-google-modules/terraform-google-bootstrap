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

data "google_project" "project_id" {
  project_id = var.project_id
}

locals {
  is_github = var.credential_config.credential_type == "GITHUBv2"
  is_gitlab = var.credential_config.credential_type == "GITLABv2"

  gitlab_secrets_iterator = local.is_gitlab ? {
    "api"      = google_secret_manager_secret.gitlab_api_token[0].id,
    "read_api" = google_secret_manager_secret.gitlab_read_api_token[0].id,
    "webhook"  = google_secret_manager_secret.gitlab_webhook[0].id
  } : {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Github Secret
resource "google_secret_manager_secret" "github_token" {
  count = local.is_github ? 1 : 0

  project   = var.project_id
  secret_id = "${var.credential_config.github_secret_id}-${random_id.suffix.dec}"

  replication {
    auto {

    }
  }
}

resource "google_secret_manager_secret_version" "github_token" {
  count = local.is_github ? 1 : 0

  secret      = google_secret_manager_secret.github_token[0].id
  secret_data = var.credential_config.github_pat
}

resource "google_secret_manager_secret_iam_member" "github_accessor" {
  count = local.is_github ? 1 : 0

  secret_id = google_secret_manager_secret.github_token[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project_id.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Gitlab secret
resource "google_secret_manager_secret" "gitlab_api_token" {
  count = local.is_gitlab ? 1 : 0

  project   = var.project_id
  secret_id = "${var.credential_config.gitlab_authorizer_credential_secret_id}-${random_id.suffix.dec}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_api_token" {
  count = local.is_gitlab ? 1 : 0

  secret      = google_secret_manager_secret.gitlab_api_token[0].id
  secret_data = var.credential_config.gitlab_authorizer_credential
}

resource "google_secret_manager_secret" "gitlab_read_api_token" {
  count = local.is_gitlab ? 1 : 0

  project   = var.project_id
  secret_id = "${var.credential_config.gitlab_read_authorizer_credential_secret_id}-${random_id.suffix.dec}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_read_api_token" {
  count = local.is_gitlab ? 1 : 0

  secret      = google_secret_manager_secret.gitlab_read_api_token[0].id
  secret_data = var.credential_config.gitlab_read_authorizer_credential
}

resource "google_secret_manager_secret" "gitlab_webhook" {
  count = local.is_gitlab ? 1 : 0

  project   = var.project_id
  secret_id = "cb-gitlab-webhook-${random_id.suffix.dec}"
  replication {
    auto {}
  }
}

resource "random_uuid" "random_webhook_secret" {
  count = local.is_gitlab ? 1 : 0
}

resource "google_secret_manager_secret_version" "gitlab_webhook" {
  count = local.is_gitlab ? 1 : 0

  secret      = google_secret_manager_secret.gitlab_webhook[0].id
  secret_data = random_uuid.random_webhook_secret[0].result
}

resource "google_secret_manager_secret_iam_member" "gitlab_token_accessor" {
  for_each = local.gitlab_secrets_iterator

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project_id.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}
