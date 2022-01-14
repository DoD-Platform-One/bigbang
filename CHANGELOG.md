# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
