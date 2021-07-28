# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.3.1...v3.0.0) (2021-07-28)


### ⚠ BREAKING CHANGES

* Default trigger location in Terraform state changed, see upgrade guide for details.

### Features

* Upgrade default Terraform version to v1.0.2 ([#112](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/112)) ([dac0483](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/dac0483368abd0e78a6f680aa949e860d9bb8e70))

### [2.3.1](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.3.0...v2.3.1) (2021-05-05)


### Bug Fixes

* Leave curl and unzip in Docker image ([#106](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/106)) ([8d24f65](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/8d24f6583b16e6bd97e3e7d2b809d689371796d1))

## [2.3.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.2.1...v2.3.0) (2021-04-08)


### Features

* add ability to specify random suffix for projects and GCS ([#102](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/102)) ([da4e8c1](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/da4e8c10a2b03f2a67d6217dba67ba7be5c83503))
* add force_destroy option for state bucket ([#100](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/100)) ([50ce28f](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/50ce28f411eed79868f968c6fff9afa7eddc226a))


### Bug Fixes

* Update version of terraform-validator to 2021-03-22 ([#103](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/103)) ([fb2f372](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/fb2f37278384adb020bf0606acd8afa3c8bb04f5))

### [2.2.1](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.2.0...v2.2.1) (2021-02-25)


### Bug Fixes

* expose GAR repo name via substitutions in triggers ([#97](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/97)) ([9ac97a3](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/9ac97a3393ebfbfd5425fec7ff5cb63bdc1c2cae))

## [2.2.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.1.0...v2.2.0) (2021-02-23)


### Features

* migrate to GAR for runner images ([#94](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/94)) ([02bf581](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/02bf5813de4f0702835e768bc70aac7f16e79730))


### Bug Fixes

* upgrade project factory to 10.1.1 and terraform to 0.13.6 ([#93](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/93)) ([e04ab65](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/e04ab658516e8c7bda4689589d5ef8f01ba6ed88))

## [2.1.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.0.0...v2.1.0) (2021-01-15)


### Features

* Add ability to customize state bucket name ([#86](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/86)) ([1af1405](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/1af1405be6455ff4a212e5977989bc597edb4067))


### Bug Fixes

* Remove incorrect substitution for seed project ([#84](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/84)) ([4ec9fa0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/4ec9fa083066712bcea317bcf9066646e07a66c6))

## [2.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.7.0...v2.0.0) (2021-01-12)


### ⚠ BREAKING CHANGES

* Upgrade google-project-factory to v10, add Terraform 0.13 constraint and module attribution (#81)

### Features

* Upgrade google-project-factory to v10, add Terraform 0.13 constraint and module attribution ([#81](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/81)) ([4d00da3](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/4d00da341d22975137b6eacd910b61fce714938b))

## [1.7.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.6.0...v1.7.0) (2020-11-05)


### Features

* custom seed project id ([#74](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/74)) ([4d44c4b](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/4d44c4ba57638f7aca081a3a3bcc2685437f17f4))

## [1.6.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.5.0...v1.6.0) (2020-10-26)


### Features

* update terraform to 12.29 and terraform-validator to 2020-09-24 ([#71](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/71)) ([74d7ef2](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/74d7ef257b9f7a076e878ec9ed56dabbf006d78f))

## [1.5.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.4.0...v1.5.0) (2020-10-26)


### Features

* allow Cloud Source Repos to be optional ([#68](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/68)) ([6df33bc](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/6df33bc50b5d25176b01b722761c941c10baeaef))
* relax tf version to allow terraform 0.13 ([#67](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/67)) ([af34b11](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/af34b11889e49fb3c50932ba7e14c33f3291eefe))

## [1.4.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.3.4...v1.4.0) (2020-10-14)


### Features

* Replaces deprecated bucket_policy_only for uniform_bucket_level_access ([#63](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/63)) ([a1ef992](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/a1ef9924a325331539bdb9eedbb8007d0b35be80))

### [1.3.4](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.3.3...v1.3.4) (2020-09-17)


### Bug Fixes

* min version in docs to 0.12.20 ([#61](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/61)) ([0c53fe2](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/0c53fe2a438cec4aa1d5561ec2497ab9ac68eebe))
* Required provider version upgraded to 0.12.20. ([#59](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/59)) ([b1fd7e8](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/b1fd7e8d5b3d69f460477d4b417102f40f83352f))

### [1.3.3](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.3.2...v1.3.3) (2020-08-06)


### Bug Fixes

* cloud build trigger regex to only match the correct branches ([#53](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/53)) ([f555239](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/f555239de6ff9aa12f6813c9256127c07c1a2898))
* update the example module version ([#50](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/50)) ([b933b9b](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/b933b9b883fbf61eb354f9e8679b54c7cb40e560))

### [1.3.2](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.3.1...v1.3.2) (2020-07-27)


### Bug Fixes

* make trigger names generic now that multiple branches are supported ([#48](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/48)) ([dc3c0c3](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/dc3c0c3eb363d936445cdef4e11fc5ec5de7347e))

### [1.3.1](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.3.0...v1.3.1) (2020-07-23)


### Bug Fixes

* downgrade minimum provider version for better compatibility with existing usage of module ([#46](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/46)) ([2aec7c8](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/2aec7c842ca4990385077d5653ce9a9dddbda28b))

## [1.3.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.2.0...v1.3.0) (2020-07-22)


### Features

* Add support for terraform validator ([#44](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/44)) ([d09725f](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/d09725f48054b2d0c08001b3650be7413d610c38))

## [1.2.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.1.0...v1.2.0) (2020-07-06)


### Features

* Add ability to define custom list of branches to trigger apply and custom cloudbuild YAML for terraform builds ([#41](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/41)) ([02467c8](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/02467c860b68cfab4e65241cae4406feb95a5674))
* Add skip_gcloud_download flag ([#39](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/39)) ([0e06b29](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/0e06b299a22c454cc0406c34de59fde150d33095))
* option to target bootstrap module at a folder ([#40](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/40)) ([fa923a5](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/fa923a5242146837ca9d5001390f9200ccc40a7f))

## [1.1.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v1.0.0...v1.1.0) (2020-04-16)

### Features

* Add serviceusage api to the defaults (#13)
* Make sure group_org_admins has projectCreator permission. (#15)
* Add folder mover permission by default
* Add ability to customize / upgrade terraform version (#17)

## [1.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v0.3.0...v1.0.0) (2020-01-27)


### ⚠ BREAKING CHANGES

* Increased minimum Google provider version to 3.3

### Features

* Upgrade to Project Factory 7.0 ([#9](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/9)) ([b0bb86b](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/b0bb86b666fc7e434f646ef35f7eaba6dc98e2d7))

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
