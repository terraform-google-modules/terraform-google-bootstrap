/**
 * Copyright 2020 Google LLC
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
  Required variables
*******************************************/

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associate projects with."
  type        = string
}

variable "project" {
  description = "The seed project to host Terraform related resources."
  type = object({
    project_id    = string
    labels        = map(string)
    activate_apis = list(string)
  })
}

variable "state_bucket" {
  description = "The bucket to store Terraform remote state."
  type = object({
    name     = string
    location = string
    labels   = map(string)
  })
}

variable "service_account" {
  description = "The service account to run Terraform operations."
  type = object({
    account_id          = string
    grant_billing_user  = bool
    allow_impersonation = bool
    root_roles          = list(string)
    seed_project_roles  = list(string)
  })
}

variable "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
  type        = string
}

variable "group_billing_admins" {
  description = "Google Group for GCP Billing Administrators"
  type        = string
}

/******************************************
  Optional variables
*******************************************/

variable "sa_enable_impersonation" {
  description = "Allow org_admins group to impersonate service account & enable APIs required."
  type        = bool
  default     = false
}

variable "org_admins_org_iam_permissions" {
  description = "List of permissions granted to the group supplied in group_org_admins variable across the GCP organization."
  type        = list(string)
  default = [
    "roles/billing.user",
    "roles/resourcemanager.organizationAdmin"
  ]
}

variable "folder_id" {
  description = "The ID of a folder to host this project"
  type        = string
  default     = ""
}

variable "org_project_creators" {
  description = "Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required."
  type        = list(string)
  default     = []
}
