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
  # GitLab repo url of form "[host_uri]/[owners]/project"
  is_gl_repo        = var.tf_repo_type == "GITLAB"
  gl_repo_url_split = local.is_gl_repo ? split("/", local.repoURLWithoutSuffix) : []
  gl_project        = local.is_gl_repo ? local.gl_repo_url_split[length(local.gl_repo_url_split) - 1] : ""

  create_api_secret           = local.is_gl_repo && var.gitlab_api_access_token != ""
  existing_api_secret_version = local.is_gl_repo && var.gitlab_api_access_token_secret != "" ? data.google_secret_manager_secret_version.existing_gitlab_api_secret_version[0].name : ""
  gitlab_api_secret_version   = local.create_api_secret ? google_secret_manager_secret_version.gitlab_api_secret_version[0].name : local.existing_api_secret_version
  api_secret_id               = local.is_gl_repo ? (local.create_api_secret ? google_secret_manager_secret.gitlab_api_secret[0].id : data.google_secret_manager_secret.existing_gitlab_api_secret[0].secret_id) : ""

  create_read_api_secret           = local.is_gl_repo && var.gitlab_read_api_access_token != ""
  existing_read_api_secret_version = local.is_gl_repo && var.gitlab_read_api_access_token_secret != "" ? data.google_secret_manager_secret_version.existing_gitlab_read_api_secret_version[0].name : ""
  gitlab_read_api_secret_version   = local.create_read_api_secret ? google_secret_manager_secret_version.gitlab_read_api_secret_version[0].name : local.existing_read_api_secret_version
  read_api_secret_id               = local.is_gl_repo ? (local.create_read_api_secret ? google_secret_manager_secret.gitlab_read_api_secret[0].id : data.google_secret_manager_secret.existing_gitlab_read_api_secret[0].secret_id) : ""
}

resource "random_id" "gitlab_resources_random_id" {
  count       = local.is_gl_repo ? 1 : 0
  byte_length = 8
}

resource "google_secret_manager_secret" "gitlab_api_secret" {
  count     = local.create_api_secret ? 1 : 0
  project   = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-api-access-token"
  labels = {
    label = "im-${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_api_secret_version" {
  count       = local.create_api_secret ? 1 : 0
  secret      = google_secret_manager_secret.gitlab_api_secret[0].id
  secret_data = var.gitlab_api_access_token
}

resource "google_secret_manager_secret" "gitlab_read_api_secret" {
  count     = local.create_read_api_secret ? 1 : 0
  project   = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-read-api-access-token"
  labels = {
    label = "im-${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_read_api_secret_version" {
  count       = local.create_read_api_secret ? 1 : 0
  secret      = google_secret_manager_secret.gitlab_read_api_secret[0].id
  secret_data = var.gitlab_read_api_access_token
}

resource "random_uuid" "random_webhook_secret" {
  count = local.is_gl_repo ? 1 : 0
}

resource "google_secret_manager_secret" "gitlab_webhook_secret" {
  count     = local.is_gl_repo ? 1 : 0
  project   = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-webhook-secret"
  labels = {
    label = "im-${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gitlab_webhook_secret_version" {
  count       = local.is_gl_repo ? 1 : 0
  secret      = google_secret_manager_secret.gitlab_webhook_secret[0].id
  secret_data = random_uuid.random_webhook_secret[0].result
}

data "google_secret_manager_secret" "existing_gitlab_api_secret" {
  count     = var.gitlab_api_access_token_secret != "" ? 1 : 0
  project   = var.project_id
  secret_id = var.gitlab_api_access_token_secret
}

data "google_secret_manager_secret_version" "existing_gitlab_api_secret_version" {
  count   = var.gitlab_api_access_token_secret != "" ? 1 : 0
  project = var.project_id
  secret  = data.google_secret_manager_secret.existing_gitlab_api_secret[0].id
  version = var.gitlab_api_access_token_secret_version != "" ? var.gitlab_api_access_token_secret_version : null
}

data "google_secret_manager_secret" "existing_gitlab_read_api_secret" {
  count     = var.gitlab_read_api_access_token_secret != "" ? 1 : 0
  project   = var.project_id
  secret_id = var.gitlab_read_api_access_token_secret
}

data "google_secret_manager_secret_version" "existing_gitlab_read_api_secret_version" {
  count   = var.gitlab_read_api_access_token_secret != "" ? 1 : 0
  project = var.project_id
  secret  = data.google_secret_manager_secret.existing_gitlab_read_api_secret[0].id
  version = var.gitlab_read_api_access_token_secret_version != "" ? var.gitlab_read_api_access_token_secret_version : null
}

resource "google_secret_manager_secret_iam_member" "gitlab_secret_members" {
  for_each  = local.is_gl_repo ? { "api" = local.api_secret_id, "read_api" = local.read_api_secret_id, "webhook" = google_secret_manager_secret.gitlab_webhook_secret[0].id } : {}
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}
