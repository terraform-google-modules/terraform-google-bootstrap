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
  value = module.cloudbuild_enabled.group_org_admins
}

output "seed_project_id" {
  value = module.cloudbuild_enabled.seed_project_id
}

output "terraform_sa_email" {
  value = module.cloudbuild_enabled.terraform_sa_email
}

output "terraform_sa_name" {
  value = module.cloudbuild_enabled.terraform_sa_name
}

output "gcs_bucket_tfstate" {
  value = module.cloudbuild_enabled.gcs_bucket_tfstate
}

output "cloudbuild_project_id" {
  value = module.cloudbuild_enabled.cloudbuild_project_id
}

output "gcs_bucket_cloudbuild_artifacts" {
  value = module.cloudbuild_enabled.gcs_bucket_cloudbuild_artifacts
}

output "csr_repos" {
  value = module.cloudbuild_enabled.csr_repos
}

output "kms_keyring" {
  value = module.cloudbuild_enabled.kms_keyring
}

output "kms_crypto_key" {
  value = module.cloudbuild_enabled.kms_crypto_key
}