/**
 * Copyright 2022 Google LLC
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
  gar_name = split("/", google_artifact_registry_repository.tf-image-repo.name)[length(split("/", google_artifact_registry_repository.tf-image-repo.name)) - 1]
}

resource "google_artifact_registry_repository" "tf-image-repo" {
  provider = google-beta
  project  = var.project_id

  location      = var.gar_repo_location
  repository_id = var.gar_repo_name
  description   = "Docker repository for Terraform runner images used by Cloud Build. Managed by Terraform."
  format        = "DOCKER"
}

# Grant CB SA permissions to push to repo
resource "google_artifact_registry_repository_iam_member" "push_images" {
  provider = google-beta
  project  = var.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Grant Workflows SA access to list images in the artifact repo
resource "google_artifact_registry_repository_iam_member" "workflow_list" {
  provider = google-beta
  project  = var.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${local.workflow_sa}"
}
