# Upgrading to v5.0

The v5.0 release of *bootstrap* is a backwards incompatible release.

## Terraform Validator < `v0.6.0` no longer supported

TFV versions older than `v0.6.0` are no longer supported. New default version is `v0.6.0`.

## KMS Resources in CloudBuild sub-module have been removed

[KMS Resources](https://github.com/terraform-google-modules/terraform-google-bootstrap/blob/2b9bf2cdfa99ef098b4816a941733d34b023e45b/modules/cloudbuild/main.tf#L85-L128) in the CloudBuild sub-module have been removed. To preserve these resources, add the resources out of band from the module and [move resource addresses](https://www.terraform.io/cli/commands/state/mv) in the TF state.

For instance, to preserve the `google_kms_key_ring` resource if you have instantiated the module as below:

```tf
module "cloudbuild_bootstrap" {
  source         = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
  version        = "~> 4.0"
  default_region = var.default_region
...
}
```

You can add this resource in your root configuration alongside the new version of the module.

```diff
module "cloudbuild_bootstrap" {
  source         = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
- version       = "~> 4.0"
+ version       = "~> 5.0"
  default_region = var.default_region
...
}

+resource "google_kms_key_ring" "tf_keyring" {
+ project  = module.cloudbuild_bootstrap.cloudbuild_project_id
+ name     = "tf-keyring"
+ location  = var.default_region
}
```

Now you can migrate this resource from the module to the newly added `google_kms_key_ring` config.

```bash
tf state mv module.cloudbuild_bootstrap.google_kms_key_ring.tf_keyring google_kms_key_ring.tf_keyring
```

This will need to be repeated for each resource like `google_kms_crypto_key` and `google_kms_crypto_key_iam_binding`.
