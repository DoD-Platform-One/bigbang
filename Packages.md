# Packages

Columns:
* Logging - fluentbit configurations for standardized logging
* Telemetry - Integration with Prometheus and dedicated Grafana dashboards as appropriate
* Tracing - Insertion of Tracing data for application traffic
* Network Policies - Network Policies for L2 connectivity,
* mTLS -mTLS for application traffic, e.g. implemented by Istio
* Behavior Detection - Twistlock Policies for applications

## Core

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Istio Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator) |  ![Istio Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/641) | Yes | No |
| [Istio Controlplane](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane) | ![Istio Controlplane Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/632) | Yes | No |
| [Jaeger](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger) | ![Jaeger Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/602) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1295) | No |
| [Kiali](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali) | ![Kiali Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/589) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1296) | No |
| [Monitoring](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring) | ![Monitoring Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/509) | Yes (PERMISSIVE) | No |
| [Twistlock](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock) |  ![Twistlock Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/498) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1396) | No |
| [ECK Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator) | ![ECK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator/badges/main/pipeline.svg) |  No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/510) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1236) | No |
| [Elasticsearch Kibana](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana) |![EK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/527) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1537) | No |
| [Fluentbit](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit) | ![Fluentbit Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/555/) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1537) | No |
| [OPA Gatekeeper](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy) | ![OPA Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/626) | No | No |
| [Cluster Auditor](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor) | ![Cluster Auditor Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/565) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1370) | No |
| [Kyverno](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno) | ![Kyverno Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |
| [Kyverno Policies](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno-policies) | ![Kyverno Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno-policies/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |
| [Promtail](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/promtail) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Promtail Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/promtail/badges/main/pipeline.svg) |  No | No | No | Yes | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1516) | No |
| [Loki](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/loki) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Loki Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/loki/badges/main/pipeline.svg) |  No | No | No | Yes | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1516) | No |
| [Tempo](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Tempo Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1253) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1762) | No |
<!-- | [NeuVector](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/neuvector) ![ALPHA](https://img.shields.io/badge/ALPHA-red?style=flat-square) | ![NeuVector Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/neuvector/badges/main/pipeline.svg) | No | No | No | No | No | No | -->

## Supported Add-Ons

### Security

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Keycloak](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak) |  ![Keycloak Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/536) | Yes (PERMISSIVE) | No |
| [Anchore Enterprise](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise) | ![Anchore Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/505) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1594) | No |
| [Authservice](https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice) | ![Authservice Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/511) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1329) | No |
| [Vault](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Vault Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault/badges/main/pipeline.svg) |  No | No | No | Yes | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1781) | No |

### Development Tools

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Gitlab](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab)  | ![Gitlab Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/504) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1724) | No |
| [Gitlab Runner](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner) |  ![Gitlab Runner Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/522) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1724)* | No |
| [Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus) |  ![Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/544) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1605) | No |
| [Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube) |  ![Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/503) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1508) | No |

> *Gitlab Runner inherits mTLS STRICT from Gitlab when installed in the same namespace.

### Collaboration Tools

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Mattermost](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost)  | ![Mattermost Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/515) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/623) | No |
| [Mattermost Operator](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator) |  ![Mattermost Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/499) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1531) | No |

### Application Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [MinIO](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio)  | ![MinIO Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/550) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1566) | No |
| [MinIO Operator](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator) |  ![MinIO Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/685)] | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1554) |No |

### Cluster Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Argocd](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd) |![Argo Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd/badges/main/pipeline.svg)  |  No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/572) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1368) | No |
| [Velero](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero)  | ![Velero Build](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/552) | [Yes (STRICT)](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1451) | No |
| [Metrics Server](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/metrics-server) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Metrics Server Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/metrics-server/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/1738) | Yes (PERMISSIVE) | No |
