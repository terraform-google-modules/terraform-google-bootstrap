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

control "gcp" do
  title "GCP Resources"

  describe google_project(project_id: attribute("seed_project_id")) do
    it { should exist }
  end

  describe google_storage_bucket(name: attribute("gcs_bucket_tfstate")) do
    it { should exist }
    its('storage_class') { should eq 'STANDARD' }
  end

  describe google_service_account(name: attribute("terraform_sa_name")) do
    it { should exist }
    its('has_user_managed_keys?') {should cmp false }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'servicenetworking.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'compute.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'logging.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'bigquery-json.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'cloudresourcemanager.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'cloudbilling.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'iam.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'admin.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

  describe google_project_service(project: attribute("seed_project_id"), name: 'appengine.googleapis.com') do
    it { should exist }
    its('state') { should cmp "ENABLED" }
  end

end