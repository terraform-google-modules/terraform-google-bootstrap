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

## Default value for variables `trigger_location` and `gar_repo_location` in module `tf_cloudbuild_builder` were removed

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

## Google Cloud Provider Project deletion_policy

The `deletion_policy` for [project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) module now defaults to `"PREVENT"` rather than `"DELETE"`.
This aligns with the behavior in Google Cloud Platform Provider v6+.
To maintain the old behavior in the projects created within the modules you can set the new variable `project_deletion_policy = "DELETE"`.

### Bootstrap main module

```diff
module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
- version = "~> 8.0"
+ version = "~> 9.0"

+ project_deletion_policy = "DELETE"
```

### Cloud Build sub module

```diff
module "cloudbuild" {
  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
- version = "~> 8.0"
+ version = "~> 9.0"

+ project_deletion_policy = "DELETE"
```


### Cloud Build Source sub module

```diff
module "tf_cloudbuild_source" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_source"
- version = "~> 8.0"
+ version = "~> 9.0"

+ project_deletion_policy = "DELETE"
```
