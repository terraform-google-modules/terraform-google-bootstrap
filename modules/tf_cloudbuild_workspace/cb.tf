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
  # regex for branches to trigger for apply trigger
  apply_branches_regex = "^(${join("|", var.tf_apply_branches)})$"

  # extract CSR project_id and repo name for granting reader access to CSR repo
  is_source_repo = var.tf_repo_type == "CLOUD_SOURCE_REPOSITORIES"
  # url of form https://source.developers.google.com/p/<PROJECT_ID>/r/<REPO>
  source_repo_url_split = local.is_source_repo ? split("/", var.tf_repo_uri) : []
  source_repo_project   = local.is_source_repo ? local.source_repo_url_split[length(local.source_repo_url_split) - 3] : ""
  source_repo_name      = local.is_source_repo ? local.source_repo_url_split[length(local.source_repo_url_split) - 1] : ""

  # GH repo url of form "github.com/owner/name"
  is_gh_repo        = var.tf_repo_type == "GITHUB"
  gh_repo_url_split = local.is_gh_repo ? split("/", var.tf_repo_uri) : []
  gh_owner          = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 2] : ""
  gh_name           = local.is_gh_repo ? local.gh_repo_url_split[length(local.gh_repo_url_split) - 1] : ""

  is_cb_v2_repo = var.tf_repo_type == "CLOUDBUILD_V2_REPOSITORY"
  # Generic repo name extracted from format projects/{{project}}/locations/{{location}}/connections/{{name}}
  cb_v2_repo_name = local.is_cb_v2_repo ? element(split("/", var.tf_repo_uri), length(split("/", var.tf_repo_uri)) - 1) : ""

  # default build steps
  default_entrypoint = "terraform"
  default_build_plan = [
    ["init", "-backend-config=bucket=${local.state_bucket_name}"],
    ["plan", "-input=false", "-out=plan.tfplan"]
  ]
  default_build_apply = concat(local.default_build_plan, [["apply", "-input=false", "--auto-approve", "plan.tfplan"]])
  default_triggers_steps = {
    "plan"  = local.default_build_plan,
    "apply" = local.default_build_apply
  }
  default_triggers_explicit = {
    "plan"  = var.cloudbuild_plan_filename,
    "apply" = var.cloudbuild_apply_filename
  }

  # default prefix computed from repo name and dir if specified of form ${repo}-${dir?}-${plan/apply}
  repo                 = local.is_source_repo ? local.source_repo_name : local.is_cb_v2_repo ? local.cb_v2_repo_name : local.gh_name
  default_prefix       = var.prefix != "" ? var.prefix : replace(var.tf_repo_dir != "" ? "${local.repo}-${var.tf_repo_dir}" : local.repo, "/", "-")
  repo_uri_description = local.is_cb_v2_repo ? local.cb_v2_repo_name : var.tf_repo_uri

  # default substitutions
  default_subst = merge({
    "_TF_SA_EMAIL"          = local.cloudbuild_sa_email,
    "_STATE_BUCKET_NAME"    = local.state_bucket_name,
    "_LOG_BUCKET_NAME"      = local.log_bucket_name,
    "_ARTIFACT_BUCKET_NAME" = local.artifacts_bucket_name,
  }, var.enable_worker_pool ? { "_PRIVATE_POOL" = var.worker_pool_id, } : {})
}

resource "google_cloudbuild_trigger" "triggers" {
  for_each = local.default_triggers_steps

  project     = var.project_id
  location    = var.trigger_location
  name        = "${local.default_prefix}-${each.key}"
  description = "${title(each.key)} Terraform configs for ${local.repo_uri_description} ${var.tf_repo_dir}. Managed by Terraform."

  # CSR repo
  dynamic "trigger_template" {
    for_each = local.is_source_repo ? [1] : []
    content {
      branch_name  = local.apply_branches_regex
      repo_name    = local.source_repo_name
      invert_regex = each.key == "apply" ? false : true
    }
  }

  # Generic Cloud Build 2nd Gen Repository
  dynamic "repository_event_config" {
    for_each = local.is_cb_v2_repo ? [1] : []
    content {
      repository = var.tf_repo_uri
      # plan for non apply branch
      dynamic "push" {
        for_each = each.key != "apply" ? [1] : []
        content {
          branch       = local.apply_branches_regex
          invert_regex = true
        }
      }
      # apply for pushes to apply branches
      dynamic "push" {
        for_each = each.key != "apply" ? [] : [1]
        content {
          branch       = local.apply_branches_regex
          invert_regex = false
        }
      }
    }
  }

  # GH repo
  dynamic "github" {
    for_each = local.is_gh_repo ? [1] : []
    content {
      owner = local.gh_owner
      name  = local.gh_name
      # plan for PRs targeting apply branches
      dynamic "pull_request" {
        for_each = each.key != "apply" ? [1] : []
        content {
          branch       = local.apply_branches_regex
          invert_regex = false
        }
      }
      # apply for pushes to apply branches
      dynamic "push" {
        for_each = each.key != "apply" ? [] : [1]
        content {
          branch       = local.apply_branches_regex
          invert_regex = false
        }
      }
    }
  }

  # todo(bharathkkb): switch to yaml after https://github.com/hashicorp/terraform-provider-google/issues/9818
  dynamic "build" {
    # only enable inline build config if no explicit config specified
    for_each = var.cloudbuild_plan_filename == null && var.cloudbuild_apply_filename == null ? [1] : []
    content {
      dynamic "step" {
        for_each = each.value
        content {
          name       = var.tf_cloudbuilder
          entrypoint = local.default_entrypoint
          args       = tolist(step.value)
          dir        = var.tf_repo_dir != "" ? var.tf_repo_dir : null
        }
      }
      logs_bucket = module.log_bucket.bucket.url
      # upload tfplan artifacts per build
      artifacts {
        objects {
          location = join("/", [module.artifacts_bucket.bucket.url, each.key, "$BUILD_ID"])
          paths    = [join("/", compact([var.tf_repo_dir, "*.tfplan"]))]
        }
      }
      options {
        env = var.cloudbuild_env_vars
      }
    }
  }

  substitutions   = merge(local.default_subst, var.substitutions)
  service_account = local.cloudbuild_sa
  filename        = local.default_triggers_explicit[each.key]
  included_files  = var.cloudbuild_included_files
  ignored_files   = var.cloudbuild_ignored_files

  depends_on = [
    google_project_iam_member.cb_sa_roles
  ]
}
