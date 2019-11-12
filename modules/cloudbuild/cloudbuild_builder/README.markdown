# [Terraform](https://www.terraform.io/docs) cloud builder

## Terraform cloud builder
This builder can be used to run the terraform tool in the GCE. From the Hashicorp Terraform [product page](https://www.terraform.io/):

> HashiCorp Terraform enables you to safely and predictably create, change, and improve infrastructure. It is an open source
> tool that codifies APIs into declarative configuration files that can be shared amongst team members, treated as code,
> edited, reviewed, and versioned.

### Building this builder
To build this builder, run the following command in this directory.
```sh
$ gcloud builds submit --config=cloudbuild.yaml
```
