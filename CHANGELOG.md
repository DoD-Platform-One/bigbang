# Changelog

---
## [34.1.0-bb.2] - 2021-10-20
### Modified
- Fixed extraLabels indentation

## [34.1.0-bb.1] - 2021-10-20
### Modified
- Fixed java environment var

## [34.1.0-bb.0] - 2021-10-15
### Modified
- Fixing chart versioning.

## [34.1-01-bb.1] - 2021-10-12
### Modified
- Updated cypress tests and test values to run without errors.

## [34.1-01-bb.0] - 2021-09-13
### Update
- Updated ironbank container because previous version had issues with non-fips nodes

## [34.0.0-bb.1] - 2021-09-13
### Modified
- Updated values.yaml with examples of auditing/logging containers

## [34.0.0-bb.0] - 2021-09-03
### Modified
- Sync with upstream charts 34.0.0 at https://github.com/sonatype/helm3-charts.git
- Version bump to 3.34.0

## [33.1.0-bb.0] - 2021-08-27
### Modified
- Sync with upstream charts 33.1.0 at https://github.com/sonatype/helm3-charts.git
- Version bump to 3.33.1
- Increased default cpu resource request and limits

## [29.1.0-bb.9] - 2021-09-01
### Changed
- add map to specify image, tag, and policy in values for proxy and saml jobs

## [29.1.0-bb.8] - 2021-08-23
### Added
- Added resource requests and limits to pods with guaranteed QoS.

## [29.1.0-bb.7] - 2021-07-27
### Fixes
- Fixed extraLabels indentation in all resources that have it.
### Added
- Added extraLabels to Deployment template labels.

## [29.1.0-bb.6] - 2021-06-30
### Added
- Add openshift toggle, conditionally add port 5353 egress. Changing "openshift:" to true in values.yaml will enable.

## [29.1.0-bb.5] - 2021-06-30
### Added
- Network policy to allow prometheus scraping of istio envoy sidecar

## [29.1.0-bb.4]
### Changed
- kube-api network policy toggle
- istio network policy stricter podSelector values

## [29.1.0-bb.3] - 2021-06-08
### Modified
- Modified CI tests to use new library and infrastructure

### Added
- Network policy for helm-tests to save artifacts

## [29.1.0-bb.2]
### Added
- default-deny-all network policy
- istio network policy
- monitoring network policy
