# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v0.3.0...v1.0.0) (2020-01-27)


### ⚠ BREAKING CHANGES

* Increased minimum Google provider version to 3.3

### Features

* Upgrade to Project Factory 7.0 ([#9](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/9)) ([b0bb86b](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/b0bb86b666fc7e434f646ef35f7eaba6dc98e2d7))

## [Unreleased]

## [0.3.0] - 2019-12-18

### Fixed
- Fixed [#5] where org admins were not able to access the terraform state bucket when using service account impersonation.

## [0.2.0] - 2019-12-16

### Added

- The `project_labels` and `storage_bucket_labels` variables. [#2]

### Changed

- The storage buckets are changed to enforce Bucket Policy Only access. [#3]
- The Terraform service account receives Security Admin by default. [#4]

## [0.1.0] - 2019-11-21

### Added

- Initial release. [#1]

[Unreleased]: https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/terraform-google-modules/terraform-google-bootstrap/releases/tag/v0.1.0
[#5]: https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/5
[#4]: https://github.com/terraform-google-modules/terraform-google-bootstrap/pull/4
[#3]: https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/3
[#2]: https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/2
[#1]: https://github.com/terraform-google-modules/terraform-google-bootstrap/pull/1
