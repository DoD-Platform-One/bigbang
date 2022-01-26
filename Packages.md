# Packages

## Core

Columns:
* Logging - fluentbit configurations for standardized logging
* Telemetry - Integration with Prometheus and dedicated Grafana dashboards as appropriate
* Tracing - Insertion of Tracing data for application traffic
* Network Policies - Network Policies for L2 connectivity, 
* mTLS -mTLS for application traffic, e.g. implemented by Istio
* Behavior Detection - Twistlock Policies for applications


| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Istio Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator) |  ![Istio Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/641) | No | No |
| [Istio Controlplane](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane) | ![Istio Controlplane Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/632) | No | No |
| [Jaeger](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger) | ![Jaeger Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/602) | No | No |
| [Kiali](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali) | ![Kiali Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/589) | No | No |
| [Monitoring](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring) | ![Monitoring Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/509) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/624) | No |
| [ECK Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator) | ![ECK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator/badges/main/pipeline.svg) |  No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/510) | No | No |
| [Elasticsearch Kibana](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana) |![EK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/527) | No | No |
| [Fluentbit](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit) | ![Fluentbit Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/555/) | No | No |
| [OPA Gatekeeper](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy) | ![OPA Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/626) | No |No |
| [Argocd](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd) |![Argo Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd/badges/main/pipeline.svg)  |  No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/572) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/620) | No |
| [Cluster Auditor](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor) | ![Cluster Auditor Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor/badges/main/pipeline.svg)  | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/565) | No | No |
| [Kyverno](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Kyverno Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |
| [Promtail](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/promtail) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Promtail Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/promtail/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |
| [Loki](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/loki) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Loki Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/loki/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |
| [Tempo](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Tempo Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo/-/merge_requests/2) | No | No |



## Security
| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Keycloak](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak) |  ![Keycloak Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/536) | No | No |
| [Twistlock](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock) |  ![Twistlock Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/498) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/618) | No |
| [Anchore Enterprise](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise) | ![Anchore Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/505) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/619) | No |
| [Authservice](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice) | ![Authservice Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice/badges/main/pipeline.svg) | No | Yes | Yes | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/511) | No | No |
| [Vault](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault) ![BETA](https://img.shields.io/badge/BETA-purple?style=flat-square) | ![Vault Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault/badges/main/pipeline.svg) |  No | No | No | Yes | No | No |


## Development Tools


| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Gitlab](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab)  | ![Gitlab Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/504) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/621) | No |
| [Gitlab Runner](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner) |  ![Gitlab Runner Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/522) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/621) | No |
| [Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus) |  ![Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/544) | No | No
| [Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube) |  ![Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/503) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/625) | No |
 

## Collaboration Tools

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Mattermost](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost)  | ![Mattermost Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/515) | [No](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/623) | No |
| [Mattermost Operator](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator) |  ![Mattermost Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/499) | No | No |

## Application Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [MinIO](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio)  | ![MinIO Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio/badges/main/pipeline.svg)    | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/550) | No | No |
| [MinIO Operator](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator) |  ![MinIO Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator/badges/main/pipeline.svg) | No | No | No | No | No |No |

## Cluster Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|---|
| [Velero](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero)  | ![Velero Build](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero/badges/main/pipeline.svg) | No | No | No | [Yes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/merge_requests/552) | No | No |

