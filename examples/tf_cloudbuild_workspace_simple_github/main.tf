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
  // Found in the URL of your Cloud Build GitHub app configuration settings
  // https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen#connecting_a_github_host_programmatically
  github_app_installation_id = "47590865"

  # GitHub repo url of form "github.com/owner/name"
  repoURL              = endswith(var.repository_uri, ".git") ? var.repository_uri : "${var.repository_uri}.git"
  repoURLWithoutSuffix = trimsuffix(local.repoURL, ".git")
  gh_repo_url_split    = split("/", local.repoURLWithoutSuffix)
  gh_name              = local.gh_repo_url_split[length(local.gh_repo_url_split) - 1]

  location = "us-central1"
}

data "google_project" "project" {
  project_id = var.project_id
}

// Added to various IDs to prevent potential conflicts for deployments targeting the same repository.
resource "random_id" "resources_random_id" {
  byte_length = 4
}

module "tf_workspace" {
  source = "../../modules/tf_cloudbuild_workspace"

  project_id               = module.enabled_google_apis.project_id
  tf_repo_type             = "CLOUDBUILD_V2_REPOSITORY"
  tf_repo_uri              = google_cloudbuildv2_repository.repository_connection.id
  location                 = "us-central1"
  trigger_location         = "us-central1"
  artifacts_bucket_name    = "tf-configs-build-artifacts-${var.project_id}-gh"
  log_bucket_name          = "tf-configs-build-logs-${var.project_id}-gh"
  create_state_bucket_name = "tf-configs-build-state-${var.project_id}-gh"

  # allow log/state buckets to be destroyed
  buckets_force_destroy = true
  cloudbuild_sa_roles = { (module.enabled_google_apis.project_id) = {
    project_id = module.enabled_google_apis.project_id,
    roles      = ["roles/compute.networkAdmin"]
    }
  }
  cloudbuild_env_vars = ["TF_VAR_project_id=${var.project_id}"]

  depends_on = [module.enabled_google_apis]
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
  secret_data = var.github_pat
}

resource "google_secret_manager_secret_iam_member" "github_token_iam_member" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_token_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

// See https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen
resource "google_cloudbuildv2_connection" "vcs_connection" {
  project  = var.project_id
  name     = "cb-${random_id.resources_random_id.dec}-${var.project_id}"
  location = local.location

  github_config {
    app_installation_id = local.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_token_secret_version.name
    }
  }
}

// Create the repository connection.
resource "google_cloudbuildv2_repository" "repository_connection" {
  project  = var.project_id
  name     = local.gh_name
  location = local.location

  parent_connection = google_cloudbuildv2_connection.vcs_connection.name
  remote_uri        = local.repoURL
}

module "bootstrap_github_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"
  upgrade = false

  create_cmd_entrypoint = "${path.module}/scripts/push-to-repo.sh"
  create_cmd_body       = "${var.github_pat} ${var.repository_uri} ${path.module}/files"
}
