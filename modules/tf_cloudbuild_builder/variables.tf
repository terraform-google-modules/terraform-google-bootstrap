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
  description = "GCP project for Cloud Build trigger,workflow and scheduler."
  type        = string
}

variable "workflow_name" {
  description = "Name of the workflow managing builds."
  type        = string
  default     = "terraform-runner-workflow"
}

variable "workflow_region" {
  description = "The region of the workflow."
  type        = string
  default     = "us-central1"
}

variable "workflow_schedule" {
  description = "The workflow frequency, in cron syntax"
  type        = string
  default     = "0 8 * * *"
}

variable "workflow_sa" {
  description = "Custom SA email to be used by the workflow. Defaults to being created if empty."
  type        = string
  default     = ""
}

variable "workflow_deletion_protection" {
  description = "Whether Terraform will be prevented from destroying the workflow. When the field is set to true or unset in Terraform state, a `terraform apply` or `terraform destroy` that would delete the workflow will fail. When the field is set to false, deleting the workflow is allowed."
  type        = bool
  default     = true
}

variable "cloudbuild_sa" {
  description = "Custom SA email to be used by the CloudBuild trigger. Defaults to being created if empty."
  type        = string
  default     = ""
}

variable "build_timeout" {
  description = "Amount of time the build should be allowed to run, to second granularity. Format is the number of seconds followed by s."
  type        = string
  default     = "600s"
}

variable "cb_logs_bucket_force_destroy" {
  description = "When deleting the bucket for storing CloudBuild logs, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

variable "gar_repo_name" {
  description = "Name of the Google Artifact Repository where the Terraform builder images are stored."
  type        = string
  default     = "tf-runners"
}

variable "gar_repo_location" {
  description = "Name of the location for the Google Artifact Repository."
  type        = string
}

variable "terraform_version" {
  description = "The initial terraform version in semantic version format."
  type        = string
  default     = "1.1.0"
}

variable "image_name" {
  description = "Name of the image for the Terraform builder."
  type        = string
  default     = "terraform"
}

variable "trigger_name" {
  description = "Name of the Cloud Build trigger building the Terraform builder."
  type        = string
  default     = "tf-cloud-builder-build"
}

variable "trigger_location" {
  description = "Location of the Cloud Build trigger building the Terraform builder. If using private pools should be the same location as the pool."
  type        = string
}

variable "dockerfile_repo_uri" {
  description = "The URI of the repo where the Dockerfile for Terraform builder is stored. If using Cloud Build Repositories (2nd Gen) this is the repository ID where the Dockerfile is stored. Repository ID Format is 'projects/{{project}}/locations/{{location}}/connections/{{parent_connection}}/repositories/{{name}}'"
  type        = string
  default     = ""
}

variable "use_cloudbuildv2_repository" {
  description = "Use Cloud Build repository (2nd gen)"
  type        = bool
  default     = false
}

variable "dockerfile_repo_ref" {
  description = "The branch or tag to use. Use refs/heads/branchname for branches or refs/tags/tagname for tags."
  type        = string
  default     = "refs/heads/main"
}

variable "dockerfile_repo_dir" {
  description = "The directory inside the repo where the Dockerfile is located. If empty defaults to repo root."
  type        = string
  default     = ""
}

variable "dockerfile_repo_type" {
  description = "Type of repo"
  type        = string
  default     = "CLOUD_SOURCE_REPOSITORIES"
  validation {
    condition     = contains(["UNKNOWN", "CLOUD_SOURCE_REPOSITORIES", "GITHUB", "BITBUCKET_SERVER"], var.dockerfile_repo_type)
    error_message = "Must be one of UNKNOWN, CLOUD_SOURCE_REPOSITORIES, GITHUB or BITBUCKET_SERVER."
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

variable "bucket_name" {
  description = "Custom bucket name for Cloud Build logs."
  type        = string
  default     = ""
}
