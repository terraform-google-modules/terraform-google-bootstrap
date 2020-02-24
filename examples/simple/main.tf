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

provider "google" {
  version = "~> 3.5.0"
}

provider "google-beta" {
  version = "~> 3.5.0"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

/*************************************************
  Make sure group_org_admins has projectCreator.
*************************************************/

data "google_organization" "org" {
  organization = var.org_id
  depends_on = [
    google_organization_iam_member.tmp_project_creator
  ]
}

resource "google_organization_iam_member" "tmp_project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "group:${var.group_org_admins}"
}

/*************************************************
  Bootstrap GCP Organization.
*************************************************/

module "seed_bootstrap" {
  source               = "../.."
  org_id               = data.google_organization.org.org_id
  billing_account      = var.billing_account
  group_org_admins     = var.group_org_admins
  group_billing_admins = var.group_billing_admins
  default_region       = var.default_region
  org_project_creators = var.org_project_creators
}
