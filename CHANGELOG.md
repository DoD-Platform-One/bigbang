# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.40.1] - 2021-10-07
### Updated
- Updated base kiali image to v1.40.1
- Updated base kiali-operator image to v1.40.1
- Updated base kiali-operator helm chart to v1.40.1
- Updated VS to v1beta1 API version

## [1.39.0-bb.3] - 2021-09-28
### Added
- Added readOnlyRootFileSystem to Kiali deployment

## [1.39.0-bb.2] - 2021-09-14
### Fixed
- Fixed requests typo

## [1.39.0-bb.1] - 2021-09-13
### Added
- Added wait script for CI

## [1.39.0-bb.0] - 2021-08-25
### Updated
- Updated base images to v1.39.0
- Updated base kiali-operator helm chart to v1.39.0

## [1.37.0-bb.3] - 2021-08-25
### Updated
- Increased resource limits and requests to 512Mi due to OOM errors

## [1.37.0-bb.2] - 2021-08-20
### Updated
- Increased resource limits and requests for memory on Kiali operator to prevent OOMKilled errors

## [1.37.0-bb.1] - 2021-08-16
### Updated
- Set resource limits and requests for kiali operator and cr.

## [1.37.0-bb.0] - 2021-08-03
### Updated
- Updated kiali-operator helm chart to v1.37.0
- Updated kiali images to latest in irobank images v1.37.0

## [1.36.0-bb.3] - 2021-07-21
- add openshift toggle. conditionally modify networkpolicy for dns

## [1.36.0-bb.2]
### Fixed
- Use ironbank bigbang base image 8.4 for svc-patch-job

## [1.36.0-bb.1]
### Fixed
- Istio disabled by default

## [1.36.0-bb.0]
### Added
- Because of a change in v1.35.0 of Kiali, we added a job to patch svc/kiali created by the Kiali CR (see https://github.com/kiali/kiali/issues/4143#issuecomment-873073251)

### Changed
- Updated base images to v1.36.0
- Updated base kiali-operator helm chart to v1.36.0
- Removing cr.spec.custom_dashboards from values.yaml. Its function was unclear, and it was throwing errors

## [1.32.0-bb.2]
### Added
- Network Policy

## [1.32.0-bb.1]
### Changed
- Copied default CR file into values.yaml from here https://github.com/kiali/kiali-operator/blob/v1.28/deploy/kiali/kiali_cr.yaml

