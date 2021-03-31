# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
