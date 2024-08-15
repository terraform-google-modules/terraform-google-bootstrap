# Upgrading to v9.0

The v9.0 release of *bootstrap* is a backwards incompatible release.

Some variables default values were removed to align with the restriction that Cloud Build Repositories (2nd Gen) cannot be created in multi-regions or in the `global` region.

You need to update your configurations if you used the default values to prevent resources to be recreated.

## Default value for variable `trigger_location` in module `tf_cloudbuild_workspace` was removed

To preserve the resources created before. include the input `trigger_location` with the previous default value in the module call

```diff
module "tf_workspace" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_workspace"
- version = "~> 8.0"
+ version = "~> 9.0"

+ trigger_location = "global"
```

## Default value for variables `trigger_location` and `gar_repo_location` in module `tf_cloudbuild_builde` were removed

To preserve the resources created before, include the inputs `trigger_location` and `gar_repo_location` with the previous default values in the module call

```diff
module "cloudbuilder" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_builder"
- version = "~> 8.0"
+ version = "~> 9.0"

+ trigger_location  = "global"
+ gar_repo_location = "us"
```

An apply after adding the two inputs will still have an *in-place update* in the `google_workflows_workflow` created by the module.

The endpoint that is used to trigger a build was replaced with a new one that allows a location to be provided.

```
 # module.cloudbuilder.google_workflows_workflow.builder will be updated in-place
```
