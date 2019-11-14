# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default_apis = [
  "servicenetworking.googleapis.com",
  "compute.googleapis.com",
  "logging.googleapis.com",
  "bigquery-json.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "cloudbilling.googleapis.com",
  "iam.googleapis.com",
  "admin.googleapis.com",
  "appengine.googleapis.com"
]

cloudbuild_apis = ["cloudbuild.googleapis.com", "sourcerepo.googleapis.com", "cloudkms.googleapis.com"]

control "bootstrap" do
  title "Bootstrap module GCP resources"

  describe google_project(project_id: attribute("seed_project_id")) do
    it { should exist }
  end

  describe google_storage_bucket(name: attribute("gcs_bucket_tfstate")) do
    it { should exist }
  end

  describe google_service_account(name: attribute("terraform_sa_name")) do
    it { should exist }
    its('has_user_managed_keys?') {should cmp false }
  end

  default_apis.each do |api|
    describe google_project_service(project: attribute("seed_project_id"), name: api) do
      it { should exist }
      its('state') { should cmp "ENABLED" }
    end
  end

end

control "cloudbuild" do
  title "Cloudbuild sub-module GCP Resources"

  describe google_project(project_id: attribute("cloudbuild_project_id")) do
    it { should exist }
  end

  describe google_storage_bucket(name: attribute("gcs_bucket_cloudbuild_artifacts")) do
    it { should exist }
  end

  default_apis.each do |api|
    describe google_project_service(project: attribute("cloudbuild_project_id"), name: api) do
      it { should exist }
      its('state') { should cmp "ENABLED" }
    end
  end

  cloudbuild_apis.each do |api|
    describe google_project_service(project: attribute("cloudbuild_project_id"), name: api) do
      it { should exist }
      its('state') { should cmp "ENABLED" }
    end
  end

end