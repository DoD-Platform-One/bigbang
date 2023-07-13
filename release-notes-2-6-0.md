# Release Notes - 2.6.0

Please see our [documentation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/2.6.0) page for more information on how to consume and deploy BigBang. This release was primarily tested on Kubernetes 1.26.3 (RKE2).

## Upgrade Notices

> Add any upgrade notices from the release issue here. You may also want to
> reach out to package maintainers for anything that looks like a major change.
> Changelog diffs for packages are included below in the `## Changes in 2.6.0`
> which may be helpful to identify "major chanes".

### **Upgrades from previous releases**

If coming from a version pre-`2.5.0`, note the additional upgrade notices in any release in between. The BB team doesn't test/guarantee upgrades from anything pre-`2.5.0`.

## Packages

| Package                                                                                                                                                           | Type   | Package Version                                                | BB Version                          |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|----------------------------------------------------------------|-------------------------------------|
| [Istio Controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane)                                                                          | Core   | Istio `1.17.3` Tetrate Istio Distro `1.17.3`                   | `1.17.3-bb.1`                       |
| [Istio Operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator)                                                                                  | Core   | Istio Operator `1.17.3` Tetrate Istio Distro Operator `1.17.3` | `1.17.3-bb.0`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Jaeger](https://repo1.dso.mil/big-bang/product/packages/jaeger)                 | Core   | `1.46.0`                                                       | `2.46.0-bb.0` [🔗](#jaeger)         |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali)                   | Core   | `1.68.0`                                                       | `1.68.0-bb.1` [🔗](#kiali)          |
| [Cluster Auditor](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor)                                                                                | Core   | `0.0.7`                                                        | `1.5.0-bb.4`                        |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy)             | Core   | `3.12.0`                                                       | `3.12.0-bb.4` [🔗](#gatekeeper)     |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno)               | Core   | `1.9.2`                                                        | `2.7.2-bb.0` [🔗](#kyverno)         |
| [Kyverno Policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies)                                                                              | Core   | `1.1.0`                                                        | `1.1.0-bb.7`                        |
| [Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter)                                                                              | Core   | `2.10.4`                                                       | `2.16.0-bb.1`                       |
| [Elasticsearch Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana)                                                                      | Core   | Kibana `8.7.1` Elasticsearch `8.7.0`                           | `1.3.1-bb.0`                        |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Eck Operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator)     | Core   | `2.8.0`                                                        | `2.8.0-bb.0` [🔗](#eck-operator)    |
| [Fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit)                                                                                            | Core   | `2.1.4`                                                        | `0.30.4-bb.0`                       |
| [Promtail](https://repo1.dso.mil/big-bang/product/packages/promtail)                                                                                              | Core   | `2.8.2`                                                        | `6.11.3-bb.0`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Loki](https://repo1.dso.mil/big-bang/product/packages/loki)                     | Core   | `2.8.2`                                                        | `5.8.9-bb.0` [🔗](#loki)            |
| [Neuvector](https://repo1.dso.mil/big-bang/product/packages/neuvector) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square)                        | Core   | `5.1.3`                                                        | `2.4.5-bb.0`                        |
| [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo)                                                                                                    | Core   | Tempo `2.1.1` Tempo Query `2.1.1`                              | `1.2.0-bb.2`                        |
| [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring)                                                                                          | Core   | Prometheus `2.43.1` Grafana `9.5.1` Alertmanager `0.25.0`      | `45.27.2-bb.4`                      |
| [Twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock)                                                                                            | Core   | `22.12.415`                                                    | `0.12.0-bb.3`                       |
| [Wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper)                                                                                                | Core   | N / A                                                          | `0.4.1`                             |
| [Argocd](https://repo1.dso.mil/big-bang/product/packages/argocd)                                                                                                  | Addon  | `2.7.4`                                                        | `5.36.1-bb.0`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice)       | Addon  | `0.5.3`                                                        | `0.5.3-bb.11` [🔗](#authservice)    |
| [Minio Operator](https://repo1.dso.mil/big-bang/product/packages/minio-operator)                                                                                  | Addon  | `5.0.5`                                                        | `5.0.5-bb.0`                        |
| [Minio](https://repo1.dso.mil/big-bang/product/packages/minio)                                                                                                    | Addon  | `RELEASE.2023-06-19T19-52-50Z`                                 | `5.0.5-bb.0`                        |
| [Gitlab](https://repo1.dso.mil/big-bang/product/packages/gitlab)                                                                                                  | Addon  | `16.0.4`                                                       | `7.0.4-bb.0`                        |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Gitlab Runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner)   | Addon  | `15.11.0`                                                      | `0.52.0-bb.0` [🔗](#gitlab-runner)  |
| [Nexus](https://repo1.dso.mil/big-bang/product/packages/nexus)                                                                                                    | Addon  | `3.53.1-02`                                                    | `53.1.0-bb.1`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube)           | Addon  | `9.9.1-community`                                              | `8.0.1-bb.2` [🔗](#sonarqube)       |
| [Haproxy](https://repo1.dso.mil/big-bang/product/packages/haproxy)                                                                                                | Addon  | `2.2.21`                                                       | `1.12.0-bb.0`                       |
| [Anchore Enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise)                                                                          | Addon  | Enterprise `4.6.0` Engine `1.1.0`                              | `1.24.1-bb.5`                       |
| [Mattermost Operator](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator)                                                                        | Addon  | `1.20.1`                                                       | `1.20.1-bb.0`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Mattermost](https://repo1.dso.mil/big-bang/product/packages/mattermost)         | Addon  | `7.10.3`                                                       | `7.10.3-bb.1` [🔗](#mattermost)     |
| [Velero](https://repo1.dso.mil/big-bang/product/packages/velero)                                                                                                  | Addon  | `1.10.2`                                                       | `3.1.5-bb.2`                        |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak)             | Addon  | `21.1.1`                                                       | `18.4.3-bb.1` [🔗](#keycloak)       |
| [Vault](https://repo1.dso.mil/big-bang/product/packages/vault)                                                                                                    | Addon  | `1.13.1`                                                       | `0.24.1-bb.1`                       |
| ![Updated](https://img.shields.io/badge/Updated-informational?style=flat-square) [Metrics Server](https://repo1.dso.mil/big-bang/product/packages/metrics-server) | Addon  | `0.6.3`                                                        | `3.10.0-bb.0` [🔗](#metrics-server) |

## Changes in 2.6.0

### Big Bang MRs

> Parsing this MR list programatically has no guarantee to be accurate
> due to the nonstandard format of labeling our MRs.
> 
> Because of this, you will have to break out this list manually,
> and move each MR under the package it belongs to / deals with.
> Leave any non-package specific MRs here.

- [!2921](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2921): eckOperator update to 2.8.0-bb.0
- [!2750](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2750): kyverno update to 2.7.2-bb.0
- [!2908](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2908): authservice update to 0.5.3-bb.11
- [!2894](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2894): Resolve "Document how to contribute to package OSCAL documents"
- [!2907](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2907): loki update to 5.8.9-bb.0
- [!2875](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2875): Add OIDC CA ConfigMap to Kiali when using custom SSO CA
- [!2900](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2900): monitoring update to 47.1.0-bb.0
- [!2890](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2890): gatekeeper update to 3.12.0-bb.4
- [!2899](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2899): jaeger update to 2.46.0-bb.0
- [!2898](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2898): Upping flux-system resource values for BB
- [!2896](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2896): authservice update to 0.5.3-bb.10
- [!2895](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2895): gitlabRunner update to 0.52.0-bb.0
- [!2889](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2889): keycloak update to 18.4.3-bb.1
- [!2884](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2884): mattermost update to 7.10.3-bb.0
- [!2877](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2877): mattermost update to 7.10.2-bb.2
- [!2885](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2885): sonarqube update to 8.0.1-bb.2


### Jaeger

```markdown
# Changelog Updates

## [2.46.0-bb.0] - 2023-06-30
### Updated
- Upgrade chart to 2.46.0
- Upgrade images to 1.46.0
```


### Kiali

```markdown
# Changelog Updates

## [1.68.0-bb.1] - 2023-06-30
### Added
- Added `oidcCaCert` value to enable a custom CA cert from an OIDC IdP.
```


### Gatekeeper

```markdown
# Changelog Updates

## [3.12.0-bb.4] - 2023-06-20
### Changed
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.26.4 -> v1.27.3
- Updated to latest gluon 0.3.2 -> 0.4.0

## [3.12.0-bb.0] - 2023-04-18
### Changed
- Updated ironbank/opensource/openpolicyagent/gatekeeper v3.11.0 -> v3.12.0.
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.26.3 -> v1.26.4
- Updated registry1.dso.mil/ironbank/opensource/openpolicyagent/gatekeeper v3.11.0 -> v3.12.0

## [3.11.0-bb.3] - 2023-04-07
### Changed
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.26.2 -> v1.26.3

## [3.11.0-bb.2] - 2023-03-09
### Changed
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.26.1 -> v1.26.2
- Updated to latest gluon 0.3.2

## [3.11.0-bb.1] - 2023-02-23
### Changed
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.25.6 -> v1.26.1

## [3.11.1-bb.0]
### Changed
- Updated ironbank/opensource/openpolicyagent/gatekeeper v3.10.0 -> v3.11.0.
- Updated registry1.dso.mil/ironbank/opensource/kubernetes/kubectl v1.25.4 -> v1.25.6
- Updated registry1.dso.mil/ironbank/opensource/openpolicyagent/gatekeeper v3.10.0 -> v3.11.0

## [3.10.0-bb.2]
### Changed
- Updated to work on OpenShift out of the box

## [3.10.0-bb.1]
### Changed
- Updated to latest kubectl v1.25.4

## [3.10.0-bb.0]
### Changed
- Updated to latest kubectl v1.25.3
- Updated to latest gatekeeper v3.10.0
- Updated chart to v3.10.0

## [3.9.0-bb.3]
### Changed
- Updated to latest kubectl v1.25.2
- Updated to latest gluon 0.3.1

## [3.9.0-bb.2]
### Changed
- Updated to latest kubectl v1.24.4
- Updated to latest gluon 0.3.0

## [3.9.0-bb.1]
### Changed
- Remove old Ingress API's

## [3.9.0-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.9.0

## [3.8.1-bb.5] - 2022-07-25
### Changed
- Removed `ProcMount` from Helm test to avoid conflicts with `PodSecurityPolicy` in some K8S distributions

## [3.8.1-bb.4] - 2022-07-22
### Changed
- Fixed PodDisruptionBudget to default to the `v1` API when neither `v1` or `v1beta1` are found.  This should prevent it from being flagged as deprecated.

## [3.8.1-bb.3]
### Changed
- Add Openshift SCCs

## [3.8.1-bb.2]
### Changed
- Re-disabled PSP due to issues fixed in RKE2

## [3.8.1-bb.1]
### Changed
- Updated to latest gluon 0.2.10

## [3.8.1-bb.0]
### Changed
- Updated to latest IB image 3.8.1
- Updated to latest gluon 0.2.9

## [3.8.0-bb.1]
### Changed
- Added OSCAL component file

## [3.8.0-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.8.0

## [3.7.1-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.7.1

## [3.7.0-bb.9]
### Changed
- Updated kubectl images to 1.22.2
- Updated renovate to monitor all images including `kubectl` test and crd images

## [3.7.0-bb.8]
### Changed
- Updated kubectl image

## [3.7.0-bb.7]
### Changed
- Reenabled PSP due to issues on RKE2

## [3.7.0-bb.6]
### Changed
- Disabled PSP due to deprecation warning

## [3.7.0-bb.5]
### Fixed
- Update Chart.yaml to follow new standardization for release automation
- Added renovate check to update new standardization

## [3.7.0-bb.4]
### Fixed
- Missing emptyDir in PSP, copied from upstream fix: https://github.com/open-policy-agent/gatekeeper/commit/ae9e7dd1c8c5a23e748f0893468abe18218fa357

## [3.7.0-bb.3]
### Changed
- Relocated bbtest values

## [3.7.0-bb.2]
### Changed
- Refactoring helm tests

## [3.7.0-bb.1]
### Fixed
- Fixed missing kpt updates from 3.7.0 upgrade

## [3.7.0-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.7.0
- Updated kubectl image

## [3.6.0-bb.2]
### Changed
- Enable OPA to log denies by default

## [3.6.0-bb.1]
### Changed
- Set validatingWebhookTimeoutSeconds to 15 seconds.

## [3.6.0-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.6.0

## [3.5.2-bb.2]
### Added
- ConstraintTemplate CRD v1 version. Storage set to false.

## [3.5.2-bb.1]
### Changed
- Updated upgrade job to remove orphan or disabled constraints.

## [3.5.2-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.5.2

## [3.5.1-bb.16]
### Changed
- Changed resource limits and requirements for manager pods

## [3.5.1-bb.15]
### Changed
- Changed names of several Constraint Templates to workaround upgrade problem when changing CRD schema

## [3.5.1-bb.14]
### Changed
- Fixed problems with K8sPSPHostNetworkingPorts template
- Added fine grained control of excluded resources using namespace and resource name
- Added chart label to controller to force reroll on chart upgrades
- Renamed constraint template `K8sRequiredPod` to `K8sQualityOfService` and removed deprecated violations

### Removed
- Deprecated constraint templates removed

## [3.5.1-bb.13]
### Changed
- Updated Post-upgrade job to use imagePullSecrets

## [3.5.1-bb.12]
### Changed
- Removed Big Bang overrides from default values.  Look in Big Bang repo under `chart/templates/gatekeeper/values.yaml` for overrides.

## [3.5.1-bb.11]
### Added
- Post-upgrade job to remove disabled constraints

### Changed
- Moved constraint kind and name to values.yaml

## [3.5.1-bb.10]
### Changed
- Removed rule for `unique-service-selector`

## [3.5.1-bb.9]
### Changed
- Changed the resource requests and limits to be equal

## [3.5.1-bb.8]
### Changed
- Excluded kube-system from all constraints through config
- Reverted values to no longer include kube-system as excluded

## [3.5.1-bb.7]
### Changed
- Set batch mode default to process 500 entries to reduce memory footprint
- Turned on match kind only to reduce memory footprint
- Increased audit interval to every 5 minutes

## [3.5.1-bb.6]
### Changed
- Updated constraint `no-host-namespace` enforcement to default deny
- Removed monitoring namespace exception for constraint `host-networking`

## [3.5.1-bb.5]
### Changed
- Remove duplicate keys in Chart.yaml

## [3.5.1-bb.4]
### Changed
- Updated constraint `https-only` enforcement to default deny

## [3.5.1-bb.3]
### Changed
- Updated constraint `volume-types` enforcement to default deny

## [3.5.1-bb.2]
### Changed
- Updated constraint `allowed-docker-registries` enforcement to default deny
- Excluded kube-system namespace for constraint `allowed-docker-registries`

## [3.5.1-bb.1]
### Changed
- Updated constraint `restrictedTaint` enforcement to default deny, added exception for `monitoring` namespace for to allow prometheus-node-exporter pods

## [3.5.1-bb.0]
### Changed
- Updated application and corresponding helm chart to v3.5.1

## [3.4.0-bb.19]
### Changed
- Disabled `app-armor-profiles` constraint by default

## [3.4.0-bb.18]
### Changed
- Align Cluster Auditor default constraint values to Kubernetes Pod Security Standard

## [3.4.0-bb.17]
### Changed
- Updated constraint `selinux-policy` enforcement to default deny
- added exception for logging namespace to selinux policy

## [3.4.0-bb.16]
### Changed
- Updated constraint `unique-ingress-hosts` enforcement to default deny

## [3.4.0-bb.15]
### Changed
- Updated constraint `host-networking` enforcement to default deny
- added exemption for monitoring namespace, this will prevent the `K8sPSPHostNetworkingPorts` from reporting a violation on monitoring namespace.

## [3.4.0-bb.14]
### Changed
- Updated constraint `no-privileged-containers` enforcement to default deny
- added exception for logging namespace to no-privileged-containers constraint

## [3.4.0-bb.13]
### Changed
- Updated constraint `banned-image-tags` enforcement to default deny
- added violation to constraintTemplate `k8sbannedimagetags` to not allow containers with no specified tag

## [3.4.0-bb.12]
### Changed
- Changed nosysctls policy to deny

## [3.4.0-bb.11]
### Changed
- Reverted constraint `pods-have-istio` enforcement to default dryrun
- Fixed podsHaveIstio disallowed regex sidecar.istio.io/inject to false and exclude istio-system namespace

## [3.4.0-bb.10]
### Changed
- Remove flexVolume and hostPath as default allowable for allowedFlexVolume constraint

## [3.4.0-bb.9]
### Changed
- Updated constraint  `pods-have-istio` enforcement to default deny

## [3.4.0-bb.8]
### Modified
- Modified the default enforcement action of allowed-flex-volumes to deny

## [3.4.0-bb.7]
### Added
- Added network policies to lock down egress/ingress

### Changed
- Move tests from bb-test-lib to gluon

## [3.4.0-bb.6]
### Modified
- Modified the default enforcement action of allowProcMount to deny.

## [3.4.0-bb.5]
### Changed
- Changed allowed-ips constraint to deny

## [3.4.0-bb.4]
### Changed
- Changed names of all constraints so that during upgrade, cluster-auditor will not delete them.

## [3.4.0-bb.3]
### Changed
- Updated CI values to only include 'default' namespace for deny actions

## [3.4.0-bb.2]
### Added
- `K8sDenySADefault` constraint template.
- `K8sDenySADefault` constraint
- Added `ServiceAccount` for good pod testing

### Changed
- Removed `K8sDenyServiceAccountTokentAutoMount` constraint template
- Updated test script to account for added SA.

## [3.4.0-bb.1]
### Added
- Constraints were moved from cluster-auditor to OPA gatekeeper package

### Changed
- Constraint template library split into individual files
- Constraints renamed to match values.yaml
- Constraint Templates renamed to match kind

## [3.4.0-bb.0]
### Added
- Common labels on Big Bang created components

### Changed
- Updated helm chart to upstream v3.4.0, which included the following notable items:
- Update docs/ConstraintTemplates list with latest templates

## [3.3.0-bb.5]
### Changed
- Remove constraint templates K8sRequiredDeploymentLabels & K8sRequiredIronBankImages.
- The constraint templates are replaced with K8sRequiredLabelValues & K8sAllowedRepos

## [3.3.0-bb.4]
### Fixed
- Typo in K8sDenyServiceNodePort message
- Typo in K8sNoAnnotationValues message
- Missing "service" in gatekeeper config

## [3.3.0-bb.3]
### Changed
- More Constraint Templates

## [3.3.0-bb.2]
### Changed
- Added Constraint Templates

## [3.3.0-bb.1]
### Changed
- Added helm test

## [3.3.0-bb.0]
### Changed
- Added changelog
- update chart and image to v3.3.0
```


### Kyverno

```markdown
# Changelog Updates

## [2.7.2-bb.0] - 2023-04-17
### Changed
- Updated to latest image 1.9.2
- Updated to latest chart 2.7.2
```


### Eck Operator

```markdown
# Changelog Updates

## [2.8.0-bb.0]
### Changed
- Updated chart and IB images from 2.7.0 to 2.8.0
```


### Loki

```markdown
# Changelog Updates

## [5.8.9-bb.0] - 2023-07-05
### Changed
- Updated to latest upstream chart 5.8.9
```


### Authservice

```markdown
# Changelog Updates

## [0.5.3-bb.11]
### Changed
- Allow for passing templates inside templates for chains prefixes and callback uris.

## [0.5.3-bb.10]
### Changed
- Added `sso-tls-ca` volume mount to the deployment to enable JWKS URI usage even if the OIDC IdP uses a custom CA.
```


### Gitlab Runner

```markdown
# Changelog Updates

## [0.52.0-bb.0] - 2023-06-30
### Changed
- Update images to 15.11.0
- Update chart to 0.52.0 base
```


### Sonarqube

```markdown
# Changelog Updates

## [8.0.1-bb.2] - 2023-06-26
### Changed
- Set volumepermissions.enabled to false
- Update change-admin-password-hook and postgresql to run as non root user
```


### Mattermost

```markdown
# Changelog Updates

## [7.10.3-bb.1] - 2023-06-30
### Changed
- update securityContext for podExtension to run as non-root

## [7.10.3-bb.0] - 2023-06-20
### Changed
- ironbank/opensource/mattermost/mattermost updated from 7.10.2 to 7.10.3
- minio-instance updated from 4.5.8-bb.0 to 5.0.4-bb.1
- mc updated from RELEASE.2022-08-23T05-45-20Z to RELEASE.2023-06-23T18-12-07Z

## [7.10.2-bb.2] - 2023-06-15
### Changed
- Modified securityContext for minio-bucket-creation job to run as non root user/group
```


### Keycloak

```markdown
# Changelog Updates

## [18.4.3-bb.1] - 2023-06-27
### Updated
- Added support for LDAP egress
```


### Metrics Server

```markdown
# Changelog Updates

## [3.10.0-bb.0]
### Added
- Update patch version of kubectl v1.26.4 -> v1.27.3
- Updated helm chart version and upstream changes.
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