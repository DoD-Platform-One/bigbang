# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [2.4.39]
### Changed
- Increased vault CoreDNS "wait for istio" HR timeout to 15 minutes

## [2.4.38]
### Added
- Added a quick check to validate README was generated with the correct helm-docs version

## [2.4.37]
### Removed
- Removed BigBang up retries from rke2 pipelines for runner errors becuase it caused the pipelines to enter a weird state

## [2.4.36]
### Fixed
- Fixed edge case for vault CoreDNS patch when deployment of passthrough gateway doesn't exist

## [2.4.35]
### Changed
- Tidy up some output, move to DEBUG only for coreDNS patch output

## [2.4.34]
### Added
- Added logic to skip `create_bigbang_merge_request` with `skip-bb-mr` merge request label.

## [2.4.33]
### Added
- Added conditional to `clone_bigbang_and_merge_templates` for setting the correct git branch in a Flux GitRepository resource for the integration stage.
### Changed
- Removed sandbox pipeline rule for integration stage to always run on a Merge Request.

## [2.4.32]
### Fixed
- Fixed conditionals for Vault CoreDNS patching

## [2.4.31]
### Changed
- support for Vault passthrough ingress.
### Added
- Added new deployment script to patch coredns for Vault.

## [2.4.30]
### Changed
- Removed third-party integration pipeline rule to always run on a Merge Request. The topmost rule checking for `bigbang/values.yaml` is sufficient.

## [2.4.29]
### Added
- Added a k3d configuration file for a k3d cluster that disables the default metrics server by default
### Changed
- Changed `METRICS_DISABLED` flag to bigbang, bigbang-package,sandbox, and third-party pipelines
- Changed `deploy_k3d.sh` to evaluate which configuration file to used based on the `METRICS_DISABLED` flag value

## [2.4.28]
### Fixed
- Fixed a bug where auto MR creation would pull the wrong MR

## [2.4.27]
### Fixed
- Fixed a bug where Promtail enabled Loki without enabling its dependencies

## [2.4.26]
### Fixed
- Fixed renovate pipeline, extending templates broke since container isn't run as root.
- No longer downloading helm-docs since it is built into the container.

## [2.4.25]
### Changed
- Move downloading renovate deps into `library/templates.sh` from `pipelines/renovate.yaml`
- Add `renovate-runner/scripts` to PATH before renovate execution, allowing full access to `postUpgradeTasks`
- Move renovate config from pipeline env variables to `renovate-runner/config.js`

