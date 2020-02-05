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
  "serviceusage.googleapis.com",
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

cloudbuild_project_admin_roles = ["roles/cloudbuild.builds.editor", "roles/viewer", "roles/source.admin"]

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

  cloudbuild_project_admin_roles.each do |role|
    describe google_project_iam_binding(project: attribute("cloudbuild_project_id"),  role: role) do
      it { should exist }
      its('members') {should include 'group:' + attribute("group_org_admins")}
    end
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

  google_projects.where(project_id: attribute("cloudbuild_project_id")).project_numbers.each do |project_number|
    describe google_storage_bucket_iam_binding(bucket: attribute("gcs_bucket_tfstate"),  role: 'roles/storage.admin') do
      it { should exist }
      its('members') {should include 'group:' + attribute("group_org_admins")}
      its('members') {should include 'serviceAccount:' + attribute("terraform_sa_email")}
      its('members') {should include 'serviceAccount:' + project_number.to_s + '@cloudbuild.gserviceaccount.com'}
    end

    describe google_kms_crypto_key_iam_binding(crypto_key_url: attribute("kms_crypto_key")['self_link'],  role: "roles/cloudkms.cryptoKeyDecrypter") do
      it { should exist }
      its('members') {should include 'serviceAccount:' + attribute("terraform_sa_email")}
      its('members') {should include 'serviceAccount:' + project_number.to_s + '@cloudbuild.gserviceaccount.com'}
    end
  end

  describe google_kms_crypto_key_iam_binding(crypto_key_url: attribute("kms_crypto_key")['self_link'],  role: "roles/cloudkms.cryptoKeyEncrypter") do
    it { should exist }
    its('members') {should include 'group:' + attribute("group_org_admins")}
  end

end
