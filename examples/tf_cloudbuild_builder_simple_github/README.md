## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_builder](../../modules/tf_cloudbuild_builder/) module with a Repositories V2 GitHub repo.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudbuildv2\_repository\_id | Cloudbuild 2nd gen repository ID. Format: 'projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}'. Must be defined if repository type is `CLOUDBUILD_V2_REPOSITORY`. | `string` | n/a | yes |
| github\_pat | GitHub personal access token. | `string` | n/a | yes |
| project\_id | n/a | `string` | `"test-builder-workflow-4"` | no |
| repository\_uri | The URI of the repo where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_repo | GAR Repo created to store TF Cloud Builder images |
| cloudbuild\_trigger\_id | Trigger used for building new TF Builder |
| project\_id | n/a |
| scheduler\_id | Scheduler ID for periodically triggering TF Builder build Workflow |
| workflow\_id | Workflow ID for triggering new TF Builder build |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
