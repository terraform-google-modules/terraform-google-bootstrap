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

module "tf_source" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_source"
  version = "~> 11.0"

  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  group_org_admins        = var.group_org_admins
  buckets_force_destroy   = true
  project_deletion_policy = var.project_deletion_policy
}
