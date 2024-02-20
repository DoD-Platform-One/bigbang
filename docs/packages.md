# Packages

#### Columns

1. Monitoring: `Metrics scraping with Prometheus and dedicated Grafana Dashboards/PrometheusRule alerts as appropriate`
2. Tracing: `Tempo or Jaeger connections for tracing application traffic`
3. Network Policies: `Network Policies for restricting network connectivity`
4. mTLS: `Istio Injected, with either a Strict or Permissive Mutual TLS Mode`

#### Values

1. N/A: `Feature doesn't exist`
2. No: `Feature exists, Not Implemented in Big Bang`
3. Yes: `Feature exists, Implemented in Big Bang`

## Core

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Istio Operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator) |  ![Istio Operator Build](https://repo1.dso.mil/big-bang/product/packages/istio-operator/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/641) | Yes |
| [Istio Controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane) |  ![Istio Controlplane Build](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/632) | Yes |
| [Jaeger](https://repo1.dso.mil/big-bang/product/packages/jaeger) |  ![Jaeger Build](https://repo1.dso.mil/big-bang/product/packages/jaeger/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/602) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1295) |
| [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali) |  ![Kiali Build](https://repo1.dso.mil/big-bang/product/packages/kiali/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/589) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1296) |
| [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring) |  ![Monitoring Build](https://repo1.dso.mil/big-bang/product/packages/monitoring/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/509) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1900) |
| [Grafana](https://repo1.dso.mil/big-bang/product/packages/grafana) |  ![Grafana Build](https://repo1.dso.mil/big-bang/product/packages/grafana/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2929) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2929) |
| [NeuVector](https://repo1.dso.mil/big-bang/product/packages/neuvector) |  ![NeuVector Build](https://repo1.dso.mil/big-bang/product/packages/neuvector/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2486) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/neuvector/-/blob/main/chart/templates/bigbang/peerauthentication/peerauthentication/peer-authentication.yaml) |
| [Twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock) |  ![Twistlock Build](https://repo1.dso.mil/big-bang/product/packages/twistlock/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/498) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1396) |
| [ECK Operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator) |  ![ECK Operator Build](https://repo1.dso.mil/big-bang/product/packages/eck-operator/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/510) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1236) |
| [Elasticsearch Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana) |  ![EK Operator Build](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/527) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1537) |
| [Fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit) |  ![Fluentbit Build](https://repo1.dso.mil/big-bang/product/packages/fluentbit/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/555/) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1537) |
| [OPA Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy) |  ![OPA Build](https://repo1.dso.mil/big-bang/product/packages/policy/badges/main/pipeline.svg) | No | N/A | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/626) | N/A |
| [Cluster Auditor](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor) |  ![Cluster Auditor Build](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/565) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1370) |
| [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno/badges/main/pipeline.svg) | Yes | N/A | [Yes](https://repo1.dso.mil/big-bang/product/packages/kyverno/-/merge_requests/2) | N/A |
| [Kyverno Policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies/badges/main/pipeline.svg) | N/A | N/A | Yes \* | N/A |
| [Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter) |  ![Kyverno Build](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/-/merge_requests/1) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/-/merge_requests/1) |
| [Promtail](https://repo1.dso.mil/big-bang/product/packages/promtail) |  ![Promtail Build](https://repo1.dso.mil/big-bang/product/packages/promtail/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1342) | Yes | [Yes](https://repo1.dso.mil/big-bang/product/packages/promtail/-/merge_requests/14) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1516) |
| [Loki](https://repo1.dso.mil/big-bang/product/packages/loki) |  ![Loki Build](https://repo1.dso.mil/big-bang/product/packages/loki/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/8) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/15) | [Yes](https://repo1.dso.mil/big-bang/product/packages/loki/-/merge_requests/1) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1516) |
| [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo) |  ![Tempo Build](https://repo1.dso.mil/big-bang/product/packages/tempo/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/product/packages/tempo/-/merge_requests/2) | [Yes](https://repo1.dso.mil/big-bang/product/packages/tempo/-/merge_requests/3) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1253) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1762) |

> `*` inherited from Kyverno when installed in the same namespace.

# Supported Add-Ons

## Security

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak) |  ![Keycloak Build](https://repo1.dso.mil/big-bang/product/packages/keycloak/badges/main/pipeline.svg) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/issues/291) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/issues/1204) | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/536) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1945) |
| [Anchore Enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise) |  ![Anchore Build](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/505) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1594) |
| [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice) |  ![Authservice Build](https://repo1.dso.mil/big-bang/product/packages/authservice/badges/main/pipeline.svg) | Yes | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/511) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1329) |
| [Vault](https://repo1.dso.mil/big-bang/product/packages/vault) |  ![Vault Build](https://repo1.dso.mil/big-bang/product/packages/vault/badges/main/pipeline.svg) | Yes | Yes | Yes | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1781) |

## Development Tools

| Package | Status | Monitoring | Tracing | Network Policies | mTLS |
|----|----|----|----|----|----|
| [Gitlab](https://repo1.dso.mil/big-bang/product/packages/gitlab) |  ![Gitlab Build](https://repo1.dso.mil/big-bang/product/packages/gitlab/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/504) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1724) |
| [Gitlab Runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner) |  ![Gitlab Runner Build](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner/badges/main/pipeline.svg) | Yes | Yes \* | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/522) \* | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1724) \* |
| [Nexus](https://repo1.dso.mil/big-bang/product/packages/nexus) |  ![Nexus](https://repo1.dso.mil/big-bang/product/packages/nexus/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/544) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1605) |
| [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube) |  ![Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube/badges/main/pipeline.svg) | N/A | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/503) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/1508) |
| [Harbor](https://repo1.dso.mil/big-bang/product/packages/harbor) |  ![Harbor](https://repo1.dso.mil/big-bang/product/packages/harbor/badges/main/pipeline.svg) | Yes | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2939) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/2939) |
| [Fortify](https://repo1.dso.mil/big-bang/product/packages/fortify) |  ![Fortify](https://repo1.dso.mil/big-bang/product/packages/fortify/badges/main/pipeline.svg) | No | Yes | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3027) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3027) |
| [Holocron](https://repo1.dso.mil/big-bang/product/packages/holocron) | ![Holocron](https://repo1.dso.mil/big-bang/product/packages/holocron/badges/main/pipeline.svg) | No | No | [Yes](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3726) | [Yes (STRICT)](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/3726) |

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

