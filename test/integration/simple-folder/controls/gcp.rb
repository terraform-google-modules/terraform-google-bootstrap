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
  "bigquery.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "cloudbilling.googleapis.com",
  "iam.googleapis.com",
  "admin.googleapis.com",
  "appengine.googleapis.com",
  "storage-api.googleapis.com"
]

control "bootstrap-folder" do
	title "Bootstrap module GCP resources"

	describe google_project(project: attribute("seed_project_id")) do
		it { should exist }
	end

	describe google_storage_bucket(name: attribute("gcs_bucket_tfstate")) do
		it { should exist }
	end

	describe google_storage_bucket_iam_binding(bucket: attribute("gcs_bucket_tfstate"),  role: 'roles/storage.admin') do
		its('members') {should include 'serviceAccount:' + attribute("terraform_sa_email")}
	end

	describe google_service_account(project: attribute("seed_project_id"), name: attribute("terraform_sa_email")) do
		it { should exist }
	end

	describe google_service_account_keys(project: attribute("seed_project_id"), service_account: attribute("terraform_sa_email")) do
		its('key_types') { should_not include 'USER_MANAGED' }
	end

	default_apis.each do |api|
		describe google_project_service(project: attribute("seed_project_id"), name: api) do
			it { should exist }
			its('state') { should cmp "ENABLED" }
		end
	end

	describe google_resourcemanager_folder_iam_binding(name: attribute("parent_folder"), role: "roles/resourcemanager.projectCreator") do
		it { should exist }
		its('members') { should include "serviceAccount:#{attribute("terraform_sa_email")}" }
	end

	describe google_organization_iam_binding(name: "organizations/#{attribute("org_id")}", role: "roles/resourcemanager.projectCreator") do
		its('members') { should_not include "serviceAccount:#{attribute("terraform_sa_email")}" }
	end

end
