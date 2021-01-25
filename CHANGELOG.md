# Big Bang Release Notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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

* Update Monitoring to [11.0.0-bb.2](https://repo1.dsop.io/platform-one/big-bang/apps/core/monitoring/-/tags/11.0.0-bb.2)

---

## [0.0.3] - 2020-12-15

### Added

* Documentation in [docs](./docs)

### Changed

* Updated Argo to [2.9.5-bb.1](https://repo1.dsop.io/platform-one/big-bang/apps/core/argocd/-/merge_requests/10) for Iron Bank images
* Updated Authservice to [0.1.3-bb.0](https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/authservice/-/blob/master/CHANGELOG.md#013-bb0) for authservice secret generation: https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/authservice/-/blob/master/CHANGELOG.md#013-bb0
* Updated ECK-Operator to [1.3.1-bb.1](https://repo1.dsop.io/platform-one/big-bang/apps/core/eck-operator/-/tags/1.3.0-bb.1)
* Updated Twistlock to [0.0.2-bb.0](https://repo1.dsop.io/platform-one/big-bang/apps/security-tools/twistlock/-/tags/0.0.2-bb.0) to add istio.enabled flag
* Updated Elasticsearch Kibana to [0.1.2-bb.0](https://repo1.dsop.io/platform-one/big-bang/apps/core/elasticsearch-kibana/-/tags/0.1.2-bb.0) and Pass istio.enabled to Elasticsearch Kibana

---

## [0.0.2] - 2020-12-11

### Added

* Initial release of Big Bang

---
