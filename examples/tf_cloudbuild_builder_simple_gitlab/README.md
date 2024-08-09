## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_builder](../../modules/tf_cloudbuild_builder/) module with a Cloud Build repositories (2nd gen) GitLab repository.

For more information on this topic refer to the Cloud Build repositories (2nd gen) documentation:
- [Connect to a GitLab host](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-host-gitlab)
- [Connect to a GitLab repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gitlab\_api\_access\_token | GitLab personal access token with api scope. If provided, creates a secret within Secret Manager. | `string` | n/a | yes |
| gitlab\_read\_api\_access\_token | GitLab personal access token with read\_api scope. If provided, creates a secret within Secret Manager. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the GitLab repository where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_repo | GAR Repo created to store TF Cloud Builder images |
| cloudbuild\_trigger\_id | Trigger used for building new TF Builder |
| location | The location in which the resources were provisioned |
| project\_id | The ID of the project in which the resources were provisioned |
| repository\_id | ID of the Cloud Build repositories (2nd gen) repository |
| scheduler\_id | Scheduler ID for periodically triggering TF Builder build Workflow |
| workflow\_id | Workflow ID for triggering new TF Builder build |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
