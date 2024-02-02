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

variable "project_id" {
  description = "GCP project for Infrastructure Manager deployments and Cloud Build triggers."
  type        = string
}


variable "location" {
  description = "Location for Infrastructure Manager deployment."
  type        = string
  default     = "us-central1"
}

variable "trigger_location" {
  description = "Location of for Cloud Build triggers created in the workspace. If using private pools should be the same location as the pool."
  type        = string
  default     = "us-central1"
}

variable "deployment_id" {
  description = "Custom ID to be used for the Infrastructure Manager deployment."
  type = string
}

variable "secret_id" {
  description = "Custom name for the secret in Secrets Manager for creating a repository connection. Generated if not given."
  type = string
  default = ""
}

// TODO Revisit description?
variable "repo_personal_access_token" {
  description = "Personal access token for a repository."
  type = string
  sensitive = true
}

// TODO Support generating this name?
variable "repo_connection_name" {
  description = "Connection name for linked repository. Generated if not given."
  type = string
  default = ""
}

variable "github_app_installation_id" {
  description = "Installation ID of the Cloud Build GitHub app."
  type = string
}

variable "create_cloudbuild_sa" {
  description = "Create a Service Account for creating Cloud Build triggers. If false `cloudbuild_sa` has to be specified."
  type        = bool
  default     = true
}

variable "create_cloudbuild_sa_name" {
  description = "Custom name to be used in the creation of the Cloud Build trigger service account if `create_cloudbuild_sa` is true. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "cloudbuild_sa" {
  description = "Custom SA ID of form projects/{{project}}/serviceAccounts/{{email}} to be used for creating Cloud Build triggers. Defaults to being created if empty."
  type        = string
  default     = ""
}

variable "create_infra_manager_sa" {
  description = "Create a Service Account for use of Infrastructure Manager. If false `infra_manager_sa` has to be specified."
  type = bool
  default = true 
}

variable "create_infra_manager_sa_name" {
  description = "Custom name to be used in the creation of the Infrastructure Manager service account if `create_infra_manager_sa` is true. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "infra_manager_sa" {
  description = "Custom SA id of form projects/{{project}}/serviceAccounts/{{email}} to be used by Infra Manager. Defaults to generated name if empty."
  type = string
  default = ""
}

variable "infra_manager_sa_roles" {
  description = "Roles to grant to Infrastructure Manager SA for resources defined in Terraform configuration. Map of project name or any static key to object with project_id and list of roles."
  type = map(object({
    project_id = string
    roles      = list(string)
  }))
  default = {}
}

variable "im_deployment_repo_uri" {
  description = "The URI of the repo where the Terraform configs are stored."
  type = string
}

variable "im_deployment_repo_dir" {
  description = "The directory inside the repo where the Terraform root config is located. If empty defaults to repo root."
  type = string
  default = ""
}

variable "im_deployment_branch" {
  description = "Git branch configured to run infra-manager apply. All other branches will run plan by default."
  type = string
  default = "main"
}

variable "im_tf_variables" {
  description = "Optional list of Terraform variables to pass to Infrastructure Manager, if the configuration exists in a different repo. List of strings of form KEY=VALUE expected."
  type = string
  default = null
}

variable "cloudbuild_preview_filename" {
  description = "Optional Cloud Build YAML definition used for Cloud Build triggers of Infra Manager preview. Defaults to using inline definition."
  type        = string
  default     = null
}

variable "cloudbuild_apply_filename" {
  description = "Optional Cloud Build YAML definition used for Cloud Build triggers of Infra Manager apply. Defaults to using inline definition."
  type        = string
  default     = null
}

variable "tf_cloudbuilder" {
  description = "Name of the Cloud Builder image used for running build steps."
  type        = string
  default     = "hashicorp/terraform"
}

variable "tf_repo_type" {
  description = "Type of repo"
  type        = string
  default = "GITHUB"
}

variable "gitlab_api_access_token" {
  description = "GitLab personal access token with api scope to be saved in Secrets Manager."
  type = string
  sensitive = true
  default = null
}

variable "gitlab_read_api_access_token" {
  description = "GitLab personal access token with read_api scope to be saved in Secrets Manager."
  type = string
  sensitive = true
  default = null
}

#####
# TODO Evaluate all variables below this line
#####

variable "diff_sa_project" {
  description = "Set to true if `cloudbuild_sa` is in a different project for setting up https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#cross-project_set_up."
  type        = bool
  default     = false
}

variable "artifacts_bucket_name" {
  description = "Custom bucket name for Cloud Build artifacts."
  type        = string
  default     = ""
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

variable "substitutions" {
  description = "Map of substitutions to use in builds."
  type        = map(string)
  default     = {}
}

variable "prefix" {
  description = "Prefix of the state/log buckets and triggers planning/applying config. If unset computes a prefix from tf_repo_uri and tf_repo_dir variables."
  type        = string
  default     = ""
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
