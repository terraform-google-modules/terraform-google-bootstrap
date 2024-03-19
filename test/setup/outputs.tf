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

output "project_id" {
  value = module.project.project_id
}

output "sa_key" {
  value     = google_service_account_key.int_test.private_key
  sensitive = true
}

output "org_id" {
  value = var.org_id
}

output "folder_id" {
  value = var.folder_id
}

output "parent_folder" {
  value = google_folder.bootstrap.name
}

output "billing_account" {
  value = var.billing_account
}

output "group_org_admins" {
  value = var.group_org_admins
}

output "group_billing_admins" {
  value = var.group_billing_admins
}

output "default_region" {
  value = var.default_region
}

output "org_project_creators" {
  value = ["serviceAccount:${google_service_account.int_test.email}"]
}

output "random_testing_string" {
  description = "Access the random ID created in setup for labeling other resources."
  value       = random_id.suffix.hex
}
