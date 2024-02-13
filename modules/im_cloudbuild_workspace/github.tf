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
  # GitHub repo url of form "github.com/owner/name"
  is_gh_repo        = var.tf_repo_type == "GITHUB"
  gh_repo_url_split = local.is_gh_repo ? split("/", local.url) : []
  gh_owner          = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 2] : ""
  gh_name           = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 1] : ""

  # TODO Finalize name of the secret ID
  secret_id            = var.secret_id != "" ? var.secret_id : "im-${local.repo}"
}

// Create a secret containing the personal access token and grant permissions to the Service Agent.
resource "google_secret_manager_secret" "github_token_secret" {
  count = local.is_gh_repo ? 1 : 0
  project = var.project_id
  secret_id = local.secret_id

  labels = {
    label = "infra-manager"
  }

  replication {
    auto {}
  }
}

// Personal access token from VCS.
resource "google_secret_manager_secret_version" "github_token_secret_version" {
  count = local.is_gh_repo ? 1 : 0
  secret      = google_secret_manager_secret.github_token_secret[0].id
  secret_data = var.github_personal_access_token
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  count = local.is_gh_repo ? 1 : 0
  project     = google_secret_manager_secret.github_token_secret[0].project
  secret_id   = google_secret_manager_secret.github_token_secret[0].secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}