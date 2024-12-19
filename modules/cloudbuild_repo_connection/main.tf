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
  is_github = var.connection_config.connection_type == "GITHUBv2"
  is_gitlab = var.connection_config.connection_type == "GITLABv2"

  gitlab_secrets_iterator = local.is_gitlab ? {
    "api"      = var.connection_config.gitlab_authorizer_credential_secret_id,
    "read_api" = var.connection_config.gitlab_read_authorizer_credential_secret_id,
    "webhook"  = var.connection_config.gitlab_webhook_secret_id
  } : {}
}

data "google_project" "project_id" {
  project_id = var.project_id
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "google_secret_manager_secret_version_access" "app_installation_id" {
  count = local.is_github ? 1 : 0

  secret = var.connection_config.github_app_id_secret_id
}

resource "google_cloudbuildv2_connection" "connection" {
  project  = var.project_id
  location = var.location
  name     = "${var.cloudbuild_connection_name}-${random_id.suffix.dec}"

  dynamic "github_config" {
    for_each = local.is_github ? [1] : []
    content {
      app_installation_id = data.google_secret_manager_secret_version_access.app_installation_id[0].secret_data
      authorizer_credential {
        oauth_token_secret_version = "${var.connection_config.github_secret_id}/versions/latest"
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = local.is_gitlab ? [1] : []
    content {
      host_uri = var.connection_config.gitlab_enterprise_host_uri
      ssl_ca   = var.connection_config.gitlab_enterprise_ca_certificate
      dynamic "service_directory_config" {
        for_each = var.connection_config.gitlab_enterprise_service_directory == null ? [] : [1]
        content {
          service = var.connection_config.gitlab_enterprise_service_directory
        }
      }
      authorizer_credential {
        user_token_secret_version = "${var.connection_config.gitlab_authorizer_credential_secret_id}/versions/latest"
      }
      read_authorizer_credential {
        user_token_secret_version = "${var.connection_config.gitlab_read_authorizer_credential_secret_id}/versions/latest"
      }
      webhook_secret_secret_version = "${var.connection_config.gitlab_webhook_secret_id}/versions/latest"
    }
  }

  depends_on = [time_sleep.secret_iam_permission_propagation]
}

resource "google_secret_manager_secret_iam_member" "github_accessor" {
  count = local.is_github ? 1 : 0

  secret_id = var.connection_config.github_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project_id.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}


resource "google_secret_manager_secret_iam_member" "gitlab_token_accessor" {
  for_each = local.gitlab_secrets_iterator

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project_id.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "time_sleep" "secret_iam_permission_propagation" {
  create_duration = "30s"

  depends_on = [
    google_secret_manager_secret_iam_member.github_accessor,
    google_secret_manager_secret_iam_member.gitlab_token_accessor
  ]
}

resource "google_cloudbuildv2_repository" "repositories" {
  for_each = var.cloud_build_repositories

  project           = var.project_id
  location          = var.location
  name              = each.value.repository_name
  remote_uri        = each.value.repository_url
  parent_connection = google_cloudbuildv2_connection.connection.name
}
