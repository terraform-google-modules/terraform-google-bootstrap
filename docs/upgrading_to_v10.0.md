# Upgrading to v10.0

The v10.0 release of *bootstrap* is a backwards incompatible release.

## Google Cloud Provider Workflow deletion protection

The field `deletion_protection` was added to the [google_workflows_workflow](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workflows_workflow) resource with default value of `true` in Google Cloud Platform Provider v6+.

To maintain the old behavior in the module [Cloud Build Builder](../modules/tf_cloudbuild_builder/README.md), which creates a workflow, set the new variable `workflow_deletion_protection` to `false`.


```diff
module "tf_cloudbuild_builder" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_builder"
- version = "~> 9.0"
+ version = "~> 10.0"

+ workflow_deletion_protection = false
```
