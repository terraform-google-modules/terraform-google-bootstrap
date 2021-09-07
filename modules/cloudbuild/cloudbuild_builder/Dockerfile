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

FROM gcr.io/cloud-builders/gcloud-slim

# Use ARG so that values can be overriden by user/cloudbuild
ARG TERRAFORM_VERSION=0.13.6
ARG TERRAFORM_VERSION_SHA256SUM=55f2db00b05675026be9c898bdd3e8230ff0c5c78dd12d743ca38032092abfc9
ARG TERRAFORM_VALIDATOR_RELEASE=2021-03-22

ENV ENV_TERRAFORM_VERSION=$TERRAFORM_VERSION
ENV ENV_TERRAFORM_VERSION_SHA256SUM=$TERRAFORM_VERSION_SHA256SUM
ENV ENV_TERRAFORM_VALIDATOR_RELEASE=$TERRAFORM_VALIDATOR_RELEASE

RUN apt-get update && \
   /builder/google-cloud-sdk/bin/gcloud -q components install alpha beta && \
    apt-get -y install curl jq unzip git ca-certificates && \
    curl https://releases.hashicorp.com/terraform/${ENV_TERRAFORM_VERSION}/terraform_${ENV_TERRAFORM_VERSION}_linux_amd64.zip \
      > terraform_linux_amd64.zip && \
    echo "${ENV_TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS && \
    sha256sum -c terraform_SHA256SUMS --status && \
    unzip terraform_linux_amd64.zip -d /builder/terraform && \
    rm -f terraform_linux_amd64.zip && \
    VALIDATOR_RELEASE_VERSION=$(echo $ENV_TERRAFORM_VALIDATOR_RELEASE | sed -e 's/^v//') && \
    VALIDATOR_RELEASE_NUMBER_AS_INT=$(echo $VALIDATOR_RELEASE_VERSION | sed -e 's/\.//g;s/^0//') && \
    TARBALL_VERSION_THRESHOLD_AS_INT="60" && \
    GCS_BASE_PATH="gs://terraform-validator/releases/${ENV_TERRAFORM_VALIDATOR_RELEASE}" && \
    LEGACY_GCS_PATH="${GCS_BASE_PATH}/terraform-validator-linux-amd64" && \
    CURRENT_GCS_PATH="${GCS_BASE_PATH}/terraform-validator_linux_amd64-${VALIDATOR_RELEASE_VERSION}.tar.gz" && \
    if ( echo "$ENV_TERRAFORM_VALIDATOR_RELEASE" | grep -v '-' | grep -q '^v' ) && \
    [ "$VALIDATOR_RELEASE_NUMBER_AS_INT" -ge "$TARBALL_VERSION_THRESHOLD_AS_INT" ]; then \
      echo "Terraform Validator recent version >= v0.6.0 : zipped tarball"; gsutil cat ${CURRENT_GCS_PATH} | tar zxv -C /builder/terraform; \
    else \
      echo "Terraform Validator legacy version < v0.6.0"; gsutil cp ${LEGACY_GCS_PATH} /builder/terraform/terraform-validator; \
    fi && \
    chmod +x /builder/terraform/terraform-validator && \
    apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/builder/terraform/:$PATH
COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
