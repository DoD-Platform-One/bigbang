# Packages

## Core

Columns:
* Logging - fluentbit configurations for standardized logging
* Telemetry - Integration with Prometheus and dedicated Grafana dashbaords as appropriate
* Tracing - Insertion of Tracing data for application traffic
* Network Policies - Network Policies for L2 connectivity, 
* mTLS -mTLS for applicatoin traffic, e.g. implemented by Istio
* Behavior Detection - Twistlock Policies for applications


| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [Istio Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator) |  ![Istio Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator/badges/main/pipeline.svg) | No | No | No | Yes | No |No |
| [Istio Controlplane](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane) | ![Istio Controlplane Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane/badges/main/pipeline.svg) | No | No | No | Yes | No | No |
| [Jaeger](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger) | ![Jaeger Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger/badges/main/pipeline.svg) | No | Yes | Yes | Yes | No |
| [Kiali](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali) | ![Kiali Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali/badges/main/pipeline.svg) | No | Yes | Yes | Yes | No |No |
| [Monitoring](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring) | ![Monitoring Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring/badges/main/pipeline.svg) | No | No | No | Yes | No |No |
| [ECK Operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator) | ![ECK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator/badges/main/pipeline.svg) |  No | No | No | Yes | No |No |
| [Elasticsearch Kibana](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana) |![EK Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana/badges/main/pipeline.svg)  | No | No | No | Yes | No |No |
| [Fluentbit](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit) | ![Fluentbit Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit/badges/main/pipeline.svg)  | No | No | No | Yes | No |No |
| [OPA Gatekeeper](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy) | ![OPA Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy/badges/main/pipeline.svg) | No | No | No | Yes | No |No |
| [Argocd](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd) |![Argo Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd/badges/main/pipeline.svg)  |  No | No | No | Yes | No |No |
| [Cluster Auditor](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor) | ![Cluster Auditor Build](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor/badges/main/pipeline.svg)  | No | No | No | Yes | No |No |


## Security
| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [Keycloak](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak) |  ![Keycloak Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak/badges/main/pipeline.svg) | No | No | No | No | No | No |
| [Twistlock](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock) |  ![Twistlock Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock/badges/main/pipeline.svg) | No | No | No | No | No | No |
| [Anchore Enterprise](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise) | ![Anchore Build](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise/badges/main/pipeline.svg) | No | No | No | No | No | No |
| [Authservice](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice) | ![Authservice Build](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice/badges/main/pipeline.svg) | No | Yes | Yes | No | No | No |

## Development Tools


| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [Gitlab](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab)  | ![Gitlab Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/badges/main/pipeline.svg)    | No | No | No | No | No | No |
| [Gitlab Runner](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner) |  ![Gitlab Runner Build](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner/badges/main/pipeline.svg) | No | No | No | No | No | No |
| [Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus) |  ![Nexus](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/badges/main/pipeline.svg) |
| [Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube) |  ![Sonarqube](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube/badges/main/pipeline.svg) | No | No | No | No | No | No |
 

## Collaboration Tools

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [Mattermost](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost)  | ![Mattermost Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost/badges/main/pipeline.svg)    | No | No | No | No | No | No |
| [Mattermost Operator](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator) |  ![Mattermost Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator/badges/main/pipeline.svg) | No | No | No | No | No | No |

## Application Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [MinIO](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio)  | ![MinIO Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio/badges/main/pipeline.svg)    | No | No | No | No | No | No |
| [MinIO Operator](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator) |  ![MinIO Operator Build](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator/badges/main/pipeline.svg) | No | No | No | No | No |No |

## Cluster Utilities

| Package | Status | Logging | Telemetry | Tracing | Network Policies | mTLS | Behavior Detection |
| ----    | ---  | ---|---|---|---|---|
| [Velero](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero)  | ![Velero Build](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero/badges/main/pipeline.svg) | No | No | No | No | No | No |

