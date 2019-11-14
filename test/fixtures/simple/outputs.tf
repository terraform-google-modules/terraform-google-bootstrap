/**
 * Copyright 2018 Google LLC
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

output "seed_project_id" {
  value = module.example.seed_project_id
}

output "terraform_sa_email" {
  value = module.example.terraform_sa_email
}

output "terraform_sa_name" {
  value = module.example.terraform_sa_name
}

output "gcs_bucket_tfstate" {
  value = module.example.gcs_bucket_tfstate
}
