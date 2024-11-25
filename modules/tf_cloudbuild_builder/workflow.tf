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


locals {
  rendered_workflow_config = templatefile("${path.module}/templates/workflow.yaml.tftpl", {
    project_id        = var.project_id
    gar_repo_location = var.gar_repo_location
    gar_repo_name     = var.gar_repo_name
    trigger_id        = var.trigger_name
    location          = var.trigger_location
    trigger_hash      = google_cloudbuild_trigger.build_trigger.trigger_id
  })
  workflow_sa = coalesce(var.workflow_sa, google_service_account.workflow_sa[0].email)
}

resource "google_service_account" "workflow_sa" {
  count                        = var.workflow_sa == "" ? 1 : 0
  project                      = var.project_id
  account_id                   = "terraform-runner-workflow-sa"
  display_name                 = "SA for TF Builder Workflow. Managed by Terraform."
  create_ignore_already_exists = true
}

resource "google_workflows_workflow" "builder" {
  project             = var.project_id
  name                = var.workflow_name
  region              = var.workflow_region
  description         = "Workflow for triggering TF Runner builds. Managed by Terraform."
  service_account     = local.workflow_sa
  source_contents     = local.rendered_workflow_config
  deletion_protection = var.workflow_deletion_protection
}

# Allow Workflow SA to trigger workflow via scheduler
resource "google_project_iam_member" "invoke_workflow_scheduler" {
  project = var.project_id
  member  = "serviceAccount:${local.workflow_sa}"
  role    = "roles/workflows.invoker"
}

# Grant Workflow SA access to trigger builds
resource "google_project_iam_member" "trigger_builds" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${local.workflow_sa}"
}

resource "google_service_account_iam_member" "use_cb_sa" {
  service_account_id = local.cloudbuild_sa
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.workflow_sa}"
}

resource "google_cloud_scheduler_job" "trigger_workflow" {
  name        = "trigger-${var.workflow_name}"
  project     = var.project_id
  region      = var.workflow_region
  description = "Trigger workflow for TF Runner builds. Managed by Terraform."
  schedule    = var.workflow_schedule
  time_zone   = "Etc/UTC"

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.builder.id}/executions"
    http_method = "POST"
    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = local.workflow_sa
    }
  }
}
