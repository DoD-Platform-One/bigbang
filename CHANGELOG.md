# Big Bang Release Notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.0]

### Upgrade Notice

This update includes updated `EnvoyFilters` for `authservice` to fix #65 and is a component of a future upgrade to istio 1.8 (#191).

__After upgrading BigBang to this version, you must follow the steps below to ensure apps protected by `authservice` are still protected.__

In order to ensure sso for all services protected by `authservice` remain functional (`kiali`, `jaeger`, `prometheus`, and `alertmanager`), the `istio-proxy` sidecar attached to the `haproxy` infront of the services must be updated to `1.7.7`.

The easiest way to do this is to cycle the pod:

```bash
kubectl delete po -n authservice -l app.kubernetes.io/instance=authservice-haproxy-sso
```

> __Note__: these 4 services (`kiali`, `jaeger`, `prometheus`, and `alertmanager`) will be unavailable for ~10s while the pod cycles. In the future we aim to provide an HA implementation of authservice's haproxy so the above operations can happen without downtime.

* [!300](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/300): Velero Addon Addition
* [!308](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/308): BigBang values migrated to Secret objects parsed by `HelmRelease` objects within chart. (also fixes #221)
* [!357](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/357): Updated Anchore (Engine 0.9.3, Enterprise 3.0.2).
* [!333](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/333): Updated Mattermost (Operator: 1.13.0, Instance: 5.32.1).
* [!346](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/346): Redis Integration with Anchore Enterprise Package.
* [!318](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/318): Redis Integration with ArgoCD Package.

## [1.3.0]

* [!322](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/322): Updated anchore to 0.9.2, enterprise 3.0.1, this also fixes #135
* [!309](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/309): Add support for Gitlab CAC signed commits and custom CAs
* [!311](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/311): Update minio to `RELEASE.2020-11-19T23-48-16Z` and expose more user configuration options
* [!220](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/220): Added consolidatedflux installation (without `flux` cli)
* [!319](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/319): Updated gitlab-runner to `13.9.0` IronBank image (note this uses a different chart schema than previous versions, see [here](https://docs.gitlab.com/runner/install/kubernetes.html#additional-configuration) for more information)
* [!340](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/340): Package `bigbang` repo in `repositories.tar.gz` release artifact
  
In addition, [Big Bang Pre-requisites](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/1.4.0/docs/d_prerequisites.md) has been added as a location to store all (known) pre-requisites for running BigBang on various distributions.  Over time, more distributions will be added as they are tested, community (and vendor) contributions are welcomed!

## [1.2.0]

* [!270](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/270): upgrade to flux 0.7.x, this requires updating flux and fixes #13
* [!250](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/250): Filename spelling correction in scripts directory
* [!259](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/259), [!265](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/265), [!274](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/274): documentation updates
* [!263](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/263), [!271](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/271): Update codeowners
* [!263](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/263): add missing enterprise Anchore images to airgap bundle
* [!237](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/237): add gitlab-runner to test values
* [!266](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/266): update fluentbit package version
* [!269](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/269): Update charter/PackageOwner.md
* [!256](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/256): update developer documentation
* [!272](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/272): Remove CI jobs that check for things no longer required as part of the developer workflow
* [!264](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/264), [!238](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/238): Update BigBang repo url references from "umbrella" to "bigbang"
* [!249](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/249): image for gatekeeper is set in the chart and should not be hardcoded in the HelmRelease
* [!202](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/202): add initial support for openshift (ocp)
* [!272](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/272): upgrade argocd helm chart to 2.14.7-bb.0
* [!232](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/232): Twistlock IB image and VirtualServcie customization
* [!210](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/210): only run cluster tests when chart contents have changed
* [!279](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/279): remove hardcoded ArgoCD server url config, allow users to set their own sso url
* [!215](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/215): add sample sso values
* [!286](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/286): add Ironbank defender image to synker config
* [!287](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/287): add gitlab runner images to synker config
* [!288](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/288): split minio into minio operator and minio and move to addons
* [!255](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/255): Integrate Mattermost Operator as an addon
* [!273](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/273): Integrate Mattermost as an addon
* [!291](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/291): enable MinIO in CI tests
* [!290](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/290): upgrade Mattermost chart version. Uses latest IronBank image

## [1.1.0]

* [&2](https://repo1.dso.mil/groups/platform-one/big-bang/-/epics/2): Add support for Gitlab (with sso) 13.8.0
* [&3](https://repo1.dso.mil/groups/platform-one/big-bang/-/epics/3): Add support for Gitlab Runners 13.2.2
* [&7](https://repo1.dso.mil/groups/platform-one/big-bang/-/epics/7): Add support for SonarQube (with sso) 8.6
* [&15](https://repo1.dso.mil/groups/platform-one/big-bang/-/epics/15): Add support for Anchore (with sso) 0.8.1
* [#129](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/129): Updated FluentBit to 1.6.3
* [#63](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/63): Fix bug with elasticsearch failing to start due to invalid file permissions
* [#49](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/49): Add consistent labels to authservice deployment
* [#32](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/32): Add support for PodAntiAffinity and NodeAffinity for elasticsearch deployments
* [#6](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/6): Add support for new elasticsearch cluster node types
* [#16](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/16): Fix bug with incorrect git credentials being created when specifying a private repository
* [#66](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/66): Fix bug with EnvoyFilter being applied in the wrong non-global namespace
* [#99](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/99): Fix bug that allowed for incorrect ImagePullSecrets to be created when providing incomplete credentials

## [1.0.8]

* Added support for deployment of Minio operator and instance deployment of minio.    

## [1.0.7]

* Added Kubernetes labels to all objects created by umbrella
* Add OIDC integration for Grafana
* Allow creation of wildcard cert for istio ingress to be passed to BigBang chart

## [1.0.6]

* Added [HAProxy Addon](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/haproxy)
* Added support for automatically populating configs and settings for the following placing SSO in front of apps without support:
```
istio:
  sso:
    enabled: true
    prometheus:
      client_id:
      client_secret:
    alertmanager:
      client_id:
      client_secret:

monitoring:
  sso:
    enabled: true
    kiali:
      client_id:
      client_secret:
    jaeger:
      client_id:
      client_secret:
```
* Added authservice namespace where authservice addon and haproxy deployment will be created.
* Added global sso options for umbrella which will be applied to all configured authservice chains:
```
sso:
  oidc:
    host: login.dso.mil
    realm: baby-yoda
  certificate_authority: ''
  jwks: ""
  client_id: ""
  client_secret: ""
```
* Updated syntax for authservice chains definition.

## [1.0.5]

* Bumped monitoring chart to consume kiwigrid/sidecar from IronBank

## [1.0.4]

* Bug fix where argocd's VirtualService wouldn't recieve the top level hostname value.

## [1.0.3]

* Added [Gitlab](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab)
* Added ability to provide multiple registry credentials while maintaining current capabilities:

```
registryCredentials:
  username: registry1user
  password: somesecretpassword
```

or
```
registryCredentials:
- registry: registry1.dso.mil
  username: registry1user
  password: somesecretpassword
- registry: registry.dsop.io
  username: registry1user
  password: somesecretpassword
- registry: somewhere.else.io
  username: someuser
  password: someothersecret
```
will correctly create the ImagePullSecrets for all those registries


## [1.0.2]

### Changed

* Updated istio-controlplane to [1.7.3-bb.5](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane/-/tags/1.7.3-bb.5) to allow
for setting ingressgateway to use nodeports

## [1.0.1]


### Changed

* Updated Istio Control plane to support Node Ports for ingressGateway
* Update Istio Control plane to support SSO for Kiali and Jaeger
* Update Authservice to refact definitions of filter chains
* Updated documentation

---

## [0.0.4] - 2020-12-16

### Changed

* Update Monitoring to [11.0.0-bb.2](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring/-/tags/11.0.0-bb.2)

---

## [0.0.3] - 2020-12-15

### Added

* Documentation in [docs](./docs)

### Changed

* Updated Argo to [2.9.5-bb.1](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd/-/merge_requests/10) for Iron Bank images
* Updated Authservice to [0.1.3-bb.0](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice/-/blob/master/CHANGELOG.md#013-bb0) for authservice secret generation: https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice/-/blob/master/CHANGELOG.md#013-bb0
* Updated ECK-Operator to [1.3.1-bb.1](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator/-/tags/1.3.0-bb.1)
* Updated Twistlock to [0.0.2-bb.0](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock/-/tags/0.0.2-bb.0) to add istio.enabled flag
* Updated Elasticsearch Kibana to [0.1.2-bb.0](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana/-/tags/0.1.2-bb.0) and Pass istio.enabled to Elasticsearch Kibana

---

## [0.0.2] - 2020-12-11

### Added

* Initial release of Big Bang

---
