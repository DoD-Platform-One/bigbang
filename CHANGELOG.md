# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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

