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

resource "random_id" "suffix" {
  byte_length = 4
}

# Gitlab secret
resource "google_secret_manager_secret" "gitlab_api_token" {
  project   = var.project_id
  secret_id = "cb-gitlab-api-credential-${random_id.suffix.dec}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_api_token" {
  secret      = google_secret_manager_secret.gitlab_api_token.id
  secret_data = var.gitlab_authorizer_credential
}

resource "google_secret_manager_secret" "gitlab_read_api_token" {
  project   = var.project_id
  secret_id = "cb-gitlab-read-api-credential-${random_id.suffix.dec}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_read_api_token" {
  secret      = google_secret_manager_secret.gitlab_read_api_token.id
  secret_data = var.gitlab_authorizer_credential
}

resource "google_secret_manager_secret" "gitlab_webhook" {
  project   = var.project_id
  secret_id = "cb-gitlab-webhook-${random_id.suffix.dec}"
  replication {
    auto {}
  }
}

resource "random_uuid" "random_webhook_secret" {
}

resource "google_secret_manager_secret_version" "gitlab_webhook" {
  secret      = google_secret_manager_secret.gitlab_webhook.id
  secret_data = random_uuid.random_webhook_secret.result
}

module "example" {
  source = "../../../examples/tf_cloudbuild_builder_simple_gitlab"

  project_id                       = var.project_id
  gitlab_authorizer_secret_id      = google_secret_manager_secret.gitlab_api_token.id
  gitlab_read_authorizer_secret_id = google_secret_manager_secret.gitlab_read_api_token.id
  gitlab_webhook_secret_id         = google_secret_manager_secret.gitlab_webhook.id
  repository_uri                   = var.repository_uri
}
