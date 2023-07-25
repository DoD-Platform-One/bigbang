# Release Notes - 2.7.0

Please see our [documentation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/2.7.0) page for more information on how to consume and deploy BigBang. This release was primarily tested on Kubernetes 1.26.3 (RKE2).

## Upgrade Notices

> Add any upgrade notices from the release issue here. You may also want to
> reach out to package maintainers for anything that looks like a major change.
> Changelog diffs for packages are included below in the `## Changes in 2.7.0`
> which may be helpful to identify "major chanes".

### **Upgrades from previous releases**

If coming from a version pre-`2.6.0`, note the additional upgrade notices in any release in between. The BB team doesn't test/guarantee upgrades from anything pre-`2.6.0`.

## Packages

| Package                                                                                                                                                                                                                | Type   | Package Version                                                | BB Version                              |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|----------------------------------------------------------------|-----------------------------------------|
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Istio Controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane)                                              | Core   | Istio `1.17.3` Tetrate Istio Distro `1.17.3`                   | `1.17.3-bb.3` [🔗](#istio-controlplane) |
| [Istio Operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator)                                                                                                                                       | Core   | Istio Operator `1.17.3` Tetrate Istio Distro Operator `1.17.3` | `1.17.3-bb.0`                           |
| [Jaeger](https://repo1.dso.mil/big-bang/product/packages/jaeger)                                                                                                                                                       | Core   | `1.46.0`                                                       | `2.46.0-bb.0`                           |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali)                                                                        | Core   | `1.70.0`                                                       | `1.70.0-bb.0` [🔗](#kiali)              |
| [Cluster Auditor](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor)                                                                                                                                     | Core   | `0.0.7`                                                        | `1.5.0-bb.4`                            |
| [Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy)                                                                                                                                                   | Core   | `3.12.0`                                                       | `3.12.0-bb.4`                           |
| [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno)                                                                                                                                                     | Core   | `1.9.2`                                                        | `2.7.2-bb.0`                            |
| [Kyverno Policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies)                                                                                                                                   | Core   | `1.1.0`                                                        | `1.1.0-bb.7`                            |
| [Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter)                                                                                                                                   | Core   | `2.10.4`                                                       | `2.16.0-bb.1`                           |
| [Elasticsearch Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana)                                                                                                                           | Core   | Kibana `8.7.1` Elasticsearch `8.7.0`                           | `1.3.1-bb.0`                            |
| [Eck Operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator)                                                                                                                                           | Core   | `2.8.0`                                                        | `2.8.0-bb.0`                            |
| [Fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit)                                                                                                                                                 | Core   | `2.1.4`                                                        | `0.30.4-bb.0`                           |
| [Promtail](https://repo1.dso.mil/big-bang/product/packages/promtail)                                                                                                                                                   | Core   | `2.8.2`                                                        | `6.11.3-bb.0`                           |
| [Loki](https://repo1.dso.mil/big-bang/product/packages/loki)                                                                                                                                                           | Core   | `2.8.2`                                                        | `5.8.9-bb.0`                            |
| [Neuvector](https://repo1.dso.mil/big-bang/product/packages/neuvector)                                                                                                                                                 | Core   | `5.1.3`                                                        | `2.4.5-bb.0`                            |
| [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo)                                                                                                                                                         | Core   | Tempo `2.1.1` Tempo Query `2.1.1`                              | `1.2.0-bb.2`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring)                                                              | Core   | Prometheus `2.45.0` Grafana `10.0.1` Alertmanager `0.25.0`     | `47.1.0-bb.1` [🔗](#monitoring)         |
| ![New](https://img.shields.io/badge/New-informational?style=flat-square) [Grafana](https://repo1.dso.mil/big-bang/apps/sandbox/grafana)                                                                                | Core   | N / A                                                          | `6.57.4-bb.0`                           |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock)                                                                | Core   | `22.12.415`                                                    | `0.12.0-bb.4` [🔗](#twistlock)          |
| [Wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper)                                                                                                                                                     | Core   | N / A                                                          | `0.4.1`                                 |
| [Argocd](https://repo1.dso.mil/big-bang/product/packages/argocd)                                                                                                                                                       | Addon  | `2.7.4`                                                        | `5.36.1-bb.0`                           |
| [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice)                                                                                                                                             | Addon  | `0.5.3`                                                        | `0.5.3-bb.11`                           |
| [Minio Operator](https://repo1.dso.mil/big-bang/product/packages/minio-operator)                                                                                                                                       | Addon  | `5.0.5`                                                        | `5.0.5-bb.0`                            |
| [Minio](https://repo1.dso.mil/big-bang/product/packages/minio)                                                                                                                                                         | Addon  | `RELEASE.2023-06-19T19-52-50Z`                                 | `5.0.5-bb.0`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gitlab](https://repo1.dso.mil/big-bang/product/packages/gitlab)                                                                      | Addon  | `16.1.2`                                                       | `7.1.2-bb.0` [🔗](#gitlab)              |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gitlab Runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner)                                                        | Addon  | `15.11.0`                                                      | `0.52.0-bb.1` [🔗](#gitlab-runner)      |
| [Nexus](https://repo1.dso.mil/big-bang/product/packages/nexus)                                                                                                                                                         | Addon  | `3.53.1-02`                                                    | `53.1.0-bb.1`                           |
| [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube)                                                                                                                                                 | Addon  | `9.9.1-community`                                              | `8.0.1-bb.2`                            |
| [Haproxy](https://repo1.dso.mil/big-bang/product/packages/haproxy)                                                                                                                                                     | Addon  | `2.2.21`                                                       | `1.12.0-bb.0`                           |
| [Anchore Enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise)                                                                                                                               | Addon  | Enterprise `4.6.0` Engine `1.1.0`                              | `1.24.1-bb.5`                           |
| [Mattermost Operator](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator)                                                                                                                             | Addon  | `1.20.1`                                                       | `1.20.1-bb.0`                           |
| [Mattermost](https://repo1.dso.mil/big-bang/product/packages/mattermost)                                                                                                                                               | Addon  | `7.10.3`                                                       | `7.10.3-bb.1`                           |
| [Velero](https://repo1.dso.mil/big-bang/product/packages/velero)                                                                                                                                                       | Addon  | `1.10.2`                                                       | `3.1.5-bb.2`                            |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak)                                                                  | Addon  | `21.1.1`                                                       | `18.4.3-bb.2` [🔗](#keycloak)           |
| [Vault](https://repo1.dso.mil/big-bang/product/packages/vault)                                                                                                                                                         | Addon  | `1.13.1`                                                       | `0.24.1-bb.1`                           |
| [Metrics Server](https://repo1.dso.mil/big-bang/product/packages/metrics-server)                                                                                                                                       | Addon  | `0.6.3`                                                        | `3.10.0-bb.0`                           |
| ![New](https://img.shields.io/badge/New-informational?style=flat-square) [Harbor](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/harbor) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | Addon  | `2.8.2`                                                        | `1.12.2-bb.5`                           |

## Changes in 2.7.0

### Big Bang MRs

> Parsing this MR list programatically has no guarantee to be accurate
> due to the nonstandard format of labeling our MRs.
> 
> Because of this, you will have to break out this list manually,
> and move each MR under the package it belongs to / deals with.
> Leave any non-package specific MRs here.

- [!2852](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2852): Allow seamless sidecar cycling for enterprise Istio switch
- [!2940](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2940): gitlabRunner update to 0.52.0-bb.1
- [!2939](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2939): Resolve "Add Harbor Charts to BB main repo"
- [!2937](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2937): gitlab update to 7.1.2-bb.0
- [!2691](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2691): Update Flux
- [!2929](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2929): New monitoring and separate grafana 2 electric boogaloo
- [!2932](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2932): istio update to 1.17.3-bb.3
- [!2931](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2931): Resolve "Add Link to Report a Cyber Security Concern to contributing.md"
- [!2926](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2926): kiali update to 1.70.0-bb.0
- [!2900](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2900): monitoring update to 47.1.0-bb.0
- [!2909](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2909): Allow user to run install_flux.sh with a prompted password
- [!2876](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2876): DEBUG twistlock update to 0.12.0-bb.4
- [!2922](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2922): istio update to 1.17.3-bb.2
- [!2906](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2906): mattermost update to 7.10.3-bb.1


### Istio Controlplane

```markdown
# Changelog Updates

## [1.17.3-bb.3] - 2023-07-12
### Added
- Allow user to specify their own `EnvoyFilters`

## [1.17.3-bb.2] - 2023-07-12
### Changed
- fix README.md for bb docs compiler job
```


### Kiali

```markdown
# Changelog Updates

## [1.70.0-bb.0] - 2023-07-12
### Added
- Updated to 1.70.0 images (latest in IB)
```


### Monitoring

```markdown
# Changelog Updates

## [47.1.0-bb.1] - 2023-07-21
### Changed
- grafana disabled by default

### Removed
- Grafana related BigBang templates

## [47.1.0-bb.0] - 2023-06-27
### Added
- registry1.dso.mil/ironbank/big-bang/grafana/grafana-plugins major 9.5.1 -> 9.5.3
- registry1.dso.mil/ironbank/kiwigrid/k8s-sidecar minor 1.23.3 -> 1.24.4
- registry1.dso.mil/ironbank/opensource/kubernetes/kubectl minor v1.26.4 -> 1.27.3
- registry1.dso.mil/ironbank/opensource/prometheus-operator/prometheus-config-reloader minor v0.65.1 -> v0.66.0
- registry1.dso.mil/ironbank/opensource/prometheus-operator/prometheus-operator minor v0.65.1 -> v0.66.0
- registry1.dso.mil/ironbank/opensource/prometheus-operator/prometheus-operato minor 0.65.1 -> v0.66.0
- registry1.dso.mil/ironbank/opensource/prometheus/node-exporter minor v1.5.0 -> v1.6.0
- registry1.dso.mil/ironbank/opensource/prometheus/prometheus minor v2.42.0 -> v2.45.0
- registry1.dso.mil/ironbank/opensource/prometheus/prometheus minor v2.43.1 -> v2.45.0
- registry1.dso.mil/ironbank/opensource/thanos/thanos minor v0.30.2 -> v0.31.0
- registry1.dso.mil/ironbank/redhat/ubi/ubi8-minimal minor 8.7 -> 8.8
```


### Twistlock

```markdown
# Changelog Updates

## [0.12.0-bb.4] - 2023-06-22
### Changed
- Updated gluon from 0.3.2 -> 0.4.0
- # [0.12.0-bb.3] - 2023-06-20
- Changed chart/values.yaml to nest serviceMonitor under monitoring
- # [0.12.0-bb.2] - 2023-05-31
- Changed chart/Chart.yaml condition
- # [0.12.0-bb.1] - 2023-05-11
- ironbank/twistlock/console/console updated from 22.06.197 to 22.12.415
- ironbank/twistlock/defender/defender updated from 22.06.197 to 22.12.415

### Added
- Added TLDR documentation for Container Models
- # [0.12.0-bb.0] - 2023-02-17

## [0.11.4-bb.3] - 2023-02-09
### Changed
- Add init job resources values and templating

## [0.11.4-bb.2] - 2022-01-17
### Changed
- Update gluon to new registry1 location + latest version (0.3.2)

## [0.11.4-bb.1] - 2022-12-05
### Fixed
- Quote value for privileged for stringData

### Added
- Add docs for WAAS

## [0.11.4-bb.0] - 2022-11-17
### Added
- Added Grafana dasboards

## [0.11.3-bb.2] - 2022-10-20
### Changed
- Modified volume job to add retries on chown + exit with error properly

## [0.11.3-bb.1] - 2022-10-14
### Added
- Added drop security context capability to defender and console

## [0.11.3-bb.0] - 2022-10-12
### Added
- Configurable trusted image policy via init job

## [0.11.2-bb.0] - 2022-10-06
### Fixed
- Added affinity for volume upgrade job
- Set job to run by default
- Add resources for volume job, modify wait logic to handle edge cases with unhealthy console

## [0.11.1-bb.0] - 2022-10-02
### Changed
- increase Mem for console to 2gb

## [0.11.0-bb.0] - 2022-09-27
### Added
- Set Twistlock console to run as nonroot
- Added upgrade option for those with local volumes through the volume-upgrade-job

## [0.10.0-bb.2] - 2022-09-22
### Added
- Enable mTLS for Twistlock metrics
- Updated Gluon to `0.3.1`

## [0.10.0-bb.1] - 2022-09-02
### Added
- Add support for SAML SSO via init script

## [0.10.0-bb.0] - 2022-08-26
### Changed
- Updated console and defender to `22.06.197`

## [0.9.1-bb.0] - 2022-09-01
### Added
- Conditional PrometheusRule template for Defender count alerts fulfilled by the monitoring stack

## [0.9.0-bb.4] - 2022-08-15
### Fixed
- Update Defender's daemonSet to support/add tolerations

## [0.9.0-bb.3] - 2022-06-30
### Fixed
- Fixed handling of metrics/servicemonitor + creation of user for metrics
- Adjust job TTL to 30 minutes to provide time for viewing debug logging

## [0.9.0-bb.2] - 2022-07-04
### Updated
- Make Twistlock more customization via values.yaml

## [0.9.0-bb.1] - 2022-06-28
### Updated
- Updated bb base image to 2.0.0
- Updated gluon to 0.2.10

## [0.9.0-bb.0] - 2022-06-16
### Updated
- Updated to 22.06.179 (console and defender)
- Updated to latest gluon library + latest base image

## [0.8.0-bb.0] - 2022-06-10
### Added
- Added oscal-component.yaml

## [0.7.0-bb.0] - 2022-05-05
### Added
- Added initialization job to setup users, license, defenders, policies, and other misc settings

### Changed
- Refactored names and labels to use _helpers.tpl
- Added labels to all resources

## [0.6.0-bb.0] - 2022-05-03
### Changed
- Updated twistlock image to 22.01.880

## [0.5.0-bb.0] - 2022-03-24
### Added
- Added Tempo Zipkin Egress Policy

## [0.4.0-bb.1] - 2022-02-28
### Added
- Added mTLS PeerAuthentication
- Added mTLS exception for defenders

## [0.4.0-bb.0] - 2022-01-31
### Changed
- Updated to 22.01.840 image versions
- Added documentation for running on k3d

## [0.3.0-bb.0] - 2022-01-31
### Changed
- Update Chart.yaml to follow new standardization for release automation
- Added renovate check to update new standardization

## [0.2.0-bb.0] - 2022-01-18
### Changed
- Relocated bbtests from `test-values.yaml` to `values.yaml`

## [0.1.0-bb.0] - 2021-12-14
### Added
- Add annotations to console deployment

## [0.0.12-bb.0] - 2021-11-22
### Changed
- Rename hostname to domain

## [0.0.11-bb.0] - 2021-10-27
### Changed
- Add image pull policy for the console

## [0.0.10-bb.0] - 2021-10-27
### Changed
- Updated console to version `21.08.520`
- Updated renovate.json for defender image + appVersion

### Added
- `tests/images.txt` for package release CI
- New network policy to allow for egress to twistlock upstream services

## [0.0.9-bb.1] - 2021-10-18
### Changed
- VS API version to v1beta1 to solve deprecation
- @micah.nagel added to CODEOWNERS, @joshwolf removed

## [0.0.9-bb.0] - 2021-09-10
### Added
- Documentation link to PCC default configuration for version 21.04.412
- Network Policy template specifically for Defenders communication
- networkPolicies.nodeCidr value to explicity set ingress CIDR for Defender WebSocket connections

## [0.0.8-bb.1] - 2021-08-26
### Added
- Added istio sidecar scraping network policy

## [0.0.8-bb.0] - 2021-08-16
### Added
- Upgrade twistlock console  to version 21.04.439

## [0.0.7-bb.0] - 2021-08-09
### Added
- Add conditional syslog audit integration for twistlock console.

## [0.0.6-bb.2] - 2021-08-06
### Added
- Add Resource limit and request.

## [0.0.6-bb.1] - 2021-07-21
### Added
- Add openshift toggle. If it's set, add port 5353 egress rule.

## [0.0.6-bb.0] - 2021-06-09
### Fixed
- Bug with istio network policy, allow egress in ns

## [0.0.5-bb.0] - 2021-06-02
### Changed
- Network policy resource Templates

## [0.0.4-bb.3] - 2021-06-01
### Added
- Gluon test library dependency

### Changed
- CI Test infrastructure. Migrating to helm tests with script capabilities.

## [0.0.4-bb.2] - 2021-05-26
### Added
- Network policy resource Templates

## [0.0.4-bb.0] - 2021-05-12
### Added
- Moved all resources into `chart/templates/console/`
- Updated twistlock to 21.04.412

## [0.0.3-bb.4] - 2021-04-06
### Added
- Resource and Toleration Values

## [0.0.3-bb.3] - 2021-04-05
### Changed
- Affinity values modified to standardize

## [0.0.3-bb.2] - 2021-03-31
### Added
- Values passthroughs for affinity and anti-affinity added

### Changed
- Split out resources into separate yaml files

## [0.0.3-bb.0] - 2021-02-12
### Added
- Options under istio values to control labels, annotations, gateways and full URL modification for twistlock VirtualService.

### Changed
- Position of "hostname" value in values, from "console.hostname" to toplevel "hostname".

## [0.0.2-bb.2] - 2021-02-11
### Added
- imagePullSecret array to values.

### Changed
- Image based on 20.12 version from IronBank.

## [0.0.2-bb.1] - 2021-01-27
### Changed
- Updating all "dsop.io" URLs to "dso.mil".

## [0.0.2-bb.0] - 2020-12-15
### Added
- Istio flag to enable VirtualService when true.

## [0.0.1-bb.0] - 2020-06-15
### Added
- Initial manifests for deploying Twistlock version 20.04.196.
```


### Gitlab

```markdown
# Changelog Updates

## [7.1.2-bb.0] - 2023-07-20
### Changed
- ironbank/gitlab/gitlab/gitlab-webservice  16.0.4 -> 16.1.2
- registry1.dso.mil/ironbank/bitnami/analytics/redis-exporter  v1.50.0 -> v1.51.0
- registry1.dso.mil/ironbank/gitlab/gitlab/certificates  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitaly  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-container-registry  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-exporter  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-mailroom  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-pages  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-shell  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-sidekiq  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-toolbox  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-webservice  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-webservice  v16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-workhorse  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/gitlab/gitlab/kubectl  16.0.3 -> 16.1.2
- registry1.dso.mil/ironbank/opensource/postgres/postgresql  14.8 -> 15.3
```


### Gitlab Runner

```markdown
# Changelog Updates

## [0.52.0-bb.1] - 2023-07-25
### Removed
- Removed name element on both submit buttons for cypress test 03, 04 and 05
```


### Keycloak

```markdown
# Changelog Updates

## [18.4.3-bb.2] - 2022-06-29
### Updated
- Update bitnami/postgresql version 15.2.0 -> 15.3.0
- Update postgresql-exporter version to 0.12.0 -> 0.12.1
- Update postgresql12 version to 12.14 -> 12.15
- Update gluon version 0.3.2 -> 0.4.0
- Update uib8-micro version 8.7 -> 8.8
```


## Known Issues

Gitlab 16 transition requires manual updates before deployment. Ensure that all blockers and breaking changes (located above in the patch notes) are addressed prior to release.




## Helpful Links

As always, we welcome and appreciate feedback from our community of users. Please feel free to:

- [Open issues here](https://repo1.dso.mil/platform-one/big-bang/umbrella/-/issues/new?issue%5Bassignee_id%5D=&issue%5Bmilestone_id%5D=)
- [Join our chat](https://chat.il2.dso.mil/platform-one/channels/team---big-bang)
- Check out the [documentation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs) for guidance on how to get started

## Future

Don't see your feature and/or bug fix? Check out our [epics](https://repo1.dso.mil/groups/platform-one/big-bang/-/epic_boards/7) for estimates on when you can expect things to drop, and as always, feel free to comment or create issues if you have questions, comments, or concerns.