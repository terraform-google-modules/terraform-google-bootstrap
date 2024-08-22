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

output "cloud_build_repositories_2nd_gen_connection" {
  description = <<EOF
  The unique identifier of the Cloud Build connection created within the specified Google Cloud project.
  Example format: projects/{{project}}/locations/{{location}}/connections/{{name}}
  EOF
  value       = google_cloudbuildv2_connection.connection.id
}

output "cloud_build_repositories_2nd_gen_repositories" {
  description = <<-EOF
  A map of created repositories associated with the Cloud Build connection.
  Each entry contains the repository's unique identifier and its remote URL.
  Example format:
  "key_name" = {
    "id" =  "projects/{{project}}/locations/{{location}}/connections/{{parent_connection}}/repositories/{{name}}",
    "url" = "https://github.com/{{account/org}}/{{repository_name}}.git"
  }
  EOF
  value       = { for k, v in google_cloudbuildv2_repository.repositories : k => { "id" : v.id, "url" : v.remote_uri } }
}
