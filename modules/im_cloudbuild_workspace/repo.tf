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
  repoURL = endswith(var.im_deployment_repo_uri, ".git") ? var.im_deployment_repo_uri : "${var.im_deployment_repo_uri}.git"
  // Remove the ".git" suffix for parsing the url for owner/repo
  repoURLWithoutSuffix = trimsuffix(local.repoURL, ".git")

  repo           = local.is_gh_repo ? local.gh_name : local.gl_project
  default_prefix = local.repo

  host_connection_name = var.host_connection_name != "" ? var.host_connection_name : "im-${random_id.resources_random_id.dec}-${var.project_id}-${var.deployment_id}"
  repo_connection_name = var.repo_connection_name != "" ? var.repo_connection_name : "im-${random_id.resources_random_id.dec}-${local.repo}"
}

data "google_project" "project" {
  project_id = var.project_id
}

// Added to various IDs to prevent potential conflicts for deployments targeting the same repository.
resource "random_id" "resources_random_id" {
  byte_length = 4
}

// Create the VCS connection.
resource "google_cloudbuildv2_connection" "vcs_connection" {
  project  = var.project_id
  location = var.location

  name = local.host_connection_name

  dynamic "github_config" {
    for_each = local.is_gh_repo ? [1] : []
    content {
      app_installation_id = var.github_app_installation_id
      authorizer_credential {
        oauth_token_secret_version = local.github_secret_version_id
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = local.is_gl_repo ? [1] : []
    content {
      host_uri = var.gitlab_host_uri != "" ? var.gitlab_host_uri : null
      authorizer_credential {
        user_token_secret_version = local.gitlab_api_secret_version
      }
      read_authorizer_credential {
        user_token_secret_version = local.gitlab_read_api_secret_version
      }
      webhook_secret_secret_version = google_secret_manager_secret_version.gitlab_webhook_secret_version[0].name
    }
  }
}

// Create the repository connection.
resource "google_cloudbuildv2_repository" "repository_connection" {
  project           = var.project_id
  location          = var.location
  name              = local.repo_connection_name
  parent_connection = google_cloudbuildv2_connection.vcs_connection.name
  remote_uri        = local.repoURL
}