## [2.4.24]
### Changed
- Upgrade api version of k3d config file from `k3d.io/v1alpha3` to `k3d.io/v1alpha4`
- Revalidated k3d config file w/ [v4 schema](https://github.com/k3d-io/k3d/blob/main/pkg/config/v1alpha4/schema.json)
- Moved `name` property --> `metadata.name` in k3d config file due to above schema

## [2.4.23]
### Added
- Migrated renovate pipeline from its repo to `pipelines/renovate.yaml`

## [2.4.22]
### Added
- Add removal of previous artifacts on cypress upgrade tests

## [2.4.21]
### Added
- Added `patch` to bb-ci Dockerfile
- Pushed version `2.4.2` of bb-ci container image
- Added `create_bigbang_merge_request` function to templates.sh
- Added variables and the `create_bigbang_merge_request` function to the `auto-tag` stage in the `bigbang-package.yaml` pipeline
### Changed
- Updated the image tag in templates.yaml

## [2.4.20]
### Changed
- Moved rke2 aws transit gateways to bigbang-ci cluster

## [2.4.19]
### Changed
- Changed os_prep data in rke2 terraform to persist ulimit changes.

## [2.4.18]
### Changed
- Changed runner tags to add bbci so that jobs are forced onto the new runners.

## [2.4.17]
### Fixed
- conflict in folder naming for cypress artifacts

## [2.4.16]
### Fixed
- syntax error in templates.sh

## [2.4.15]
### Fixed
- Exit check_changes and label_check functions if not a merge request event

## [2.4.14]
### Fixed
- check_changes function to rebase before checking for changes.

## [2.4.13]
### Fixed
- AWS network down stage should now run when a prior stage is cancelled in rke2 test-ci::infra pipelines

## [2.4.12]
### Added
- logic in templates.sh to check for and auto-enable minioOperator when loki is also enabled

## [2.4.11]
### Fixed
- Fix exit codes from API deprecation check and oscal component check

## [2.4.10]
### Added
- Auto-tagging added to helm pipeline for Gluon

## [2.4.9]
### Changed
- Updated RKE2 CI to 1.23.5, includes a number of other changes to make things work
  - Remove pinning of AWS TF provider (no longer needed on newer RKE2 TF)
  - Add to userdata: iptables rules (needed for RKE2 on stig'd image) and mount the extra volume for ephemeral storage
  - Use latest AMI for CIS STIG instead of pre-built RHEL + download/install RKE2 (no longer assume pre-baked in)
  - Update RKE2 TF to latest upstream, update RKE2 version to latest 1.23.x
  - Set InstanceOpsRole IAM profile for nodes (required for provisioning EBS PVCs)
  - Apply AWS EBS CSI provisioner as required by Kubernetes 1.23.x
- Fix a logging issue that could prevent debug output in certain scenarios

## [2.4.8]
### Fixed
- Fixed missing gitlab runner label check for real

## [2.4.7]
### Fixed
- Fixed missing gitlab runner label check

## [2.4.6]
### Changed
- If no newline is in the curl output when pulling images.txt, add one

## [2.4.5]
### Added
- Added conditional that checks if a Big Bang version has been specified in a package repo's `test-values.yaml` file

## [2.4.4]
### Changed
- Modified bb down for RKE2 pipeline - uninstall istio first to clean up ELBs, then helm uninstall with wait

## [2.4.3]
### Added
- Don't pass --wait argument to helm upgrade if DISABLE_HELM_UPGRADE_WAIT is set to true

## [2.4.2]
### Added
- Added `CI_VALUES_OVERRIDES_FILE` variable to the `"aws/rke2/bigbang up"` stage in `pipelines/bigbang.yaml` to specify a values file for RKE2 pipelines
- Added conditional in `scripts/deploy/01_deploy_bigbang.sh` that checks if the new variable is set and deploys Big Bang accordingly

## [2.4.1]
### Fixed
- Re-added `jsonschema`, missing due to caching of docker build layers

## [2.4.0]
### Changed
- Updated k3d to 5.4.1
- Updated image in k3d config to k3s v1.23.4-k3s1
- Added gateway config to docker network setup (gateway must be set for k3d to start up)

## [2.3.9]
### Added
- Added `package_oscal_validate` function to validate an oscal-component.yaml against a spec file in oscal/oscal_component_schema.json

## [2.3.8]
### Added
- Added change owner to cypress directories

## [2.3.7]
### Added
- Added label and commit message filter for "disable-ci" to disable pipelines on MR

## [2.3.6]
### Added
- Added `check_changes` function to enable disabled packages in pipeline if any changes are detected 

## [2.3.5]
### Fixed
- Fixed updates to new function names in sandbox.yaml and third-party.yaml

## [2.3.4]
### Fixed
- Fixed minor bugs in auto tag stage functions

## [2.3.3]
### Added
- Auto Tag stage to automate tag creation whenever merging into default branch based off `chart/Chart.yaml`

## [2.3.2]
### Added
- Added check for new line in changelog function

## [2.3.1]
### Added
- Add `pipelines/bigbang-bot.yaml` pipeline

## [2.3.0]
### Updated
- Updated bb-ci container

## [2.2.22]
### Added
- Add Kyverno Policies to list of packages

## [2.2.21]
### Changed
- Add function get_cpumem() to dump cpu and memory usage via the metrics API

## [2.2.20]
- Changed kubeconfig permissions to 600 due to pipeline warnings about group and world readable

## [2.2.19]
### Changed
- Added label for `app.kubernetes.io/name` to all namespaces

## [2.2.18]
### Fixed
- Cleaned up duplicate images and MetalLB images from BB pipeline

## [2.2.17]
### Fixed
- Use `mv` instead of `cp` for package re-test cypress artifacts

## [2.2.16]
### Fixed
- Bug fix to prevent a lot of repetition of `kubectl describe` in the new function

## [2.2.15]
### Fixed
- Add set -x in the shell when DEBUG_ENABLED is set, move traps to templates.sh, add check so templates.sh can't be run standalone

## [2.2.14]
### Added
- Added cluster_info_dump debug function to output cluster-info dump to artifact cluster_info_dump.txt

## [2.2.13]
### Added
- Added `describe_resources` function to debug output which will save all resources out to artifacts in kubectl_describes/

## [2.2.12]
### Added
- Added `bigbang_additional_images` function to get images from the package level `images.txt` for synker packaging.

## [2.2.11]
### Added
- Added bbctl pipeline

## [2.2.10]
### Added
- Added ability to put `DEBUG` in MR title to enable debug output

## [2.2.9]
### Added
- Added Debug function to output all pod logs to artifacts

## [2.2.8]
### Fixed
- Use a shared volume instead of configmaps for storing cypress videos

## [2.2.7]
### Fixed
- Added prevars as needed for RKE2 tests

## [2.2.6]
### Fixed
- Pinned terraform aws provider version to version 3.74.1 for rke2

## [2.2.5]
### Added
- Added logic check for `../bigbang/values.yaml`, which will determine if pipeline is running from a package or not

## [2.2.4]
### Fixed
- Tempo enable conditional improperly using `=` instead of `=~`

## [2.2.3]
### Fixed
- Integration stage merge bigbang test values into packages bigbang values
- Ability to disable bb core packages without breaking helm wait script

## [2.2.2]
### Fixed
- Deploy scripts to use new CI_DEPLOY_LABEL array 

## [2.2.1]
### Fixed
- Keycloak missing from addon list in wait script

## [2.2.0]
### Added
- Tempo package added to scripts

## [2.1.3]
### Added
- Added logic to add dependencies for Mattermost, Minio, and Velero

## [2.1.2]
### Added
- Copied integration stage from sandbox so it can be used in thirdparty pipeline as well.
- Added check for post-install-packages.yaml to package pipeline for installing packages for things like operators.

## [2.1.1]
### Added
- Created `clone_bigbang_and_merge_templates` function in library/templates.sh
- Added optional integration stage to sandbox pipeline: stands up a full bigbang deployment w/ sandbox app

## [2.1.0]
### Changed
- Updated flux cli in utility image to 0.24.0

## [2.0.28]
### Added
- Added sandox pipeline

## [2.0.27]
### Changed
- Updated the helm pipeline for newer helm commands

## [2.0.26]
### Changed
- Fixed pipeline failure when no images are installed as part of the main application

## [2.0.25]
### Changed
- Added `--all-containers=true` to `kubectl logs` to cover pods with multiple containers

## [2.0.24]
### Changed
- Upped RKE2 coredns rollout timeout to 120s

## [2.0.23]
### Fixed
- Fixed syntax error in release cli (an extra `/`)

## [2.0.22]
### Fixed
- Fixed syntax error in release cli

## [2.0.21]
### Added
- Generation of image lists per package as an artifact for a release.

## [2.0.20]
### Added
- New wait on MetalLB so that it is not listed in package image lists

## [2.0.19]
### Fixed
- Kyverno to addons so it doesn't deploy for every pipeline

## [2.0.18]
### Added
- Added kyverno to add HR list
- Enable kyverno on MR label or default branch

## [2.0.17]
### Updated
- Updated helm release wait timeout to 1 hour

## [2.0.16]
### Added
- Changes to allow loki/promtail to co-exist with efk

## [2.0.15]
### Added
- Artifacts for RKE2/nightly pipeline

## [2.0.14]
### Added
- Vault added to addon HR list

## [2.0.13]
### Removed
- Removed dependency check from package_repos
### Added
- Dependencies now output in release_notes.txt

## [2.0.12]
### Added
- Only package images from *.dso.mil

## [2.0.11]
### Added
- Added initial third party pipeline

## [2.0.10]
### Fixed
- Resolved an issue with the terminating pod wait checks

## [2.0.9]
### Changed
- Added changelog format checker function to chart update check job.

## [2.0.8]
### Changed
- Changes to support removal of the logging.engine parameter

## [2.0.7]
### Removed
- Removed old pipeline and associated files

## [2.0.6]
### Changed
- bigbang and bigbang-package pipelines to not run if label kind::docs is on the MR

## [2.0.5]
### Changed
- scripts/deploy changes to account for the 2 logging engines and `PLG` label on MRs

## [2.0.4]
### Added
- Service and pod CIDRs for k3d

## [2.0.3]
### Added
- Cypress artifact script for local helm test debugging

## [2.0.2]
### Changed
- moved bb synker file out and renamed package-synker to just synker
- In BB we moved the ingress cert values to chart/ingress-certs.yaml so a yq was added to merge them into test-values.yaml

## [2.0.1]
### Changed
- Had to bump the version of bb-ci due to cacheing on the runners

## [2.0.0]
### Changed
- Updated k3d-builder and moved version to tag version
- Cleaned up unused files
- Added bigbang pipeline /pipelines/bigbang.yaml
- Added third party pipeline /pipelines/third-party.yaml
- Added sandbox pipeline /pipelines/sandbox.yaml
- Moved package pipeline to /pipelines/bigbang-package.yaml
- Added /infrastructure and /cluster folders and subfolders for each infra and distro
- Moved script functions to library/templates.sh

## [1.2.14]
### Changed
- Changed hardcoded reg1_user to ci variable

## [1.2.13]
### Changed
- Updated tests to verify readme updates

## [1.2.12]
### Changed
- Moved image list to before running package tests

## [1.2.11]
### Changed
- Removed duplicate tar line for package release

## [1.2.10]
### Added
- Added additional echo statements around waits to assist with debug
- Added wait for terminating pods before waiting for ready pods

## [1.2.9]
### Changed
- Update check now exits with success when no changelog.md or chart/chart.yaml is found in the target branch.

## [1.2.8]
### Changed
- added pluto helm deprecation checks in configuration validation stage.
- added kubent in cluster deprecation checks in package install stage.

## [1.2.7]
### Changed
- added retries into each package-test stage.

## [1.2.6]
### Changed
- Updated package-tests.yml to pattern match SKIP UPGRADE and SKIP UPDATE CHECK anywhere in the MR title.

## [1.2.5]
### Changed
- Updated upgrade to use MR target branch instead of default branch.

## [1.2.4]
### Changed
- Updates made to templates/package-tests.yml to remove dependencies and test artifacts from the generated images.txt file.

## [1.2.3]
### Added
- Check for CHANGELOG and chart version bump

## [1.2.2]
### Changed
- Updated the k3d-builder image
- Added cypress/kubectl Dockerfile

## [1.2.1]
### Changed
- Allow failures on upgrade job only for test failure, will throw a more clear warning when this happens

## [1.2.0]
### Added
- Added upgrade testing (note: post-upgrade testing is currently allowed to fail to allow for a transition period and test updates as needed)
### Changed
- Refactored code for better reusability across jobs
### Removed
- Removed standalone cypress testing
- Removed upstream istio installation

## [1.1.5]
### Added
- Label added to istio install

## [1.1.4]

### Fixed

- Fixed pipeline robot user.

## [1.1.3]

### Fixed

- Fixed tar command in cypress runner.

## [1.1.2]

### Updated

- Updated readme with how to make cypress videos smaller.

### Changed

- Changed tar command in bb-test-lib library for better compression of cypress videos and screenshots.

### Removed

- Removed container builds from .gitlab-ci.yaml that were creating numerious builds for unused containers.

## [1.1.1]

### Added

- Added additionalVolume and additionalVolumeMounts to the cypress and script runner test templates
- Updated README with examples of using additionalVolumeMounts and additionalVolumes

## [1.1.0]

### Added

- Added bb-test-lib with templates to consume in packages for easy testing
- Handle helm logs better and provide for cypress artifact retrieval from helm tests

## [1.0.7]

### Added

- better rego policies to cover our package requirements

## [1.0.6]

### Changed

- moved `private-registry` secret to dso.mil IB address

## [1.0.5]

### Fixed

- bug with helm tests not being in correct directory

## [1.0.4]

### Fixed

- istio bug with secret getting created when it shouldn't

## [1.0.3]

### Added

- Added helm test invocation in the package pipeline to execute any helm chart tests in the package.
- Added log dump to display the results of any chart tests in the pipeline log

## [1.0.2]

### Fixed

- Bug where istio would not create the cert due to variables not being up to date

## [1.0.1]

### Changed

- Test values now looks at both `test-values.yaml` and `test-values.yml`
- Allow overriding of the helm release install names for dependencies & the package
  - dependencies can now specify `dependency.package-name` as the helmrelease name
  - the main package can accept `PACKAGE_HELM_NAME` as the helmrelease name
- Added ability to override the namespace to install the package to
  - `PACKAGE_NAMESPACE` variable in the gitlab-ci file

## [1.0.0]

### Added

- Version control added for better future-proofing
- First release, pipeline with basic conftesting, cypress tests, and package/release stages
