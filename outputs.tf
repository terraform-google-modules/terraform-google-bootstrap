/**
 * Copyright 2019 Google LLC
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

/******************************************
  Project
*******************************************/

output "seed_project_id" {
  description = "Project where service accounts and core APIs will be enabled."
  value       = module.seed_project.project_id
}

/******************************************
  Service Account
*******************************************/

output "terraform_sa_email" {
  description = "Email for privileged service account."
  value       = google_service_account.org_terraform.email
}

output "terraform_sa_name" {
  description = "Fully qualified name for privileged service account."
  value       = google_service_account.org_terraform.name
}

/******************************************
  GCS Terraform State Bucket
*******************************************/

output "gcs_bucket_tfstate" {
  description = "Bucket used for storing terraform state for foundations pipelines in seed project."
  value       = google_storage_bucket.org_terraform_state.name
}
