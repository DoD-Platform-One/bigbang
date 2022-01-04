# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.17.0-bb.0] - 2022-01-03
### Changed
- Updated to latest IB image 1.17

## [1.16.0-bb.0] - 2021-11-01
### Changed
- Updated to latest IB image 1.16
### Added
- Documentation on how to perform a package update with kpt/manual changes

## [1.15.0-bb.0] - 2021-09-21
### Changed
- Updated to latest IB image 1.15
### Added
- Added support for sidecars via networkPolicies

## [1.14.0-bb.4] - 2021-08-30
### Added
- Added support for tolerations

## [1.14.0-bb.3] - 2021-08-19
### Added
- Added resource requests and limits

## [1.14.0-bb.2] - 2021-06-21
### Added
- Added network policies with a default deny and egress allowed to the API

## [1.14.0-bb.1] - 2021-06-03
### Changed
- Remove network policies

## [1.14.0-bb.0] - 2021-06-01
### Changed
- Updated to latest v1.14.0 operator from IB

## [1.13.0-bb.3] - 2021-05-25
### Added
- Basic network policies to deny all ingress, allow egress only within cluster

## [1.13.0-bb.2] - 2021-04-05
### Added
- Modified pod affinity spec and values, documentation

## [1.13.0-bb.1] - 2021-03-30
### Added
- Added pod affinity and anti-affinity, documentation

## [1.13.0-bb.0] - 2021-03-15
### Changed
- Bumped the operator image to 1.13.0 from Ironbank

## [1.12.0-bb.0] - 2021-02-12
### Added
- Initial operator from upstream v1.12.0 using Ironbank images
