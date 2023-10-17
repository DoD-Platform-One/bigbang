# Release Notes - 2.13.0

Please see our [documentation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/2.13.0) page for more information on how to consume and deploy BigBang. This release was primarily tested on Kubernetes 1.26.3 (RKE2).

## Upgrade Notices

> Add any upgrade notices from the release issue here. You may also want to
> reach out to package maintainers for anything that looks like a major change.
> Changelog diffs for packages are included below in the `## Changes in 2.13.0`
> which may be helpful to identify "major chanes".

### **Upgrades from previous releases**

If coming from a version pre-`2.12.0`, note the additional upgrade notices in any release in between. The BB team doesn't test/guarantee upgrades from anything pre-`2.12.0`.

## Packages

| Package                                                                                                                                                                                                                 | Type   | Package Version                                                | BB Version                               |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|----------------------------------------------------------------|------------------------------------------|
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Istio Controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane)                                               | Core   | Istio `1.19.0` Tetrate Istio Distro `1.18.2`                   | `1.19.0-bb.2` [🔗](#istio-controlplane)  |
| [Istio Operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator)                                                                                                                                        | Core   | Istio Operator `1.19.0` Tetrate Istio Distro Operator `1.19.0` | `1.19.0-bb.1`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Jaeger](https://repo1.dso.mil/big-bang/product/packages/jaeger)                                                                       | Core   | `1.47.0`                                                       | `2.47.0-bb.1` [🔗](#jaeger)              |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali)                                                                         | Core   | `1.74.0`                                                       | `1.74.0-bb.2` [🔗](#kiali)               |
| [Cluster Auditor](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor)                                                                                                                                      | Core   | `0.0.7`                                                        | `1.5.0-bb.8`                             |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy)                                                                   | Core   | `3.13.0`                                                       | `3.13.0-bb.2` [🔗](#gatekeeper)          |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno)                                                                     | Core   | `1.9.3`                                                        | `3.0.0-bb.5` [🔗](#kyverno)              |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kyverno Policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies)                                                   | Core   | `3.0.4`                                                        | `3.0.4-bb.1` [🔗](#kyverno-policies)     |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter)                                                   | Core   | `2.10.4`                                                       | `2.16.0-bb.6` [🔗](#kyverno-reporter)    |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Elasticsearch Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana)                                           | Core   | Kibana `8.9.1` Elasticsearch `8.10.2`                          | `1.5.0-bb.0` [🔗](#elasticsearch-kibana) |
| [Eck Operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator)                                                                                                                                            | Core   | `2.9.0`                                                        | `2.9.0-bb.1`                             |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit)                                                                 | Core   | `2.1.8`                                                        | `0.37.0-bb.2` [🔗](#fluentbit)           |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Promtail](https://repo1.dso.mil/big-bang/product/packages/promtail)                                                                   | Core   | `2.9.1`                                                        | `6.15.0-bb.3` [🔗](#promtail)            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Loki](https://repo1.dso.mil/big-bang/product/packages/loki)                                                                           | Core   | `2.9.1`                                                        | `5.23.1-bb.1` [🔗](#loki)                |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Neuvector](https://repo1.dso.mil/big-bang/product/packages/neuvector)                                                                 | Core   | `5.1.3`                                                        | `2.4.5-bb.7` [🔗](#neuvector)            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo)                                                                         | Core   | Tempo `2.2.2` Tempo Query `2.2.2`                              | `1.6.1-bb.3` [🔗](#tempo)                |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring)                                                               | Core   | Prometheus `2.47.0` Grafana `10.0.3` Alertmanager `0.26.0`     | `51.1.0-bb.2` [🔗](#monitoring)          |
| [Grafana](https://repo1.dso.mil/big-bang/product/packages/grafana)                                                                                                                                                      | Core   | `10.0.3`                                                       | `6.58.9-bb.4`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock)                                                                 | Core   | `30.02.123`                                                    | `0.13.0-bb.3` [🔗](#twistlock)           |
| [Wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper)                                                                                                                                                      | Core   | N / A                                                          | `0.4.1`                                  |
| [Argocd](https://repo1.dso.mil/big-bang/product/packages/argocd)                                                                                                                                                        | Addon  | `2.8.2`                                                        | `5.46.7-bb.2`                            |
| [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice)                                                                                                                                              | Addon  | `0.5.3`                                                        | `0.5.3-bb.18`                            |
| [Minio Operator](https://repo1.dso.mil/big-bang/product/packages/minio-operator)                                                                                                                                        | Addon  | `5.0.9`                                                        | `5.0.9-bb.0`                             |
| [Minio](https://repo1.dso.mil/big-bang/product/packages/minio)                                                                                                                                                          | Addon  | `RELEASE.2023-09-23T03-47-50Z`                                 | `5.0.9-bb.2`                             |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gitlab](https://repo1.dso.mil/big-bang/product/packages/gitlab)                                                                       | Addon  | `16.4.1`                                                       | `7.4.1-bb.3` [🔗](#gitlab)               |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gitlab Runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner)                                                         | Addon  | `15.11.0`                                                      | `0.52.0-bb.7` [🔗](#gitlab-runner)       |
| [Nexus](https://repo1.dso.mil/big-bang/product/packages/nexus)                                                                                                                                                          | Addon  | `3.53.1-02`                                                    | `53.1.0-bb.3`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube)                                                                 | Addon  | `9.9.2-community`                                              | `8.0.2-bb.0` [🔗](#sonarqube)            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Fortify](https://repo1.dso.mil/big-bang/product/packages/fortify) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | Addon  | `23.1.2.0005`                                                  | `1.1.2311007-bb.2` [🔗](#fortify)        |
| [Haproxy](https://repo1.dso.mil/big-bang/product/packages/haproxy)                                                                                                                                                      | Addon  | `2.2.21`                                                       | `1.12.0-bb.1`                            |
| [Anchore Enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise)                                                                                                                                | Addon  | Enterprise `4.8.0` Engine `1.1.0`                              | `1.26.1-bb.0`                            |
| [Mattermost Operator](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator)                                                                                                                              | Addon  | `1.20.1`                                                       | `1.20.1-bb.0`                            |
| [Mattermost](https://repo1.dso.mil/big-bang/product/packages/mattermost)                                                                                                                                                | Addon  | `9.0.0`                                                        | `9.0.0-bb.0`                             |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Velero](https://repo1.dso.mil/big-bang/product/packages/velero)                                                                       | Addon  | `1.11.1`                                                       | `5.0.2-bb.4` [🔗](#velero)               |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak)                                                                   | Addon  | `21.1.1`                                                       | `18.4.3-bb.10` [🔗](#keycloak)           |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Vault](https://repo1.dso.mil/big-bang/product/packages/vault)                                                                         | Addon  | `1.13.1`                                                       | `0.25.0-bb.4` [🔗](#vault)               |
| [Metrics Server](https://repo1.dso.mil/big-bang/product/packages/metrics-server)                                                                                                                                        | Addon  | `0.6.3`                                                        | `3.10.0-bb.2`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Harbor](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/harbor)                                                              | Addon  | `2.8.4`                                                        | `1.12.4-bb.3` [🔗](#harbor)              |

## Changes in 2.13.0

### Big Bang MRs

- [!3288](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3288): gatekeeper update to 3.13.0-bb.2
- [!3274](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3274): istio update to 1.19.0-bb.2
- [!3159](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3159): Update Flux
- [!3248](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3248): Update istio to 1.19.0-bb.1
- [!3207](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3207): updated licensing-model.md for issue#1698
- [!3243](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3243): 1032: Enable Istio mTLS globally on istio-system namespace
- [!3234](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3234): Change default AMI for k3d-dev to support users that don't have access to marketplace


### Istio Controlplane


```markdown
# Changelog Updates

## [1.19.0-bb.2] - 2023-10-11
### Changed
- Modified OSCAL Version for istio and updated to 1.1.1

## [1.19.0-bb.1] - 2023-10-02
### Changed
- Enable Istio mTLS (via peerAuthentication) globally on istio-system namespace
```


### Jaeger

- [!3294](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3294): jaeger update to 2.47.0-bb.1

```markdown
# Changelog Updates

## [2.47.0-bb.1] - 2023-10-11
### Updated
- Modified OSCAL Version for jaeger and updated to 1.1.1
```


### Kiali

- [!3276](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3276): kiali update to 1.74.0-bb.2
- [!3253](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3253): kiali update to 1.74.0-bb.1
- [!3221](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3221): kiali update to 1.72.0-bb.2

```markdown
# Changelog Updates

## [1.74.0-bb.2] - 2023-10-11
### Changed
- OSCAL version update from 1.0.0 to 1.1.1

## [1.74.0-bb.1] - 2023-10-06
### Changed
- Fixed Cypress Testing

## [1.74.0-bb.0] - 2023-10-03
### Changed
- Renovated chart to 1.74.0
- Bumped kiali operator to 1.74.0
- Bumped kiali tenant to 1.74.1
- Change runAsUser and runAsGroup to 2001 for ansible user

## [1.72.0-bb.2] - 2023-09-07
### Added
- Updated non root group user
```


### Gatekeeper


```markdown
# Changelog Updates

## [3.13.0-bb.2] - 2023-10-11
### Removed
- OSCAL version update from 1.0.0 to 1.1.1
```


### Kyverno

- [!3290](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3290): kyvernoPolicies update to 3.0.4-bb.1
- [!3283](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3283): kyvernoReporter update to 2.16.0-bb.6
- [!3272](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3272): kyverno update to 3.0.0-bb.5

```markdown
# Changelog Updates

## [3.0.0-bb.5] - 2023-10-11
### Changed
- Modified `features.policyExceptions.enabled` to true
- Restricted new `policyExceptions` to the kyerno `namespace`
```


### Kyverno Policies

- [!3290](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3290): kyvernoPolicies update to 3.0.4-bb.1

```markdown
# Changelog Updates

## [3.0.4-bb.1] - 2023-10-11
### Changed
- respect `autogenControllers`, `background`, and `failurePolicy` values across all policies
```


### Kyverno Reporter

- [!3283](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3283): kyvernoReporter update to 2.16.0-bb.6

```markdown
# Changelog Updates

## [2.16.0-bb.6] - 2023-10-11
### Changed
- Harden API token automounting behavior of ServiceAccount/Pod

## [2.16.0-bb.5] - 2023-10-5
### Changed
- Exposed automountServiceAccountToken as a value
```


### Elasticsearch Kibana

- [!3263](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3263): elasticsearchKibana update to 1.5.0-bb.0
- [!3260](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3260): elasticsearchKibana update to 1.4.0-bb.1

```markdown
# Changelog Updates

## [1.5.0-bb.0] - 2023-10-11
### Changed
- ironbank/elastic/elasticsearch/elasticsearch updated from 8.9.0 to 8.10.2
- ironbank/elastic/kibana/kibana updated from 8.9.0 to 8.9.1

## [1.4.0-bb.1] - 2023-10-06
### Updated
- Updated OSCAL version from 1.0.0 to 1.1.1

## [1.4.0-bb.0] - 2023-10-2
### Changed
- ironbank/elastic/elasticsearch/elasticsearch updated from 8.7.1 to 8.9.0
- ironbank/elastic/kibana/kibana updated from 8.7.1 to 8.9.0
```


### Fluentbit

- [!3263](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3263): elasticsearchKibana update to 1.5.0-bb.0
- [!3296](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3296): fluentbit update to 0.37.0-bb.2
- [!3260](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3260): elasticsearchKibana update to 1.4.0-bb.1

```markdown
# Changelog Updates

## [0.37.0-bb.2]
### Changed
- Modified OSCAL Version for fluentbit and updated to 1.1.1
```


### Promtail

- [!3282](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3282): promtail update to 6.15.0-bb.3
- [!3269](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3269): promtail update to 6.15.0-bb.2

```markdown
# Changelog Updates

## [6.15.0-bb.3] - 2023-10-16
### Updated
- Updated registry1.dso.mil/ironbank/opensource/jimmidyson/configmap-reload v0.11.1 -> v0.12.0

## [6.15.0-bb.2] - 2023-10-11
### Updated
- Update OSCAL version from 1.0.0 to 1.1.1
```


### Loki


```markdown
# Changelog Updates

## [5.23.1-bb.1] - 2023-10-13
### Added
- Helm validation for backend scaling requirements introduced with loki 2.9.*
```


### Neuvector

- [!3278](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3278): neuvector update to 2.4.5-bb.7
- [!3219](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3219): add default no-secret client_secret to neuvector

```markdown
# Changelog Updates

## [2.4.5-bb.7] - 2023-10-11
### Changed
- Update OSCAL version from 1.0.0 to 1.1.1
```


### Tempo

- [!3289](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3289): tempo update to 1.6.1-bb.3
- [!3270](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3270): tempo update to 1.6.1-bb.2

```markdown
# Changelog Updates

## [1.6.1-bb.3] - 2023-10-12
### Changed
- Harden API token automounting behavior of ServiceAccount/Pod

## [1.6.1-bb.2] - 2023-10-11
### Changed
- OSCAL Version update from 1.0.0 to 1.1.1
```


### Monitoring

- [!3280](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3280): monitoring update to 51.1.0-bb.2
- [!3252](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3252): monitoring update to 51.1.0-bb.1

```markdown
# Changelog Updates

## [51.1.0-bb.2] - 2023-10-11
### Changed
- Update OSCAL version from 1.0.0 to 1.1.1

## [51.1.0-bb.1] - 2023-10-03
### Changed
- Add delay before sidecar proxy kill for monitoring jobs
```


### Twistlock

- [!3284](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3284): twistlock update to 0.13.0-bb.3

```markdown
# Changelog Updates

## [0.13.0-bb.3] - 2023-10-11
### Changed
- OSCAL version update from 1.0.0 to 1.1.1

## [0.13.0-bb.2] - 2023-10-05
### Changed
- gluon updated from 0.4.0 to 0.4.1
- Updated Cypress to version 13.0.0
- Changed the Cypress file structure
- Changed to use the script for e2e testing instead of Cypress
```


### Gitlab

- [!3275](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3275): gitlab update to 7.4.1-bb.3
- [!3273](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3273): gitlab update to 7.4.1-bb.2
- [!3254](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3254): gitlab update to 7.4.1-bb.1
- [!3246](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3246): gitlabRunner update to 0.52.0-bb.7

```markdown
# Changelog Updates

## [7.4.1-bb.3] - 2023-10-11
### Changed
- OSCAL Version update from 1.0.0 to 1.1.1

## [7.4.1-bb.2] - 2023-10-09
### Changed
- Update security contexts for kyverno non-root-group policy violations

## [7.4.1-bb.1] - 2023-10-06
### Changed
- Fixed typo in documentation that leads to error
```


### Gitlab Runner

- [!3246](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3246): gitlabRunner update to 0.52.0-bb.7

```markdown
# Changelog Updates

## [0.52.0-bb.7] - 2023-10-05
### Changed
- Update cypress tests for compatibility with latest gitlab version (7.4.1)
```


### Sonarqube

- [!3298](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3298): sonarqube update to 8.0.2-bb.0

```markdown
# Changelog Updates

## [8.0.1-bb.0] - 2023-10-16
### Changed
- Update release to sonarqube-8.0.2-sonarqube-dce-7.0.2
- sonarqube from 9.9.1-community to 9.9.2-community
- postgres-exporter from 0.13.2 to 0.14.0
- Update release to sonarqube-8.0.1-sonarqube-dce-7.0.1
- sonarqube from 9.9.0-community to 9.9.1-community
- postgres-exporter from 0.11.1 to 0.12.0
- postgresql12 from 12.14 to 12.15
```


### Fortify

- [!3256](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3256): fortify update to 1.1.2311007-bb.2

```markdown
# Changelog Updates

## [1.1.2311007-bb.2] - 2023-10-06
### Updated
- fixed the network policy error
```


### Velero

- [!3299](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3299): velero update to 5.0.2-bb.4
- [!3264](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3264): velero update to 5.0.2-bb.3

```markdown
# Changelog Updates

## [5.0.2-bb.4] - 2023-10-11
### Changed
- Added testing for scheduled backups

## [5.0.2-bb.3] - 2023-10-11
### Changed
- Fixing changelog entries
```


### Keycloak

- [!3268](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3268): keycloak update to 18.4.3-bb.10
- [!3259](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3259): keycloak update to 18.4.3-bb.9

```markdown
# Changelog Updates

## [18.4.3-bb.10] - 2023-10-11
### Updated
- OSCAL version updated from 1.0.0 to 1.1.1

## [18.4.3-bb.9] - 2023-10-10
### Updated
- Fixed and updated changelog entries

## [18.4.3-bb.8] - 2023-10-03
### Updated
- Updated non root group user

## [18.4.3-bb.7]-] - 2023-10-03
### Updated
- Added dev client for neuvector to baby-yoda realm

## [18.4.3-bb.6] - 2023-09-27
### Updated
- Updated horizontal pod autoscaler to select and apply the appropriate API version

## [18.4.3-bb.5] - 2023-09-19
### Updated
- Updated gluon to 0.4.0 to 0.4.1
- Updated Cypress tests to accomodate cypress 13.X+
- Added chart/resources/dev/baby-yoda-bb-ci.json to enable SSO testing in the pipeline
- Improved chart/templates/bigbang/create-ci-cypress-user-hook.yaml with additional attributes

## [18.4.3-bb.4] - 2023-09-12
### Updated
- Fixed a broken link in the docs

## [18.4.3-bb.3] - 2023-08-09
### Updated
- Update securityContext for postgres to run as non-root

## [18.4.3-bb.2] - 2022-06-29
### Updated
- Update bitnami/postgresql version 15.2.0 -> 15.3.0
- Update postgresql-exporter version to 0.12.0 -> 0.12.1
- Update postgresql12 version to 12.14 -> 12.15
- Update gluon version 0.3.2 -> 0.4.0
- Update uib8-micro version 8.7 -> 8.8

## [18.4.3-bb.1] - 2023-06-27
### Updated
- Added support for LDAP egress

## [18.4.3-bb.0] - 2022-05-23
### Updated
- Update Keycloak version to 21.1.1
- Update bitnami postgres exporter to 0.12.0

## [18.4.0-bb.3] - 2023-05-17
### Updated
- Update chat/values.yaml hostname key to domain
- Updated docs, changing hostname to domain

## [18.4.0-bb.2] - 2022-03-30
### Updated
- Update helm.sh/images postgresql ironbank image to 12.14
- Update bitnami postgres version to 15.2.0
- Update Keycloak version to 21.0.2
- new plugin version 3.2.0

## [18.4.0-bb.1] - 2022-02-27
### Updated
- new plugin version 3.1.0

## [18.4.0-bb.0] - 2022-01-24
### Updated
- Update helm chart to 18.4.0
- Update Keycloak version to 20.0.3

## [18.3.0-bb.2] - 2022-01-17
### Changed
- Update gluon to new registry1 location + latest version (0.3.2)

## [18.3.0-bb.1] - 2023-01-11
### Changed
- Fix PeerAuthentication exception policy for infinispan/jgroups communication

## [18.3.0-bb.0] - 2022-12-30
### Updated
- Update helm chart to 18.3.0
- Upgrade Keycloak image from version 18.0.1-legacy to version 20.0.2
- Update Java truststore to DoD trusted certificate authorities version 9.5

### Changed
- Migration to new Quarkus deployment architecture

## [18.2.1-bb.6] - 2022-12-12
### Added
- Added keycloak-primary-app-exception for JPGROUPS

## [18.2.1-bb.5] - 2022-10-28
### Added
- Added ServiceMonitor support for Istio mTLS

## [18.2.1-bb.4] - 2022-09-22
### Fixed
- Added capabilities drop ALL
- Updated Gluon to `0.3.1`

## [18.2.1-bb.3] - 2022-08-10
### Fixed
- Fixed metrics mTLS issue

## [18.2.1-bb.2] - 2022-08-05
### Fixed
- Fixed CI mTLS issue by injecting create-ci-cypress-user job
- Updated conditionals for PeerAuthentications to be stricter and less prone to edge cases

## [18.2.1-bb.1] - 2022-08-01
### Added
- Default Istio `PeerAuthentication` for mTLS
- Set mTLS exceptions for postgresql

## [18.2.1-bb.0] - 2022-07-19
### Updated
- Update chart to latest 18.2.1
- Upgrade Keycloak image from version 18.0.1-legacy to version 18.0.2-legacy

## [18.1.1-bb.6] - 2022-06-28
### Updated
- Updated bb base image to 2.0.0
- Updated gluon to 0.2.10
- Removed websecurity disable from cypress

## [18.1.1-bb.5] - 2022-06-27
### Updated
- Updated pgchecker initContainer to use IronBank postgres image instead of busybox
- Moved base image out of `create-ci-cypress-user-hook.yaml` and into bbtest values

## [18.1.1-bb.4] - 2022-06-24
### Updated
- Fix app version in Chart.yaml

## [18.1.1-bb.3] - 2022-06-21
### Updated
- upgrade Keycloak to app version 18.0.1 chart version 18.1.1
- Update postgresql dependency chart big-bang base image to 1.18.0

## [18.1.1-bb.2] - 2022-06-16
### Updated
- Update postgresql image and initContainer image

## [18.1.1-bb.1] - 2022-06-03
### Added
- Added network policies to support istio sidecar injection

## [18.1.1-bb.0] - 2022-05-27
### Updated
- upgrade Keycloak to app version 18.0.0-legacy chart version 18.1.1-bb.0

## [18.0.0-bb.4] - 2022-04-26
### Changed
- Custom P1 plugin changed to allow underscores in client names
- Move MODIFICATIONS.md to /docs/PACKAGE_UPDATES.md and add more upgrade documentation

### Updated
- Updated DoD certificate authorities pem file

## [18.0.0-bb.3] - 2022-04-18
### Added
- Added oscal-component

## [18.0.0-bb.2] - 2022-04-18
### Added
- Added values to the values.yaml file for using an ironbank approved image for postgresql.enabled set to true.
- Added postgresql dependency chart source under `/charts/deps` directory

## [18.0.0-bb.1] - 2022-04-15
### Changed
- Changed the bigbang.dev/applicationVersions to point to upstream version instead of tagged version

### Added
- Added PlatformOne Plugin to bigbang.dev/applicationVersions annotation

## [18.0.0-bb.0] - 2022-04-13
### Updated
- upgrade Keycloak to app version 17.0.1-legacy chart version 18.0.0-bb.0

## [17.0.1-bb.4] - 2022-03-29
### Added
- Added create-ci-cypress-user-hook.yaml, creates a cypress user using Keycloak REST API when run in CI testing.

## [17.0.1-bb.3] - 2022-03-25
### Added
- Added baby-yoda-ci.json, create a baby-yoda realm w/ MFA disabled for CI cypress testing

## [17.0.1-bb.2] - 2022-03-10
### Updated
- Updated development realm config with Vault client

## [17.0.1-bb.1] - 2022-02-17
### Updated
- Updated gluon subchart to latest version 0.2.6

## [17.0.1-bb.0] - 2022-02-02
### Changed
- upgrade Keycloak to app version 16.1.1 chart version 17.0.1

## [16.0.6-bb.3] - 2022-01-31
### Changed
- moved test values

## [16.0.6-bb.2] - 2022-01-31
### Updated
- Update Chart.yaml to follow new standardization for release automation
- Added renovate check to update new standardization

## [16.0.6-bb.1] - 2022-01-27
### Changed
- fix problem on FIPS enabled nodes

## [16.0.6-bb.0] - 2022-01-24
### Changed
- upgrade to Keycloak app version 16.1.0 chart version 16.0.6
- the x509.sh script will conditionally skip building the java keystore if it already exists
- the Java JDK version is changed from JDK8 to JDK11

## [11.0.1-bb.9] - 2021-10-21
### Changed
- add development realm with clients for testing and CI pipeline purposes

## [11.0.1-bb.8] - 2021-10-06
### Changed
- Updated Helm Tests

## [11.0.1-bb.7] - 2021-09-24
### Fixed
- fix for trash bin in custom plugin code

## [11.0.1-bb.6] - 2021-09-16
### Fixed
- modify networkPolicy for smtp egress

## [11.0.1-bb.5] - 2021-09-16
### Added
- add networkPolicy for smtp egress

### Fixed
- fix yaml syntax in values

## [11.0.1-bb.4] - 2021-09-13
### Changed
- plugin code change for email

## [11.0.1-bb.3] - 2021-09-10
### Fixed
- custom plugin code fix for email to whitelist check

## [11.0.1-bb.2] - 2021-08-12
### Changed
- added requests and limits to postgresql pod to satisfy ratio violations
- added requests and limits to CI test-values to satisfy ratio violations

## [11.0.1-bb.1] - 2021-07-22
### Changed
- allow DNS networkpolicie allow for port 5353

## [11.0.1-bb.0] - 2021-06-30
### Changed
- upgrade to keycloak app version 14.0.0 chart version 11.0.1

### Fixed
- includes fix for usercertificate attribute
- cleanup networkpolicies

## [11.0.0-bb.5] - 2021-06-14
### Changed
- set resource request and limit for CPU and memory to comply with BigBang charter

## [11.0.0-bb.4] - 2021-06-10
### Added
- modify upstream chart to add custom volumes and volumemounts for BigBang integration

## [11.0.0-bb.3] - 2021-06-09
### Fixed
- new custom image with various UI fixes

## [11.0.0-bb.2] - 2021-06-08
### Changed
- remove configuration from deploying by default
- DoD CA certs no longer loaded by default
- refactor how ENV variables are configured in the values.yaml
- document recommended way to configure

## [11.0.0-bb.1] - 2021-05-26
### Added
- Added additional network policies to be controlled through the bigbang chart

## [11.0.0-bb.0] - 2021-05-14
### Added
- initial realase with app version 13.0.0 helm chart version 11.0.0
```


### Vault

- [!3267](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3267): vault update to 0.25.0-bb.4
- [!3250](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3250): vault update to 0.25.0-bb.3

```markdown
# Changelog Updates

## [0.25.0-bb.4] - 2023-10-11
### Updated
- Updated OSCAL version from 1.0.0 to 1.1.1

## [0.25.0-bb.3] - 2023-10-03
### Changed
- Added resiliency to auto unseal job
```


### Harbor

- [!3255](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3255): harbor update to 1.12.4-bb.3

```markdown
# Changelog Updates

## [1.12.4-bb.3] - 2023-10-06
### Changed
- image order in the Chart.yaml to fix bug with exporter image not showing in images package
```


## Known Issues

- [Kyverno Policies Issue 43](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies/-/issues/43): "Injected pods with 'istio-init' containers violate require-non-root-group policy" syntax is no longer valid with new chart versions, we are working to get this updated for 2.13.0.

- [Velero Issue 1740](https://repo1.dso.mil/big-bang/bigbang/-/issues/1740): "BB 2.11.x contains an undocumented breaking change for velero schedules" Please see issue link for details and workaround.



## Helpful Links

As always, we welcome and appreciate feedback from our community of users. Please feel free to:

- [Open issues here](https://repo1.dso.mil/platform-one/big-bang/umbrella/-/issues/new?issue%5Bassignee_id%5D=&issue%5Bmilestone_id%5D=)
- [Join our chat](https://chat.il2.dso.mil/platform-one/channels/team---big-bang)
- Check out the [documentation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs) for guidance on how to get started

## Future

Don't see your feature and/or bug fix? Check out our [epics](https://repo1.dso.mil/groups/platform-one/big-bang/-/epic_boards/7) for estimates on when you can expect things to drop, and as always, feel free to comment or create issues if you have questions, comments, or concerns.