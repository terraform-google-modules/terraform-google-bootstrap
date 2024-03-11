## Overview

This example demonstrates the simplest usage of the [im_cloudbuild_workspace](../../modules/im_cloudbuild_workspace/) module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| im\_github\_pat | GitHub personal access token. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_apply\_trigger\_id | Trigger used for running IM apply |
| cloudbuild\_preview\_trigger\_id | Trigger used for creating IM previews |
| cloudbuild\_sa | Service account used by the Cloud Build triggers |
| infra\_manager\_sa | Service account used by Infrastructure Manager |
| location | Location for Infrastructure Manager deployment. |
| project\_id | n/a |
| repo\_url | The URI of the repo where the Terraform configs are stored and triggers are created for |
| trigger\_location | Location of for Cloud Build triggers created in the workspace. Matches `location` if not given. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
