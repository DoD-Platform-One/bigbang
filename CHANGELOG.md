# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.23.0-bb.0] - 2022-12-06
### Changed
- even bigger
## [1.22.0-bb.0] - 2022-12-06
### Changed
- huge release
## [1.21.0-bb.0] - 2022-12-06
### Changed
- stuff
## [1.20.0-bb.0] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.6] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.5] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.4] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.3] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.2] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.1] - 2022-12-06
### Changed
- stuff
## [1.19.0-bb.0] - 2022-12-06
### Changed
- ironbank/opensource/mattermost/mattermost-operator updated from 1.18.1 to 1.19.0

## [1.18.1-bb.1] - 2022-09-08
### Added
- Added default securitycontext to container (drop capabilities, non-privileged, read only fs)
- Added post install package to validate MM successful install

## [1.18.1-bb.0] - 2022-06-23
### Changed
- Updated to latest 1.18.1 image/manifests

## [1.18.0-bb.1] - 2022-06-14
### Changed
- Adding securityContext section to deployment template and chart values.

## [1.18.0-bb.0] - 2022-04-20
### Changed
- Updated to latest IB image 1.18.0

## [1.17.0-bb.3] - 2022-04-12
### Added
- Default Istio `PeerAuthentication` for mTLS

## [1.17.0-bb.2] - 2022-01-31
### Updated
- Update Chart.yaml to follow new standardization for release automation
- Added renovate check to update new standardization

## [1.17.0-bb.1] - 2022-01-12
### Added
- Ability to specify pod annotations in value file.

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
