## Overview

The example will create Cloud Build 2nd gen repositories using a Gitlab connection.

## Gitlab Requirements for Cloud Build Connection

When using a Cloud Build repositories (2nd gen) GitLab repository, a Cloud Build connection to your repository provider will be needed.

For more information on this topic refer to the Cloud Build repositories (2nd gen) documentation:
- [Connect to a GitLab host](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-host-gitlab)
- [Connect to a GitLab repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gitlab\_authorizer\_credential | Credential for GitLab authorizer | `string` | n/a | yes |
| gitlab\_read\_authorizer\_credential | Credential for GitLab read authorizer | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| test\_repo\_name | The name of the test repository. | `string` | n/a | yes |
| test\_repo\_url | The HTTPS clone URL of the test repository, ending with .git. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_2nd\_gen\_connection | Cloudbuild connection created. |
| cloudbuild\_2nd\_gen\_repositories | Created repositories. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
