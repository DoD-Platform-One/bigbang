# Changelog

---
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
