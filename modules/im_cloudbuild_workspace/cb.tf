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
  tf_cloudbuilder_image = "${var.tf_cloudbuilder}:${var.tf_version}"

  default_create_preview_script = templatefile("${path.module}/templates/create-preview.sh.tftpl", {
    project_id      = var.project_id
    location        = var.location
    deployment_id   = var.deployment_id
    service_account = local.im_sa
    source_repo     = local.repoURL
    source_repo_dir = var.im_deployment_repo_dir
    tf_vars         = var.im_tf_variables
  })

  default_preview_steps = [
    { id = "git_setup", name = "gcr.io/cloud-builders/git", args = ["config", "--global", "init.defaultBranch", "main"] },
    { id = "create_preview", name = "gcr.io/cloud-builders/gcloud", script = local.default_create_preview_script },
    { id = "download_preview", name = "gcr.io/cloud-builders/gcloud", args = ["infra-manager", "previews", "export", "projects/${var.project_id}/locations/${var.location}/previews/preview-$SHORT_SHA", "--file", "plan"] },
    { id = "terraform_init", name = local.tf_cloudbuilder_image, args = ["init", "-no-color"] },
    { id = "terraform_show", name = local.tf_cloudbuilder_image, args = ["show", "/workspace/plan.tfplan", "-no-color"] },
  ]

  default_apply_steps = [
    {
      id   = "apply"
      name = "gcr.io/cloud-builders/gcloud",
      args = compact([
        "infra-manager",
        "deployments",
        "apply",
        "projects/${var.project_id}/locations/${var.location}/deployments/${var.deployment_id}",
        "--service-account=${local.im_sa}",
        "--git-source-repo=${local.repoURL}",
        var.im_deployment_repo_dir != "" ? "--git-source-directory=${var.im_deployment_repo_dir}" : "",
        var.im_deployment_ref != "" ? "--git-source-ref=${var.im_deployment_ref}" : "",
        var.im_tf_variables != "" ? "--input-values=${var.im_tf_variables}" : "",
        "--tf-version-constraint=${var.tf_version}",
      ])
    }
  ]

  default_triggers_steps = {
    "preview" = local.default_preview_steps,
    "apply"   = local.default_apply_steps
  }
}

resource "google_cloudbuild_trigger" "triggers" {
  for_each = local.default_triggers_steps

  project            = var.project_id
  location           = var.trigger_location
  name               = substr("im-${each.key}-${random_id.resources_random_id.dec}-${local.default_prefix}", 0, 64)
  description        = "${title(each.key)} Terraform configs for ${local.repoURL} ${var.im_deployment_repo_dir}"
  include_build_logs = local.is_gh_repo ? "INCLUDE_BUILD_LOGS_WITH_STATUS" : null

  repository_event_config {
    repository = google_cloudbuildv2_repository.repository_connection.id
    dynamic "pull_request" {
      for_each = (each.key == "preview") && (local.is_gh_repo) ? [1] : []
      content {
        branch          = var.im_deployment_ref
        invert_regex    = false
        comment_control = var.pull_request_comment_control
      }
    }
    dynamic "push" {
      for_each = (each.key == "preview") && (local.is_gl_repo) ? [1] : []
      content {
        branch       = var.im_deployment_ref
        invert_regex = true
      }
    }
    dynamic "push" {
      for_each = each.key == "apply" ? [1] : []
      content {
        branch       = var.im_deployment_ref
        invert_regex = false
      }
    }
  }

  dynamic "build" {
    # only enable inline build config if no explicit config specified
    for_each = var.cloudbuild_preview_filename == "" && var.cloudbuild_apply_filename == "" ? [1] : []
    content {
      dynamic "step" {
        for_each = each.value
        content {
          id         = step.value.id
          name       = step.value.name
          entrypoint = try(step.value.entrypoint, null)
          args       = try(step.value.args, null)
          script     = try(step.value.script, null)
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
  substitutions   = var.substitutions
  included_files  = var.cloudbuild_included_files
  ignored_files   = var.cloudbuild_ignored_files

  depends_on = [google_project_iam_member.im_sa_roles]
}
