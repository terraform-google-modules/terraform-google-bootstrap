# Copyright 2021 Google LLC
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

control "gcloud" do
    title "GAR Repo"
    describe command("gcloud --project=#{attribute("cloudbuild_project_id")} artifacts repositories describe #{attribute("tf_runner_artifact_repo")} --location=us-central1 --format=json") do
      its(:exit_status) { should eq 0 }
      let!(:data) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout)
        else
          {}
        end
      end
      describe "GAR repo" do
        it "exists" do
          expect(data['name']).to eq "projects/#{attribute("cloudbuild_project_id")}/locations/us-central1/repositories/#{attribute("tf_runner_artifact_repo")}"
        end
      end
    end

    title "GAR Repo TF Runner Image"
    describe command("gcloud --project=#{attribute("cloudbuild_project_id")} artifacts tags list --repository=#{attribute("tf_runner_artifact_repo")} --location=us-central1 --package=terraform --format=json") do
      its(:exit_status) { should eq 0 }
      let!(:data) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout)
        else
          {}
        end
      end
      describe "TF runner image" do
        it "exists" do
          expect(data[0]['name']).to eq "projects/#{attribute("cloudbuild_project_id")}/locations/us-central1/repositories/#{attribute("tf_runner_artifact_repo")}/packages/terraform/tags/latest"
        end
      end
    end

    title "Terraform SA in Trigger"
    describe command("gcloud beta --project=#{attribute("cloudbuild_project_id")} builds triggers list --format=json") do
      its(:exit_status) { should eq 0 }
      let!(:data) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout)
        else
          {}
        end
      end
      describe "Terraform SA" do
        it "exists" do
          expect(data[0]['serviceAccount']).to include "#{attribute("terraform_sa_email")}"
        end
        it "exists" do
          expect(data[1]['serviceAccount']).to include "#{attribute("terraform_sa_email")}"
        end
      end
    end
  end
