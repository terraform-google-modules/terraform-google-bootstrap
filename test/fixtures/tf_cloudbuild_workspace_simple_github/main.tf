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

# Github Secret
resource "google_secret_manager_secret" "github_token" {
  project   = var.project_id
  secret_id = "cb-gh-${random_id.suffix.dec}"

  replication {
    auto {

    }
  }
}

resource "google_secret_manager_secret_version" "github_token" {
  secret      = google_secret_manager_secret.github_token.id
  secret_data = var.github_pat
}

resource "google_secret_manager_secret" "github_app_id" {
  project   = var.project_id
  secret_id = "cb-gh-app-id-${random_id.suffix.dec}"

  replication {
    auto {

    }
  }
}

resource "google_secret_manager_secret_version" "github_app_id" {
  secret      = google_secret_manager_secret.github_app_id.id
  secret_data = var.github_app_id
}

module "example" {
  source = "../../../examples/tf_cloudbuild_workspace_simple_github"

  project_id              = var.project_id
  github_pat_secret_id    = google_secret_manager_secret.github_token.id
  github_app_id_secret_id = google_secret_manager_secret.github_app_id.id
  repository_uri          = var.repository_uri
}
