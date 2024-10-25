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

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "parent" {
  description = "GCP parent folder id of form folders/{id}"
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associate projects with."
  type        = string
}

variable "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
  type        = string
}

variable "group_billing_admins" {
  description = "Google Group for GCP Billing Administrators"
  type        = string
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "org_project_creators" {
  description = "Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required."
  type        = list(string)
  default     = []
}

variable "project_prefix" {
  description = "Name prefix to use for projects created."
  default     = "cft"
  type        = string
}

variable "project_deletion_policy" {
  description = "The deletion policy for the project created."
  type        = string
  default     = "PREVENT"
}
