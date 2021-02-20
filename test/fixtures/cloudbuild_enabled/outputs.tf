/**
 * Copyright 2018 Google LLC
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

output "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
  value       = var.group_org_admins
}

output "seed_project_id" {
  description = "Project where service accounts and core APIs will be enabled."
  value       = module.cloudbuild_enabled.seed_project_id
}

output "terraform_sa_email" {
  description = "Email for privileged service account for Terraform."
  value       = module.cloudbuild_enabled.terraform_sa_email
}

output "terraform_sa_name" {
  description = "Fully qualified name for privileged service account for Terraform."
  value       = module.cloudbuild_enabled.terraform_sa_name
}

output "gcs_bucket_tfstate" {
  description = "Bucket used for storing terraform state for foundations pipelines in seed project."
  value       = module.cloudbuild_enabled.gcs_bucket_tfstate
}

output "cloudbuild_project_id" {
  description = "Project where CloudBuild configuration and terraform container image will reside."
  value       = module.cloudbuild_enabled.cloudbuild_project_id
}

output "gcs_bucket_cloudbuild_artifacts" {
  description = "Bucket used to store Cloud/Build artefacts in CloudBuild project."
  value       = module.cloudbuild_enabled.gcs_bucket_cloudbuild_artifacts
}

output "csr_repos" {
  description = "List of Cloud Source Repos created by the module, linked to Cloud Build triggers."
  value       = module.cloudbuild_enabled.csr_repos
}

output "kms_keyring" {
  description = "KMS Keyring created by the module."
  value       = module.cloudbuild_enabled.kms_keyring
}

output "kms_crypto_key" {
  description = "KMS key created by the module."
  value       = module.cloudbuild_enabled.kms_crypto_key
}

output "tf_runner_artifact_repo" {
  description = "GAR Repo created to store runner images"
  value       = module.cloudbuild_enabled.tf_runner_artifact_repo
}
