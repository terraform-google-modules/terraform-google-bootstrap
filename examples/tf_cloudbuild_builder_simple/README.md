## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_builder](../../modules/tf_cloudbuild_builder/) module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | `"test-builder-workflow-4"` | no |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_repo | GAR Repo created to store TF Cloud Builder images |
| cloudbuild\_trigger\_id | Trigger used for building new TF Builder |
| csr\_repo\_url | CSR repo for storing cloudbuilder Dockerfile |
| project\_id | n/a |
| scheduler\_id | Scheduler ID for periodically triggering TF Builder build Workflow |
| workflow\_id | Workflow ID for triggering new TF Builder build |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
