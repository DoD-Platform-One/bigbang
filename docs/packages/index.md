# Packages

#### Columns

1. Monitoring: `Metrics scraping with Prometheus and dedicated Grafana Dashboards/PrometheusRule alerts as appropriate`
2. Tracing: `Tempo connections for tracing application traffic`
3. Network Policies: `Network Policies for restricting network connectivity`
4. mTLS: `Istio Injected, with either a Strict or Permissive Mutual TLS Mode`

#### Values

1. N/A: `Feature doesn't exist`
2. No: `Feature exists, Not Implemented in Big Bang`
3. Yes: `Feature exists, Implemented in Big Bang`

## Core

Core packages are included in the Big Bang umbrella chart and configured outside the `addons` key in `values.yaml`.

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Istio CRDs](https://repo1.dso.mil/big-bang/product/packages/istio-crds) |  ![Istio CRDs Build](https://repo1.dso.mil/big-bang/product/packages/istio-crds/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/4906) | Yes |
| [Istio Daemon](https://repo1.dso.mil/big-bang/product/packages/istiod) |  ![Istio Core Build](https://repo1.dso.mil/big-bang/product/packages/istiod/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/4906) | Yes |
| [Istio Gateway](https://repo1.dso.mil/big-bang/product/packages/istio-gateway) |  ![Istio Gateway Build](https://repo1.dso.mil/big-bang/product/packages/istio-gateway/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/4906) | Yes |
| [Istio CNI](https://repo1.dso.mil/big-bang/product/packages/istio-cni) | ![Istio CNI Build](https://repo1.dso.mil/big-bang/product/packages/istio-cni/badges/main/pipeline.svg) | N/A | N/A | N/A | N/A |
| [Gateway API](https://repo1.dso.mil/big-bang/product/packages/gateway-api) | ![Gateway API Build](https://repo1.dso.mil/big-bang/product/packages/gateway-api/badges/main/pipeline.svg) | N/A | N/A | N/A | N/A |
| [ztunnel](https://repo1.dso.mil/big-bang/product/packages/ztunnel) | ![ztunnel Build](https://repo1.dso.mil/big-bang/product/packages/ztunnel/badges/main/pipeline.svg) | N/A | N/A | Yes | N/A |
| [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali) |  ![Kiali Build](https://repo1.dso.mil/big-bang/product/packages/kiali/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/589) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1296) |
| [Prometheus Operator CRDs](https://repo1.dso.mil/big-bang/product/packages/prometheus-operator-crds) | ![Prometheus Operator CRDs Build](https://repo1.dso.mil/big-bang/product/packages/prometheus-operator-crds/badges/main/pipeline.svg) | N/A | N/A | N/A | N/A |
| [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring) |  ![Monitoring Build](https://repo1.dso.mil/big-bang/product/packages/monitoring/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/509) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1900) |
| [Grafana](https://repo1.dso.mil/big-bang/product/packages/grafana) |  ![Grafana Build](https://repo1.dso.mil/big-bang/product/packages/grafana/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2929) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2929) |
| [NeuVector](https://repo1.dso.mil/big-bang/product/packages/neuvector) |  ![NeuVector Build](https://repo1.dso.mil/big-bang/product/packages/neuvector/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2486) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/neuvector/-/blob/main/chart/templates/bigbang/peerauthentication/peerauthentication/peer-authentication.yaml) |
| [Twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock) |  ![Twistlock Build](https://repo1.dso.mil/big-bang/product/packages/twistlock/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/498) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1396) |
| [ECK Operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator) |  ![ECK Operator Build](https://repo1.dso.mil/big-bang/product/packages/eck-operator/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/510) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1236) |
| [Elasticsearch Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana) |  ![EK Operator Build](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/527) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1537) |
| [Fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit) |  ![Fluentbit Build](https://repo1.dso.mil/big-bang/product/packages/fluentbit/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/555/) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1537) |
| [OPA Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy) |  ![OPA Build](https://repo1.dso.mil/big-bang/product/packages/policy/badges/main/pipeline.svg) | No | N/A | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/626) | N/A |
| [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno/badges/main/pipeline.svg) | Yes | N/A | [Yes](https://repo1.dso.mil/big-bang/product/packages/kyverno/-/merge_requests/2) | N/A |
| [Kyverno Policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies/badges/main/pipeline.svg) | N/A | N/A | Yes \* | N/A |
| [Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/-/merge_requests/1) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/-/merge_requests/1) |
| [Alloy](https://repo1.dso.mil/big-bang/product/packages/alloy) | ![Alloy Build](https://repo1.dso.mil/big-bang/product/packages/alloy/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/product/packages/alloy/-/merge_requests/38) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/alloy/-/merge_requests/30) |
| [Loki](https://repo1.dso.mil/big-bang/product/packages/loki) |  ![Loki Build](https://repo1.dso.mil/big-bang/product/packages/loki/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/8) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/15) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/1) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1516) |
| [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo) |  ![Tempo Build](https://repo1.dso.mil/big-bang/product/packages/tempo/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/product/packages/tempo/-/merge_requests/2) | [Yes](https://repo1.dso.mil/big-bang/product/packages/tempo/-/merge_requests/3) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1253) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1762) |
| [Renovate](https://repo1.dso.mil/big-bang/product/packages/renovate) |  ![Renovate Build](https://repo1.dso.mil/big-bang/product/packages/renovate/badges/main/pipeline.svg) | No | No | [Yes](https://repo1.dso.mil/big-bang/product/packages/renovate/-/blob/main/chart/values.yaml?ref_type=heads#L305) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/renovate/-/blob/main/chart/values.yaml?ref_type=heads#L295) |
| [bbctl](https://repo1.dso.mil/big-bang/product/packages/bbctl) | ![bbctl Build](https://repo1.dso.mil/big-bang/product/packages/bbctl/badges/main/pipeline.svg) | No | No | No | N/A |

> `*` inherited from Kyverno when installed in the same namespace.

# Supported Add-Ons

## Security

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak) |  ![Keycloak Build](https://repo1.dso.mil/big-bang/product/packages/keycloak/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/issues/291) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/issues/1204) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/536) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1945) |
| [Anchore Enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise) |  ![Anchore Build](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/505) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1594) |
| [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice) |  ![Authservice Build](https://repo1.dso.mil/big-bang/product/packages/authservice/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/511) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1329) |
| [Vault](https://repo1.dso.mil/big-bang/product/packages/vault) |  ![Vault Build](https://repo1.dso.mil/big-bang/product/packages/vault/badges/main/pipeline.svg) | Yes | Yes | Yes | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1781) |
| [External Secrets Operator](https://repo1.dso.mil/big-bang/product/packages/external-secrets) |  ![External Secrets Operator Build](https://repo1.dso.mil/big-bang/product/packages/vault/badges/main/pipeline.svg) | Yes | No | Yes | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/external-secrets/-/blob/main/chart/values.yaml?ref_type=heads#L580) |

## Development Tools

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Gitlab](https://repo1.dso.mil/big-bang/product/packages/gitlab) |  ![Gitlab Build](https://repo1.dso.mil/big-bang/product/packages/gitlab/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/504) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1724) |
| [Gitlab Runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner) |  ![Gitlab Runner Build](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner/badges/main/pipeline.svg) | Yes | Yes \* | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/522) \* | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1724) \* |
| [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube) |  ![Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube/badges/main/pipeline.svg) | N/A | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/503) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1508) |
| [Harbor](https://repo1.dso.mil/big-bang/product/packages/harbor) |  ![Harbor](https://repo1.dso.mil/big-bang/product/packages/harbor/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2939) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2939) |
| [Fortify](https://repo1.dso.mil/big-bang/product/packages/fortify) |  ![Fortify](https://repo1.dso.mil/big-bang/product/packages/fortify/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3027) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3027) |

> `*` inherited from Gitlab when installed in the same namespace.

## Collaboration Tools

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Mattermost](https://repo1.dso.mil/big-bang/product/packages/mattermost) |  ![Mattermost Build](https://repo1.dso.mil/big-bang/product/packages/mattermost/badges/main/pipeline.svg) | Yes \* | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/515) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2800) |
| [Mattermost Operator](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator) |  ![Mattermost Operator Build](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator/badges/main/pipeline.svg) | No | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/499) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1531) |

> `*` Monitoring/metrics are only available for enterprise (licensed) deployments of Mattermost

## Application Utilities

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [MinIO](https://repo1.dso.mil/big-bang/product/packages/minio) |  ![MinIO Build](https://repo1.dso.mil/big-bang/product/packages/minio/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/550) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1566) |
| [MinIO Operator](https://repo1.dso.mil/big-bang/product/packages/minio-operator) |  ![MinIO Operator Build](https://repo1.dso.mil/big-bang/product/packages/minio-operator/badges/main/pipeline.svg) | [N/A](https://repo1.dso.mil/big-bang/product/packages/minio-operator/-/blob/main/docs/prometheus.md) | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/685) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1554) |

## Cluster Utilities

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Argocd](https://repo1.dso.mil/big-bang/product/packages/argocd) |  ![Argo Build](https://repo1.dso.mil/big-bang/product/packages/argocd/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/572) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1368) |
| [Velero](https://repo1.dso.mil/big-bang/product/packages/velero) |  ![Velero Build](https://repo1.dso.mil/big-bang/product/packages/velero/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/552) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1451) |
| [Metrics Server](https://repo1.dso.mil/big-bang/product/packages/metrics-server) |  ![Metrics Server Build](https://repo1.dso.mil/big-bang/product/packages/metrics-server/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1738) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1968) |
| [Thanos](https://repo1.dso.mil/big-bang/product/packages/thanos) |  ![Thanos Build](https://repo1.dso.mil/big-bang/product/packages/thanos/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3113) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3113) |
| [Mimir](https://repo1.dso.mil/big-bang/product/packages/mimir) |  ![Mimir Build](https://repo1.dso.mil/big-bang/product/packages/mimir/badges/main/pipeline.svg) | No | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/5378) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/mimir/-/blob/main/chart/values.yaml?ref_type=heads#L213) |
| [Headlamp](https://repo1.dso.mil/big-bang/product/packages/headlamp) | ![Headlamp Build](https://repo1.dso.mil/big-bang/product/packages/headlamp/badges/main/pipeline.svg) | Yes | Yes | Yes | Yes (STRICT) |

# Supporting Repositories

The following active repositories are hosted in the [`product/packages`](https://repo1.dso.mil/groups/big-bang/product/packages) subgroup but provide shared package libraries and tooling rather than standalone deployable packages.

| Repository | Status | Purpose |
|----|----|----|
| [bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common) | ![bb-common Build](https://repo1.dso.mil/big-bang/product/packages/bb-common/badges/main/pipeline.svg) | Common Helm library chart for Big Bang packages |
| [Gluon](https://repo1.dso.mil/big-bang/product/packages/gluon) | ![Gluon Build](https://repo1.dso.mil/big-bang/product/packages/gluon/badges/master/pipeline.svg) | Shared automation and tooling for Big Bang packages |
| [wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper) | ![wrapper Build](https://repo1.dso.mil/big-bang/product/packages/wrapper/badges/main/pipeline.svg) | Wrapper chart for deploying arbitrary big bang packages with big bang capabilities |

# Maintained Packages

[Maintained packages](https://repo1.dso.mil/groups/big-bang/product/maintained) are owned and updated by the Big Bang team and tested in their package pipelines, but are not included in the Big Bang umbrella chart. They can be deployed alongside umbrella packages with the [`packages` key](../installation/environments/extra-package-deployment.md) in `values.yaml`. Support is limited to the package running in isolation and does not cover its interactions with other packages, networking issues, or other emergent integration issues.

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [cert-manager](https://repo1.dso.mil/big-bang/product/maintained/cert-manager) | ![cert-manager Build](https://repo1.dso.mil/big-bang/product/maintained/cert-manager/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [cert-manager-approver-policy](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-approver-policy) | ![cert-manager-approver-policy Build](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-approver-policy/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [cert-manager-trust-manager](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager) | ![cert-manager-trust-manager Build](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [Confluence](https://repo1.dso.mil/big-bang/product/maintained/confluence) | ![Confluence Build](https://repo1.dso.mil/big-bang/product/maintained/confluence/badges/main/pipeline.svg) | Yes | Yes | Yes | Yes (STRICT) |
| [Fluentd](https://repo1.dso.mil/big-bang/product/maintained/fluentd) | ![Fluentd Build](https://repo1.dso.mil/big-bang/product/maintained/fluentd/badges/main/pipeline.svg) | Yes | Yes | Yes | Yes (STRICT) |
| [Garage](https://repo1.dso.mil/big-bang/product/maintained/garage) | ![Garage Build](https://repo1.dso.mil/big-bang/product/maintained/garage/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [GitLab CI Pipelines Exporter](https://repo1.dso.mil/big-bang/product/maintained/gitlab-ci-pipelines-exporter) | ![GitLab CI Pipelines Exporter Build](https://repo1.dso.mil/big-bang/product/maintained/gitlab-ci-pipelines-exporter/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [Jira](https://repo1.dso.mil/big-bang/product/maintained/jira) | ![Jira Build](https://repo1.dso.mil/big-bang/product/maintained/jira/badges/main/pipeline.svg) | Yes | No | Yes | No |
| [Karpenter](https://repo1.dso.mil/big-bang/product/maintained/karpenter) | ![Karpenter Build](https://repo1.dso.mil/big-bang/product/maintained/karpenter/badges/main/pipeline.svg) | Yes | No | No | No |
| [Nexus Repository High Availability](https://repo1.dso.mil/big-bang/product/maintained/nxrm-ha) | ![Nexus Repository High Availability Build](https://repo1.dso.mil/big-bang/product/maintained/nxrm-ha/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [Podinfo](https://repo1.dso.mil/big-bang/product/maintained/podinfo) | ![Podinfo Build](https://repo1.dso.mil/big-bang/product/maintained/podinfo/badges/main/pipeline.svg) | Yes | No | Yes | Yes (STRICT) |
| [Redis](https://repo1.dso.mil/big-bang/product/maintained/redis) | ![Redis Build](https://repo1.dso.mil/big-bang/product/maintained/redis/badges/main/pipeline.svg) | Yes | Yes | Yes | Yes (STRICT) |

# Community Packages

[Community packages](https://repo1.dso.mil/groups/big-bang/product/community) are not maintained by Platform One engineering teams. They are owned and maintained by members of the community, and Platform One does not provide updates or support for them. Community repositories that do not receive commits or updates for one year will be archived.

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [coder-provisioner](https://repo1.dso.mil/big-bang/product/community/coder-provisioner) | ![coder-provisioner Build](https://repo1.dso.mil/big-bang/product/community/coder-provisioner/badges/main/pipeline.svg) | Yes | No | No | No |
| [coder-v2](https://repo1.dso.mil/big-bang/product/community/coder-v2) | ![coder-v2 Build](https://repo1.dso.mil/big-bang/product/community/coder-v2/badges/main/pipeline.svg) | No | No | No | No |
| [Crossplane](https://repo1.dso.mil/big-bang/product/community/crossplane) | ![Crossplane Build](https://repo1.dso.mil/big-bang/product/community/crossplane/badges/main/pipeline.svg) | No | No | Yes | Yes (STRICT) |
| [Jaeger](https://repo1.dso.mil/big-bang/product/community/jaeger) | ![Jaeger Build](https://repo1.dso.mil/big-bang/product/community/jaeger/badges/main/pipeline.svg) | Yes | Yes | Yes | Yes (STRICT) |
| [JFrog Platform](https://repo1.dso.mil/big-bang/product/community/jfrog-platform) | ![JFrog Platform Build](https://repo1.dso.mil/big-bang/product/community/jfrog-platform/badges/main/pipeline.svg) | No | No | No | No |
| [Nexus IQ](https://repo1.dso.mil/big-bang/product/community/nexus-iq) | ![Nexus IQ Build](https://repo1.dso.mil/big-bang/product/community/nexus-iq/badges/main/pipeline.svg) | No | No | No | No |
| [Parabol](https://repo1.dso.mil/big-bang/product/community/parabol) | ![Parabol Build](https://repo1.dso.mil/big-bang/product/community/parabol/badges/main/pipeline.svg) | Yes | Yes | No | No |
| [RapidFort](https://repo1.dso.mil/big-bang/product/community/rapidfort) | ![RapidFort Build](https://repo1.dso.mil/big-bang/product/community/rapidfort/badges/main/pipeline.svg) | No | No | Yes | Yes (STRICT) |
| [SD Elements](https://repo1.dso.mil/big-bang/product/community/sdelements) | ![SD Elements Build](https://repo1.dso.mil/big-bang/product/community/sdelements/badges/main/pipeline.svg) | No | No | Yes | No |
