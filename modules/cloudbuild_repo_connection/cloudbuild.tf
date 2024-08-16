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

resource "google_cloudbuildv2_connection" "connection" {
  project  = var.project_id
  location = var.default_region
  name     = "${var.cloudbuild_connection_name}-${random_id.resources_random_id.dec}"

  dynamic "github_config" {
    for_each = local.is_github_connection ? [1] : []
    content {
      app_installation_id = var.credential_config.github_app_id
      authorizer_credential {
        oauth_token_secret_version = "${google_secret_manager_secret.github_token_secret[0].id}/versions/latest"
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = local.is_gitlab_connection ? [1] : []
    content {
      host_uri = null
      authorizer_credential {
        user_token_secret_version = google_secret_manager_secret_version.gitlab_api_secret_version[0].name
      }
      read_authorizer_credential {
        user_token_secret_version = google_secret_manager_secret_version.gitlab_read_api_secret_version[0].name
      }
      webhook_secret_secret_version = google_secret_manager_secret_version.gitlab_webhook_secret_version[0].name
    }
  }

  depends_on = [time_sleep.secret_iam_permission_propagation]
}

resource "time_sleep" "secret_iam_permission_propagation" {
  create_duration = "30s"

  depends_on = [
    google_secret_manager_secret_iam_member.github_accessor,
    google_secret_manager_secret_iam_member.gitlab_token_iam_member
  ]
}

resource "google_cloudbuildv2_repository" "repositories" {
  for_each = var.cloudbuild_repos

  project           = var.project_id
  location          = var.default_region
  name              = each.value.repo_name
  remote_uri        = each.value.repo_url
  parent_connection = google_cloudbuildv2_connection.connection.name
}
