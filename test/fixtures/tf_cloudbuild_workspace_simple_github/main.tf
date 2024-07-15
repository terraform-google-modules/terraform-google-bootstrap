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
  github_app_installation_id = "47590865"
  location                   = "us-central1"
  repoURL                    = endswith(var.repository_uri, ".git") ? var.repository_uri : "${var.repository_uri}.git"

  repoURLWithoutSuffix = trimsuffix(local.repoURL, ".git")
  gh_repo_url_split    = split("/", local.repoURLWithoutSuffix)
  gh_name              = local.gh_repo_url_split[length(local.gh_repo_url_split) - 1]

  github_secret_version_id = google_secret_manager_secret_version.github_token_secret_version.name
  github_secret_id         = google_secret_manager_secret.github_token_secret.id

  host_connection_name = "cb-${random_id.resources_random_id.dec}-${var.project_id}"
  repo_connection_name = "cb-${random_id.resources_random_id.dec}-${local.gh_name}"
}

module "github_workspace" {
  source = "../../../examples/tf_cloudbuild_workspace_simple_github"

  project_id                 = var.project_id
  cloudbuildv2_repository_id = google_cloudbuildv2_repository.repository_connection.id
  create_cloudbuild_sa       = true
  create_cloudbuild_sa_name  = "tf-deploy-cb-github"
  github_pat                 = var.im_github_pat
  repository_uri             = var.repository_uri
}

// Create a secret containing the personal access token and grant permissions to the Service Agent.
resource "google_secret_manager_secret" "github_token_secret" {
  project   = var.project_id
  secret_id = "cb-github-${random_id.resources_random_id.dec}-${local.gh_name}"

  labels = {
    label = "cb-${random_id.resources_random_id.dec}"
  }

  replication {
    auto {}
  }
}

// Personal access token from VCS.
resource "google_secret_manager_secret_version" "github_token_secret_version" {
  secret      = google_secret_manager_secret.github_token_secret.id
  secret_data = var.im_github_pat
}

resource "google_secret_manager_secret_iam_member" "github_token_iam_member" {
  project   = var.project_id
  secret_id = local.github_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

// Added to various IDs to prevent potential conflicts for deployments targeting the same repository.
resource "random_id" "resources_random_id" {
  byte_length = 4
}

resource "google_cloudbuildv2_connection" "vcs_connection" {
  project  = var.project_id
  location = local.location

  name = local.host_connection_name

  github_config {
    app_installation_id = local.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = local.github_secret_version_id
    }
  }
}

// Create the repository connection.
resource "google_cloudbuildv2_repository" "repository_connection" {
  project           = var.project_id
  location          = local.location
  name              = local.repo_connection_name
  parent_connection = google_cloudbuildv2_connection.vcs_connection.name
  remote_uri        = local.repoURL
}
