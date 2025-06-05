#!/usr/bin/env bash
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


set -ex

if [ "$#" -lt 3 ]; then
    >&2 echo "Not all expected arguments set."
    exit 1
fi

GITLAB_TOKEN=$1
REPO_URL=$2
DOCKERFILE_PATH=$3

# extract portion after https:// from URL
IFS="/"; mapfile -t -d / URL_PARTS < <(printf "%s" "$REPO_URL")
# construct the new authenticated URL
AUTH_REPO_URL="https://gitlab-bot:${GITLAB_TOKEN}@gitlab.com/${URL_PARTS[3]}/${URL_PARTS[4]}"

# create temp dir, cleanup at exit
tmp_dir=$(mktemp -d)
# # shellcheck disable=SC2064
# trap "rm -rf $tmp_dir" EXIT
git clone "${AUTH_REPO_URL}" "${tmp_dir}"
cp "${DOCKERFILE_PATH}" "${tmp_dir}"
pushd "${tmp_dir}"
git config credential.helper gcloud.sh
git config init.defaultBranch main
git config user.email "terraform-robot@example.com"
git config user.name "TF Robot"
git checkout main || git checkout -b main
git add Dockerfile

# The '-z' flag checks if the following string is empty.
if [ -z "$(git status --porcelain)" ]; then
    # If the output is empty, the working directory is clean.
    echo "No changes to commit. Nothing to do."
else
  # If there is output, changes exist, so we commit.
    echo "Changes detected. Attempting to commit..."
  git commit -m "init tf dockerfile"
  git push origin main -f
fi
