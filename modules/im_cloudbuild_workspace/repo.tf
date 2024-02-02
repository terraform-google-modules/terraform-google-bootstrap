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
  # Remove ".git" suffix if it's included
  url = trimsuffix(var.im_deployment_repo_uri, ".git")

  # GitHub repo url of form "github.com/owner/name"
  is_gh_repo        = var.tf_repo_type == "GITHUB"
  gh_repo_url_split = local.is_gh_repo ? split("/", local.url) : []
  gh_owner          = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 2] : ""
  gh_name           = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 1] : ""

  # GitLab repo url of form "[host_uri]/[owners]/project"
  is_gl_repo = var.tf_repo_type == "GITLAB"
  gl_repo_url_split = local.is_gl_repo ? split("/", local.url) : []
  gl_host_uri = local.is_gl_repo ? join("", slice(local.gl_repo_url_split, 0, 3)) : "" 
  gl_project = local.is_gl_repo ? local.gl_repo_url_split[length(local.gl_repo_url_split) - 1] : ""

  # default prefix computed from repo name and dir if specified of form ${repo}-${dir?}-${plan/apply}
  repo = local.is_gh_repo ? local.gh_name : local.gl_project

  # TODO Come up with better default prefix to handle edge cases (underscores, slashes)
  # default_prefix = var.prefix != "" ? var.prefix : substr(replace(var.im_deployment_repo_uri != "" ? "${local.repo}-${var.im_deployment_repo_dir}" : local.repo, "/", "-"), 0, 25)
  default_prefix = replace(local.repo, "_", "-")

  repo_connection_name = var.repo_connection_name != "" ? var.repo_connection_name : "im-${local.repo}"
  secret_id            = var.secret_id != "" ? var.secret_id : "im-${local.repo}"
}

data "google_project" "project" {
  project_id = var.project_id
}

// Create a secret containing the personal access token and grant permissions to the Service Agent
resource "google_secret_manager_secret" "repo_token_secret" {
  project   = var.project_id
  secret_id = local.secret_id

  labels = {
    label = "im-repo-secret"
  }

  replication {
    auto {}
  }
}

// Personal access token from VCS.
resource "google_secret_manager_secret_version" "repo_token_secret_version" {
  secret      = google_secret_manager_secret.repo_token_secret.id
  secret_data = var.repo_personal_access_token
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

resource "random_uuid" "random_webhook_secret" {
}

resource "google_secret_manager_secret_version" "gitlab_webhook_secret_version" {
  count = local.is_gl_repo ? 1 : 0
  secret = google_secret_manager_secret.gitlab_webhook_secret[0].id
  secret_data = random_uuid.random_webhook_secret.result
}

data "google_iam_policy" "serviceagent_secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = google_secret_manager_secret.repo_token_secret.project
  secret_id   = google_secret_manager_secret.repo_token_secret.secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

// Create the VCS connection.
resource "google_cloudbuildv2_connection" "vcs_connection" {
  project  = var.project_id
  location = var.location
  # TODO This should be generated with some other values, at least have a variable.
  name = "im-vcs-connection"

  dynamic "github_config" {
    for_each = local.is_gh_repo ? [1] : []
    content {
      app_installation_id = var.github_app_installation_id
      authorizer_credential {
        oauth_token_secret_version = google_secret_manager_secret_version.repo_token_secret_version.id
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = local.is_gl_repo ? [1] : []
    content {
      host_uri = local.gl_host_uri != "" ? local.gl_host_uri : null
      authorizer_credential {
        user_token_secret_version = google_secret_manager_secret_version.gitlab_api_secret_version.name
      }
      read_authorizer_credential {
        user_token_secret_version = google_secret_manager_secret_version.gitlab_read_api_secret_version.name
      }
      webhook_secret_secret_version = google_secret_manager_secret_version.gitlab_webhook_secret_version.name
    }
  }

  depends_on = [google_secret_manager_secret_iam_policy.policy]
}

// Create the repository connection.
resource "google_cloudbuildv2_repository" "repository_connection" {
  project  = var.project_id
  location = var.location
  # TODO Combination of prefix, repo name
  name              = local.repo_connection_name
  parent_connection = google_cloudbuildv2_connection.vcs_connection.name
  remote_uri        = var.im_deployment_repo_uri
}
