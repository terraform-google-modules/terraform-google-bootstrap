#!/bin/bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# GitLab Installation
apt-get update
apt-get install -y curl openssh-server ca-certificates tzdata perl jq
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | bash
apt-get install gitlab-ee=17.11.2-ee.0


# Retrieve values from Metadata Server
EXTERNAL_IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")
PROJECT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
URL="https://$EXTERNAL_IP.nip.io"

openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes \
-subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=gitlab.example.com" \
-addext "subjectAltName=DNS:gitlab.example.com, IP:$EXTERNAL_IP, DNS:$EXTERNAL_IP.nip.io"

mv key.pem gitlab.key
mv cert.pem gitlab.crt

mkdir -p /etc/gitlab/ssl
cp gitlab.* /etc/gitlab/ssl
gcloud storage cp gitlab.crt gs://"${PROJECT_ID}"-ssl-cert

cat > /etc/gitlab/gitlab.rb <<EOF
external_url "https://gitlab.example.com"
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.key"
letsencrypt['enable'] = false
EOF

gitlab-ctl reconfigure

# cp gitlab.crt /usr/local/share/ca-certificates/gitlab.pem
# update-ca-certificates
# ls -l /etc/ssl/certs | grep gitlab
# curl external_ip

MAX_TRIES=50
# Wait for the server to handle authentication requests
for (( i=1; i<=MAX_TRIES; i++)); do
  RESPONSE_BODY=$(curl --cacert /etc/gitlab/ssl/gitlab.crt "$URL")

  if echo "$RESPONSE_BODY" | grep -q "You are .*redirected"; then
      personal_token=$(tr -dc "[:alnum:]" < /dev/random | head -c 20)
      gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: ['api', 'read_api', 'read_user'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('$personal_token'); token.save!"
      echo "personal_token=$(echo "$personal_token" | head -c 3)*********"
      if gcloud secrets describe gitlab-pat-from-vm --project="$PROJECT_ID"; then
        echo "Secret already exists. Will create new secret version for existing 'gitlab-pat-from-vm'."
        echo -n "$personal_token" | gcloud secrets versions add gitlab-pat-from-vm --project="$PROJECT_ID" --data-file=-
      else
        echo "Secret does not already exists. Will create secret 'gitlab-pat-from-vm'."
        echo -n "$personal_token" | gcloud secrets create gitlab-pat-from-vm --project="$PROJECT_ID" --data-file=-
      fi
      break
  else
      echo "$i: GitLab is not ready for sign-in operations. Waiting 10 seconds and will try again."
      echo "Command Output:"
      echo "$RESPONSE_BODY"
      sleep 10
  fi

  # Stop execution upon reaching MAX_TRIES iterations
  if [ "$i" -eq $MAX_TRIES ]; then
        echo "ERROR: Reached limit of $MAX_TRIES tries"
        exit 1
  fi
done


# Fail if certificate is not present
gcloud storage cp /etc/gitlab/ssl/gitlab.crt gs://"${PROJECT_ID}"-ssl-cert
gcloud storage cp gs://"${PROJECT_ID}"-ssl-cert/gitlab.crt /tmp/gitlab.crt || (echo "ERROR: Certificate is not available in bucket" && exit 1)

# Fail if secret is not present
if gcloud secrets describe gitlab-pat-from-vm --project="$PROJECT_ID"; then
  echo "Secret exists" && exit 0
else
  echo "Secret does not exist, will try waiting for propagation time."
  sleep 45
  # Exit with success if the secret exists after the wait time.
  (gcloud secrets describe gitlab-pat-from-vm --project="$PROJECT_ID" && echo "Secret now exists" && exit 0) || exit 1
fi
