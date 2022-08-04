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

terraform {
  required_version = ">=0.13.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Exclude 4.31.0 for https://github.com/hashicorp/terraform-provider-google/issues/12226
      version = ">= 3.50, < 5.0, != 4.31.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      # Exclude 4.31.0 for https://github.com/hashicorp/terraform-provider-google/issues/12226
      version = ">= 3.50, < 5.0, != 4.31.0"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-bootstrap:cloudbuild/v6.1.0"
  }
}
