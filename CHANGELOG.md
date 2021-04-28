# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.6]
### Changed
- removed `private-registry-mil` secret
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
