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

variable "cloudbuild_sa" {
  description = "Custom SA email to be used by the CloudBuild trigger. Defaults to being created if empty."
  type        = string
  default     = ""
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
  default     = "us"
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

variable "dockerfile_repo_uri" {
  description = "The URI of the repo where the Dockerfile for Terraform builder is stored"
  type        = string
}

variable "dockerfile_repo_ref" {
  description = "The branch or tag to use. Use refs/heads/branchname for branches or refs/tags/tagname for tags."
  type        = string
  default     = "refs/heads/main"
}

variable "dockerfile_repo_dir" {
  description = "The directory inside the repo where the Dockerfile is located. If empty defaults to repo root."
  default     = ""
}

variable "dockerfile_repo_type" {
  description = "Type of repo"
  default     = "CLOUD_SOURCE_REPOSITORIES"
  validation {
    condition     = contains(["UNKNOWN", "CLOUD_SOURCE_REPOSITORIES", "GITHUB", "BITBUCKET_SERVER"], var.dockerfile_repo_type)
    error_message = "Must be one of UNKNOWN, CLOUD_SOURCE_REPOSITORIES, GITHUB or BITBUCKET_SERVER."
  }
}
