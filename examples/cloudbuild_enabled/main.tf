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

/*************************************************
  Bootstrap GCP Organization.
*************************************************/

module "seed_bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
  version = "~> 11.0"

  org_id                  = var.org_id
  billing_account         = var.billing_account
  group_org_admins        = var.group_org_admins
  group_billing_admins    = var.group_billing_admins
  default_region          = var.default_region
  org_project_creators    = var.org_project_creators
  sa_enable_impersonation = true
  project_prefix          = var.project_prefix
  force_destroy           = var.force_destroy
  project_deletion_policy = var.project_deletion_policy
}

module "cloudbuild_bootstrap" {
  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
  version = "~> 11.0"

  org_id                  = var.org_id
  billing_account         = var.billing_account
  group_org_admins        = var.group_org_admins
  default_region          = var.default_region
  sa_enable_impersonation = true
  terraform_sa_email      = module.seed_bootstrap.terraform_sa_email
  terraform_sa_name       = module.seed_bootstrap.terraform_sa_name
  terraform_state_bucket  = module.seed_bootstrap.gcs_bucket_tfstate
  project_prefix          = var.project_prefix
  force_destroy           = var.force_destroy
  project_deletion_policy = var.project_deletion_policy
}
