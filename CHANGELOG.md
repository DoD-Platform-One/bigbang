# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.5.1-bb.0] - 2022-09-06
### Update
- Updated Confluence node to 7.19.0 and gluon 0.3.0
- Updated kpt upstream

## [0.1.0-bb.21] - 2022-07-11
### Added
- Added livenessProbe configuration for statefulset pods

## [0.1.0-bb.20] - 2022-06-28
### Update
- Updated BB base image to 2.0.0

## [0.1.0-bb.19] - 2022-06-23
### Update
- Confluence to 7.18.1

## [0.1.0-bb.18] - 2022-06-08
### Update
- Hostname and synchrony updates to BB VirtualService

## [0.1.0-bb.17] - 2022-06-07
### Changed
- Enable user access logs by default in server.xml

## [0.1.0-bb.16] - 2022-05-17
### Update
- Moved image to Ironbank and updated to 7.17.1 and gluon 0.2.9

## [0.1.0-bb.15] - 2022-05-10
### Added
- Horizontal pod scaling yaml added with Value file update

## [0.1.0-bb.14] - 2022-04-18
### Fixed
- serviceMonitor for confluence by adding quote for endpoint port

## [0.1.0-bb.13] - 2022-04-12
### Added
- server.xml disabled tomcat error report configuration

## [0.1.0-bb.12] - 2022-02-01
### Added
- License added

## [0.1.0-bb.11] - 2022-01-05
### Added
- footer-content.vm file added to files section of the chart.
- footer-content-vm configmap template created.
- Values.yaml file updated with footer-content-vm configmap volume mount.
- This configuration does not display the app version and node on the footer section of the UI.

## [0.1.0-bb.10] - 2021-11-30
### Added
- renovate.json added for image tracking with IB
### Fxied
- Image name for statefulset, added the tag using template
- Deprecated istio api versions updated

## [0.1.0-bb.9] - 2021-09-14
### Update
- Moved image to Ironbank and updated to 7.13.0

## [0.1.0-bb.8] - 2021-09-02
### Fix
- Remove duplicate Confluence label and service template values.

## [0.1.0-bb.7] - 2021-08-25
### Fix
- Update server.xml file to support Confluence 7.13.0.

## [0.1.0-bb.6] - 2021-06-22
### Fix
- synchrony and confluence virtual service use same FDQN.
- synchrony URL can be reach via confluence url/synchrony

## [0.1.0-bb.5] - 2021-06-18
### Fix
- Fixed vitrual services and added needed values.
