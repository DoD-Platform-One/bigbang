# Big Bang Release Notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
