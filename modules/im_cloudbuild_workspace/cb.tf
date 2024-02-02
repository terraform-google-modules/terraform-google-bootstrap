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

locals {
  deployment_exists_env_filename = "deployment_exists.env"
  binary_signed_uri_filename = "binary_signed_uri.env"

  # TODO Should scripts sit within a helpers/ directory?
  # Checking if a deployment exists already and saving result of command in workspace
  describe_deployment_script = <<-EOT
  #!/usr/bin/env bash
  gcloud infra-manager deployments describe projects/${var.project_id}/locations/${var.location}/deployments/${var.deployment_id}
  echo $? > /workspace/${local.deployment_exists_env_filename}
  EOT

  default_create_preview_command = <<-EOT
  gcloud infra-manager previews create projects/${var.project_id}/locations/${var.location}/previews/preview-$SHORT_SHA \
    --service-account=${local.im_sa} \
    --git-source-repo=${var.im_deployment_repo_uri} \
    --git-source-ref=$SHORT_SHA \
    ${var.im_deployment_repo_dir != "" ? "--git-source-directory=${var.im_deployment_repo_dir} \\" : ""}
    ${var.im_tf_variables != "" ? "--input-values=${var.im_tf_variables} \\" : ""}
  EOT

  default_delete_existing_preview_command = "gcloud infra-manager previews delete projects/${var.project_id}/locations/${var.location}/previews/preview-$SHORT_SHA --quiet || exit 0" 

  # Add deployment flag if the deployment already exists
  # TODO 
  default_create_preview_script = <<-EOT
  #!/usr/bin/env bash
  [ $(cat /workspace/${local.deployment_exists_env_filename}) -eq 0 ] && ${local.default_create_preview_command} --deployment projects/${var.project_id}/locations/${var.location}/deployments/${var.deployment_id} || ${local.default_create_preview_command}
  EOT

  # TODO This may be able to not be in a script field
  # TODO May need a way to short circuit if any of these steps fail for some reason.
  # Download preview binary plan
  default_download_preview_script = <<-EOT
  #!/usr/bin/env bash
  curl $(gcloud infra-manager previews export projects/${var.project_id}/locations/${var.location}/previews/preview-$SHORT_SHA --format="get(result.binarySignedUri)") -o /workspace/plan.tfplan
  EOT

  default_output_preview_script = <<-EOT
  terraform init -no-color
  terraform show /workspace/plan.tfplan -no-color
  EOT

  default_preview_steps = [
    { id = "check_for_existing_deployment", name = "gcr.io/cloud-builders/gcloud", script = "${local.describe_deployment_script}" },
    { id = "delete_existing_preview", name = "gcr.io/cloud-builders/gcloud", script = local.default_delete_existing_preview_command },
    { id = "create_preview", name = "gcr.io/cloud-builders/gcloud", script = "${local.default_create_preview_script}"},
    { id = "download_preview", name = "gcr.io/cloud-builders/gcloud", script = "${local.default_download_preview_script}"},
    { id = "preview_results", name = "${var.tf_cloudbuilder}", script = "${local.default_output_preview_script}"},
  ]

  default_apply_steps = [
    {
      id = "apply"
      name = "gcr.io/cloud-builders/gcloud",
      args = compact([
        "infra-manager",
        "deployments",
        "apply",
        "projects/${var.project_id}/locations/${var.location}/deployments/${var.deployment_id}",
        "--service-account=${local.im_sa}",
        "--git-source-repo=${var.im_deployment_repo_uri}",
        "${var.im_deployment_repo_dir != "" ? "--git-source-directory=${var.im_deployment_repo_dir}" : ""}",
        "${var.im_deployment_branch != "" ? "--git-source-ref=${var.im_deployment_branch}" : ""}",
        "${var.im_tf_variables != "" ? "--input-values=${var.im_tf_variables}" : ""}"
      ])
    }
  ]

  default_triggers_steps = {
    "preview" = local.default_preview_steps,
    "apply" = local.default_apply_steps
  }
}

resource "google_cloudbuild_trigger" "triggers" {
  for_each = local.default_triggers_steps

  project     = var.project_id
  location    = var.trigger_location
  name        = "${local.default_prefix}-${each.key}"
  description = "${title(each.key)} Terraform configs for ${var.im_deployment_repo_uri} ${var.im_deployment_repo_dir}. Managed by Infrastructure Manager."
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  # TODO Test if this will work for GitLab
  repository_event_config {
    repository = google_cloudbuildv2_repository.repository_connection.id
    dynamic pull_request {
      for_each = each.key == "preview" ? [1] : []
      content {
        branch = var.im_deployment_branch
        invert_regex = false
      }
    }
    dynamic push {
      for_each = each.key == "apply" ? [1] : []
      content {
        branch = var.im_deployment_branch
        invert_regex = false
      }
    }
  }

  dynamic "build" {
    # only enable inline build config if no explicit config specified
    for_each = var.cloudbuild_preview_filename == null && var.cloudbuild_apply_filename == null ? [1] : []
    content {
      dynamic "step" {
        for_each = each.value
        content {
          id = step.value.id 
          name = step.value.name
          entrypoint = try(step.value.entrypoint, null)
          args = try(step.value.args, null)
          script = try(step.value.script, null)
          env = [
            "SHORT_SHA=$SHORT_SHA"
          ]
        }
      }
      options {
        logging = "CLOUD_LOGGING_ONLY"
      }
    }
  }

  service_account = local.cloudbuild_sa

  depends_on = [
    google_project_iam_member.im_sa_roles,
    google_cloudbuildv2_connection.vcs_connection,
    google_cloudbuildv2_repository.repository_connection
  ]
}
