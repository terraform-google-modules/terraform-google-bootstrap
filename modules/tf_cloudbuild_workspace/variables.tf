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

variable "project_id" {
  description = "GCP project for Cloud Build triggers, state and log buckets."
  type        = string
}

variable "location" {
  description = "Location for build logs/state bucket"
  type        = string
  default     = "us-central1"
}

variable "trigger_location" {
  description = "Location of for Cloud Build triggers created in the workspace. If using private pools should be the same location as the pool."
  type        = string
}

variable "create_cloudbuild_sa" {
  description = "Create a Service Account for use in Cloud Build. If false `cloudbuild_sa` has to be specified."
  type        = bool
  default     = true
}

variable "create_cloudbuild_sa_name" {
  description = "Custom name to be used in the creation of the Cloud Build service account if `create_cloudbuild_sa` is true. Defaults to generated name if empty"
  type        = string
  default     = ""
}

variable "cloudbuild_sa" {
  description = "Custom SA id of form projects/{{project}}/serviceAccounts/{{email}} to be used by the CloudBuild trigger. Defaults to being created if empty."
  type        = string
  default     = ""
}

variable "diff_sa_project" {
  description = "Set to true if `cloudbuild_sa` is in a different project for setting up https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#cross-project_set_up."
  type        = bool
  default     = false
}

variable "create_state_bucket" {
  description = "Create a GCS bucket for storing state. If false `state_bucket_self_link` has to be specified."
  type        = bool
  default     = true
}

variable "create_state_bucket_name" {
  description = "Custom bucket name for storing TF state. Used if `create_state_bucket` is true. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "state_bucket_self_link" {
  description = "Custom GCS bucket for storing TF state. Defaults to being created if empty."
  type        = string
  default     = ""
}

variable "log_bucket_name" {
  description = "Custom bucket name for Cloud Build logs."
  type        = string
  default     = ""
}

variable "artifacts_bucket_name" {
  description = "Custom bucket name for Cloud Build artifacts."
  type        = string
  default     = ""
}

variable "cloudbuild_sa_roles" {
  description = "Optional to assign to custom CloudBuild SA. Map of project name or any static key to object with project_id and list of roles."
  type = map(object({
    project_id = string
    roles      = list(string)
  }))
  default = {}
}

variable "cloudbuild_plan_filename" {
  description = "Optional Cloud Build YAML definition used for terraform plan. Defaults to using inline definition."
  type        = string
  default     = null
}

variable "cloudbuild_apply_filename" {
  description = "Optional Cloud Build YAML definition used for terraform apply. Defaults to using inline definition."
  type        = string
  default     = null
}

variable "cloudbuild_env_vars" {
  description = "Optional list of environment variables to be used in builds. List of strings of form KEY=VALUE expected."
  type        = list(string)
  default     = []
}

variable "cloudbuild_included_files" {
  description = "Optional list. Changes affecting at least one of these files will invoke a build."
  type        = list(string)
  default     = []
}

variable "cloudbuild_ignored_files" {
  description = "Optional list. Changes only affecting ignored files will not invoke a build."
  type        = list(string)
  default     = []
}

variable "buckets_force_destroy" {
  description = "When deleting the bucket for storing CloudBuild logs/TF state, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

variable "substitutions" {
  description = "Map of substitutions to use in builds."
  type        = map(string)
  default     = {}
}

variable "tf_cloudbuilder" {
  description = "Name of the Cloud Builder image used for running build steps."
  type        = string
  default     = "hashicorp/terraform:1.3.10"
}

variable "prefix" {
  description = "Prefix of the state/log buckets and triggers planning/applying config. If unset computes a prefix from tf_repo_uri and tf_repo_dir variables."
  type        = string
  default     = ""
}

variable "tf_repo_uri" {
  description = "The URI of the repo where Terraform configs are stored. If using Cloud Build Repositories (2nd Gen) this is the repository ID where the Dockerfile is stored. Repository ID Format is 'projects/{{project}}/locations/{{location}}/connections/{{parent_connection}}/repositories/{{name}}'."
  type        = string
  default     = ""
}

variable "tf_apply_branches" {
  description = "List of git branches configured to run terraform apply Cloud Build trigger. All other branches will run plan by default."
  type        = list(string)
  default = [
    "main"
  ]
}

variable "tf_repo_dir" {
  description = "The directory inside the repo where the Terrafrom root config is located. If empty defaults to repo root."
  type        = string
  default     = ""
}

variable "tf_repo_type" {
  description = "Type of repo. When the repo type is CLOUDBUILD_V2_REPOSITORY, it will use the generic Cloudbuild 2nd gen Repository API."
  type        = string
  default     = "CLOUD_SOURCE_REPOSITORIES"
  validation {
    condition     = contains(["CLOUD_SOURCE_REPOSITORIES", "GITHUB", "CLOUDBUILD_V2_REPOSITORY"], var.tf_repo_type)
    error_message = "Must be one of CLOUD_SOURCE_REPOSITORIES, GITHUB, or CLOUDBUILD_V2_REPOSITORY"
  }
}

variable "enable_worker_pool" {
  description = "Set to true to use a private worker pool in the Cloud Build Trigger."
  type        = bool
  default     = false
}

variable "worker_pool_id" {
  description = "Custom private worker pool ID. Format: 'projects/PROJECT_ID/locations/REGION/workerPools/PRIVATE_POOL_ID'."
  type        = string
  default     = ""
}
