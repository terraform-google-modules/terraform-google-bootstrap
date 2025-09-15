# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [11.0.1](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v11.0.0...v11.0.1) (2025-08-22)


### Bug Fixes

* add depends_on for cloudbuild_project module on cloudbuild_bucket module ([#356](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/356)) ([f14e5eb](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f14e5ebde6ab2d34cddf1535c91217fcf65a7410))
* Use existing repo for IM Cloud Build GitHub module ([#364](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/364)) ([1864e6d](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/1864e6d6cd62be99cd74227b2afaeefe70c156fd))

## [11.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v10.0.0...v11.0.0) (2025-01-10)


### ⚠ BREAKING CHANGES

* **deps:** Update Terraform terraform-google-modules/project-factory/google to v18 ([#344](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/344))
* **deps:** Update Terraform terraform-google-modules/org-policy/google to v6 ([#345](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/345))
* **TF>=1.3:** bump terraform ([#333](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/333))
* **deps:** Update Terraform terraform-google-modules/cloud-storage/google to v9 ([#339](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/339))

### Bug Fixes

* bump default gcloud version ([#337](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/337)) ([c2acf0f](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c2acf0fa5ab10b6730daf21a6ee577254dfe68ef))
* **deps:** Update Terraform terraform-google-modules/cloud-storage/google to v9 ([#339](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/339)) ([798aed3](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/798aed32e5a0e60395afce1eb5e0542d2eed90e0))
* **deps:** Update Terraform terraform-google-modules/org-policy/google to v6 ([#345](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/345)) ([a846e97](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/a846e97d347ed88c43102d6d00187c1a0dea0c7a))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v18 ([#344](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/344)) ([faded1f](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/faded1f8f02a39da5c95f0204a204e5173790701))
* remove optional project id from gitlab secret accessor permission assignment ([#335](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/335)) ([c1799d3](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c1799d3733b4d216e7e104afa8e3ba6790272db1))
* **TF>=1.3:** bump terraform ([#333](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/333)) ([f70a38b](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f70a38b07015094a6dcf4a75a37f3138a1ba9b37))

## [10.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v9.0.0...v10.0.0) (2024-12-05)


### ⚠ BREAKING CHANGES

* add workflow deletion protection to cloud build builder module ([#329](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/329))

### Features

* add support for custom host in gitlab ([#328](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/328)) ([62eb9ae](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/62eb9aefb17c4896e766075c05bba6a67db72cf3))
* add workflow deletion protection to cloud build builder module ([#329](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/329)) ([9678d8c](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/9678d8c3f8a30f40611e03bf563cc66e9751334f))

## [9.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v8.0.0...v9.0.0) (2024-11-01)


### ⚠ BREAKING CHANGES

* **deps:** Update Terraform Google Provider to v6 ([#320](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/320))
* **modules:** enable cloudbuildv2 repository support on tf_cloudbuild_builder and tf_cloudbuild_workspace ([#299](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/299))

### Features

* **deps:** Update Terraform Google Provider to v6 ([#320](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/320)) ([b4ae113](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/b4ae113473592272e3acbb753cc16f45e250cf30))
* **deps:** Update Terraform Google Provider to v6 (major) ([#314](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/314)) ([cbb731d](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/cbb731d182607161813bd8ee0a47bc1351e2f6b0))
* **module:** add cloudbuild connection module ([#312](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/312)) ([f79bbc5](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f79bbc53f0593882e552ee0e1ca4019a4db88ac7))
* **modules:** enable cloudbuildv2 repository support on tf_cloudbuild_builder and tf_cloudbuild_workspace ([#299](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/299)) ([62f5f7d](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/62f5f7d28596b74ceac9a55179f6ee29dbcab740))


### Bug Fixes

* Added new force_destroy variable to cloudbuild module. ([#304](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/304)) ([1cdce21](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/1cdce217a98c64001348ff87bc59cfc65e7bac28))
* Do not create secret versions when using Cloud Build repositores second gen ([#324](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/324)) ([a6072e0](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/a6072e0db92d976f1535dab767ad6b4331bcb4ef))
* Include cloudkms.googleapis.com API to activate when encrypt_gcs_bucket_tfstate set to true ([#302](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/302)) ([1121fa2](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/1121fa28b63673c993aee2a53e9199a440e4eefa))

## [8.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v7.2.0...v8.0.0) (2024-05-20)


### ⚠ BREAKING CHANGES

* **deps:** Update Terraform terraform-google-modules/project-factory/google to v15 ([#290](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/290))
* **deps:** Update Terraform terraform-google-modules/cloud-storage/google to v6 ([#291](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/291))

### Features

* Set project field on secret IAM member ([#287](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/287)) ([0efe030](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/0efe03022c7893614ead441e29f513880bac6337))


### Bug Fixes

* **deps:** Update Terraform terraform-google-modules/cloud-storage/google to v6 ([#291](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/291)) ([3854ea6](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/3854ea6d98fa93184d80c650ba9ca6b04ad43297))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v15 ([#290](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/290)) ([eeffa37](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/eeffa37122b00c25670ca68b438e9c1f4bc712e8))
* enable create_ignore for service accounts ([#292](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/292)) ([7c8477b](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/7c8477bd6137745176d27a4e092c997b0da64149))

## [7.2.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v7.1.0...v7.2.0) (2024-04-01)


### Features

* Add GitLab support for IM module ([#281](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/281)) ([a9858a9](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/a9858a9dca91268bc691614dbde75316f0573e0f))
* Add tf_version variable for Infra Manager module ([#279](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/279)) ([f176e92](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f176e929b4898626cd0f3ef0d5ce35b16bed1c54))
* Add the ".git" suffix to the repo URL if missing ([#282](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/282)) ([c4e0098](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c4e0098a7e478082befd806509a6e27494767bc0))


### Bug Fixes

* Update check existing deployments command ([#275](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/275)) ([8623af7](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/8623af7aa82c156a6c17fbf908362efe7dc47e58))

## [7.1.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v7.0.0...v7.1.0) (2024-03-12)


### Features

* Infrastructure Manager workspace blueprint ([#271](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/271)) ([61ec4eb](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/61ec4eb0f40526bc62f3d8e06eafc2c8185bf454))

## [7.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.5.0...v7.0.0) (2024-01-13)


### ⚠ BREAKING CHANGES

* **deps:** Update TF modules (major) ([#241](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/241))

### Bug Fixes

* bump impersonate_propagation to 60s ([#253](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/253)) ([3360ef2](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/3360ef2c58c4d23b9fe2b53f626d748466ce2719))
* **deps:** Update TF modules (major) ([#241](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/241)) ([6f2e3a0](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/6f2e3a01663abe8fbc90d09b50e4740603c13ac8))

## [6.5.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.4.1...v6.5.0) (2024-01-03)


### Features

* add timeout variable for cloudbuild builder ([#256](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/256)) ([380d48f](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/380d48f35d26ea4e63693d8002226c94dff9c92c))

## [6.4.1](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.4.0...v6.4.1) (2023-10-31)


### Bug Fixes

* upgraded versions.tf to include minor bumps from tpg v5 ([#245](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/245)) ([59c5e97](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/59c5e979543c6ff479340aadd0d27a8b1c7e0ccb))

## [6.4.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.3.0...v6.4.0) (2022-12-09)


### Features

* Add custom bucket names support for modules `tf_cloudbuild_workspace` and `tf_cloudbuild_builder` ([#212](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/212)) ([c537031](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c537031865012bcf6eda6a2d9a6bbc3f3cca638a))
* add custom name for cloud build service account and state bucket ([#214](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/214)) ([f1d0014](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f1d0014cfc7d2909475907f7b391b4378c7eb152))


### Bug Fixes

* updates to address tflint and CFT 1.10 ([#203](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/203)) ([7c7a874](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/7c7a8749e2667d05514bfef70023ab541747bdd5))

## [6.3.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.2.0...v6.3.0) (2022-11-08)


### Features

* add support for `included_files` and `ignored_files` of `google_cloudbuild_trigger` ([#207](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/207)) ([d2e5a75](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/d2e5a7519e0374a82fd5ab2489de4d94e772c392))
* add support for optional private worker pool usage ([#201](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/201)) ([d1035ed](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/d1035ed7635917c197032917d361b10880cea4c0))
* create variable for providing the trigger location ([#206](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/206)) ([54ca307](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/54ca30787eb8cd599ea6de1a586c19db13f55968))
* creation of the Terraform service account should be optional ([#209](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/209)) ([9bb2800](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/9bb280044f1430cb3f042b05906736f0b9754a05))

## [6.2.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.1.0...v6.2.0) (2022-08-19)


### Features

* allow configuration of initial terraform version in tf_cloudbuild_builder ([#189](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/189)) ([4f38396](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/4f3839608edf6d8c078e22b41b1a0ae27685b7fd))


### Bug Fixes

* add terraform-tools to the docker images ([#186](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/186)) ([c2d7b3f](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c2d7b3ff2b878d9555338b465021db0c2c651d50))

## [6.1.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v6.0.0...v6.1.0) (2022-07-15)


### Features

* add artifacts bucket to tf workspace module ([#170](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/170)) ([fceee53](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/fceee53b9128db532f11290650e7cc94f04f4ea4))
* CloudBuild workspace blueprint ([#162](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/162)) ([bcbbed2](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/bcbbed2ae09ded98e25d0462dfc920cfbb0f121c))
* create Cloudbuild Source submodule ([#167](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/167)) ([2dc083f](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/2dc083f0f9e2d2c4442e93b022d6787f6007b049))


### Bug Fixes

* wait on IAM to return terraform_sa_email ([#166](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/166)) ([45830b7](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/45830b70a194e7f2169fd10ae7859bf97e786d20))

## [6.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v5.1.0...v6.0.0) (2022-06-23)


### ⚠ BREAKING CHANGES

* Update Dockerfile to install terraform-validator from gcloud (#156)
* Use user defined SA for cb triggers (#148)

### Features

* Update Dockerfile to install terraform-validator from gcloud ([#156](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/156)) ([a300b9c](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/a300b9c27796200f2a565173484eb997d8e296a8))
* Use user defined SA for cb triggers ([#148](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/148)) ([5a925f8](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/5a925f8d3c742b9846e71743197fbbd22550bb7a))

## [5.1.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v5.0.1...v5.1.0) (2022-05-27)


### Features

* add TF cloudbuilder blueprint ([#154](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/154)) ([34120e5](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/34120e579528dfb72dddace0485d38efaf9202bd))
* Allow service account impersonation in the local-exec gcloud runs. ([#151](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/151)) ([6a7463b](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/6a7463b12cd140905fd5a60fc0d030359b94607a))

### [5.0.1](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v5.0.0...v5.0.1) (2022-03-09)


### Bug Fixes

* Guarantee the execution permission in the entrypoint.bash file ([#149](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/149)) ([f113076](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/f113076264b71e0423c2bcd642eb63851311e604))

## [5.0.0](https://github.com/terraform-google-modules/terraform-google-bootstrap/compare/v4.2.0...v5.0.0) (2022-01-13)


### ⚠ BREAKING CHANGES

* remove KMS resources in cloudbuild submodule (#143)
* Drop old TFV version (< `v0.6.0`)  support (#141)

### Features

* Drop old TFV version (< `v0.6.0`)  support ([#141](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/141)) ([2b9bf2c](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/2b9bf2cdfa99ef098b4816a941733d34b023e45b))
* remove KMS resources in cloudbuild submodule ([#143](https://github.com/terraform-google-modules/terraform-google-bootstrap/issues/143)) ([c1a52c7](https://github.com/terraform-google-modules/terraform-google-bootstrap/commit/c1a52c798d8d307681c02a3ac96222ee761ff735))

## [4.2.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v4.1.0...v4.2.0) (2021-12-13)


### Features

* update TPG version constraints to allow 4.0 ([#133](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/133)) ([71aa344](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/71aa344c657e1348cdca22900fc87e24820f2b6f))

## [4.1.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v4.0.0...v4.1.0) (2021-11-22)


### Features

* Add a lien for the seed project ([#136](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/136)) ([3853dc4](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/3853dc46cc75146424595babea631080820a69a6))


### Bug Fixes

* Remove incompatible escape characters with Windows systems (CMD and PowerShell) to make the command fits in one line ([#131](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/131)) ([56dec3e](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/56dec3e4e0496b01231e8e37c60e43b17dddaff0))

## [4.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v3.1.0...v4.0.0) (2021-10-15)


### ⚠ BREAKING CHANGES

* hardcode create_project_sa to false (#126)

### Features

* added capability to toggle creation of seed project service account ([#124](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/124)) ([0457e66](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/0457e668b7231690c748d91a0107233081da991c))
* hardcode create_project_sa to false ([#126](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/126)) ([c1ee35e](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/c1ee35e0615d5da91ddc0fb10eba3235dd53eb46))


### Bug Fixes

* add explicit dependency for GCS service account ([#128](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/128)) ([62adacc](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/62adacc8ed8ad92e8ec3197ed05291fbaf8cbb07))

## [3.1.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v3.0.0...v3.1.0) (2021-09-02)


### Features

* Add KMS cmek support for state bucket ([#115](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/115)) ([2fea4be](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/2fea4be30af10b9f5880b0a29c02bf27ed00e6e3))
* Add variables to allow customisation of terraform service account ([#116](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/issues/116)) ([b7b0090](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/commit/b7b0090d61ad578c395dc35c9b25967ab8b341f2))

## [3.0.0](https://www.github.com/terraform-google-modules/terraform-google-bootstrap/compare/v2.3.1...v3.0.0) (2021-07-28)


### ⚠ BREAKING CHANGES

* Default trigger location in Terraform state changed, see upgrade guide for details.
* Default branch trigger changed from `master` to `main`.
* Default Terraform version changed to v1.0.2.

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
