FROM gcr.io/cloud-builders/gcloud-slim

ENV TERRAFORM_VERSION=0.12.13
ENV TERRAFORM_VERSION_SHA256SUM=63f765a3f83987b67b046a9c31acff1ec9ee618990d0eab4db34eca6c0d861ec

RUN apt-get update && \
   /builder/google-cloud-sdk/bin/gcloud -q components install alpha beta && \
    apt-get -y install curl jq unzip ca-certificates && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      > terraform_linux_amd64.zip && \
    echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS && \
    sha256sum -c terraform_SHA256SUMS --status && \
    unzip terraform_linux_amd64.zip -d /builder/terraform && \
    rm -f terraform_linux_amd64.zip && \
    apt-get remove --purge -y curl unzip && \
    apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/builder/terraform/:$PATH
COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
