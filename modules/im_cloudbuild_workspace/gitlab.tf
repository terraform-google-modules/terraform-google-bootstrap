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
  is_gl_repo = var.tf_repo_type == "GITLAB"
  gl_repo_url_split = local.is_gl_repo ? split("/", local.url) : []
  gl_project = local.is_gl_repo ? local.gl_repo_url_split[length(local.gl_repo_url_split) - 1] : ""
}

resource "random_id" "gitlab_resources_random_id" {
  count = local.is_gl_repo ? 1 : 0
  byte_length = 8
}

resource "google_secret_manager_secret" "gitlab_api_secret" {
  count = local.is_gl_repo ? 1 : 0
  project = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-api-access-token"
  labels = {
    label = "${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_policy" "api_secret_policy" {
  count = local.is_gl_repo ? 1 : 0
  project     = google_secret_manager_secret.gitlab_api_secret[0].project
  secret_id = google_secret_manager_secret.gitlab_api_secret[0].secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

resource "google_secret_manager_secret_version" "gitlab_api_secret_version" {
  count = local.is_gl_repo ? 1 : 0
  secret = google_secret_manager_secret.gitlab_api_secret[0].id
  secret_data = var.gitlab_api_access_token
}

resource "google_secret_manager_secret" "gitlab_read_api_secret" {
  count = local.is_gl_repo ? 1 : 0
  project = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-read-api-access-token"
  labels = {
    label = "${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_policy" "read_api_secret_policy" {
  count = local.is_gl_repo ? 1 : 0
  project     = google_secret_manager_secret.gitlab_read_api_secret[0].project
  secret_id = google_secret_manager_secret.gitlab_read_api_secret[0].secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

resource "google_secret_manager_secret_version" "gitlab_read_api_secret_version" {
  count = local.is_gl_repo ? 1 : 0
  secret = google_secret_manager_secret.gitlab_read_api_secret[0].id 
  secret_data = var.gitlab_read_api_access_token
}

resource "google_secret_manager_secret" "gitlab_webhook_secret" {
  count = local.is_gl_repo ? 1 : 0
  project = var.project_id
  secret_id = "im-gitlab-${local.gl_project}-${random_id.gitlab_resources_random_id[0].dec}-webhook-secret"
  labels = {
    label = "${var.deployment_id}"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_policy" "webhook_secret_policy" {
  count = local.is_gl_repo ? 1 : 0
  project     = google_secret_manager_secret.gitlab_webhook_secret[0].project
  secret_id = google_secret_manager_secret.gitlab_webhook_secret[0].secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

resource "random_uuid" "random_webhook_secret" {
  count = local.is_gl_repo ? 1 : 0
}

resource "google_secret_manager_secret_version" "gitlab_webhook_secret_version" {
  count = local.is_gl_repo ? 1 : 0
  secret = google_secret_manager_secret.gitlab_webhook_secret[0].id
  secret_data = random_uuid.random_webhook_secret[0].result
}