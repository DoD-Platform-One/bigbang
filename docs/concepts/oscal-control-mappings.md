# Big Bang Package OSCAL Control Mapping Summary

This report summarizes `oscal-component.yaml` files found across the repositories in the [Big Bang Product Packages group](https://repo1.dso.mil/big-bang/product/packages).

## Package control mappings

| Repository | Mappings | Control-family coverage | High-level summary |
|---|---:|---|---|
| [NeuVector](https://repo1.dso.mil/big-bang/product/packages/neuvector/-/blob/main/oscal-component.yaml) | 28 | AC 8, AU 3, CA 2, CM 2, RA 4, SA 2, SC 2, SI 5 | Container security: RBAC, vulnerability scanning, continuous monitoring, audit events, secure networking, and transport protection. |
| [Grafana](https://repo1.dso.mil/big-bang/product/packages/grafana/-/blob/main/oscal-component.yaml) | 16 | AC 1, AU 15 | Audit and monitoring visualization, alerting, event correlation, retention visibility, and restricting access to monitoring data. |
| [Loki](https://repo1.dso.mil/big-bang/product/packages/loki/-/blob/main/oscal-component.yaml) | 15 | AC 6, AU 9 | Centralized log storage and querying, retention, audit analysis, and enterprise RBAC around log access. |
| [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno/-/blob/main/oscal-component.yaml) | 13 | CM 6, SC 5, SI 1, SR 1 | Policy-as-code enforcement for secure configuration, network isolation, resource limits, and signed-image verification. |
| [Vault](https://repo1.dso.mil/big-bang/product/packages/vault/-/blob/main/oscal-component.yaml) | 3 | IA 1, SC 2 | Machine and service authentication, PKI certificate issuance, and encryption of secrets at rest. |
| [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo/-/blob/main/oscal-component.yaml) | 3 | AU 2, SI 1 | Scalable trace storage, time-series audit trails, and visibility into service-to-service communications. |
| [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali/-/blob/main/oscal-component.yaml) | 1 | SI 1 | Visibility into Istio mTLS configuration and encrypted service-mesh traffic. |
| [Velero](https://repo1.dso.mil/big-bang/product/packages/velero/-/blob/main/oscal-component.yaml) | 15 | CP 15 | Backup, restore, off-site storage, alternate recovery locations, and continuity and reconstitution capabilities. |
| [Fluent Bit](https://repo1.dso.mil/big-bang/product/packages/fluentbit/-/blob/main/oscal-component.yaml) | 4 | AC 1, AU 3 | Collection and forwarding of audit records, including privileged events, event details, and timestamps. |
| [Elasticsearch/Kibana](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/-/blob/main/oscal-component.yaml) | 34 | AC 1, AU 15, CM 1, IR 5, PS 1, SI 11 | Audit-log storage, search, reporting and protection, plus incident analysis, event monitoring, alerting, and integrity checking. |
| [Authservice](https://repo1.dso.mil/big-bang/product/packages/authservice/-/blob/main/oscal-component.yaml) | 30 | AC 8, IA 22 | Centralized authentication and access enforcement: account lifecycle, sessions, MFA, external identity providers, and credential handling. |
| [Istio Controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane/-/blob/main/oscal-component.yaml) | 28 | AC 8, AU 4, CM 1, SC 14, SI 1 | Service-mesh traffic authorization, network-flow enforcement, mTLS and encryption, communications isolation, and traffic logging. |
| [Argo CD](https://repo1.dso.mil/big-bang/product/packages/argocd/-/blob/main/oscal-component.yaml) | 23 | AC 3, AU 2, CM 14, CP 4 | GitOps configuration baselines, controlled and auditable changes, resource inventory, RBAC, and configuration recovery. |
| [Keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak/-/blob/main/oscal-component.yaml) | 50 | AC 29, AU 9, IA 12 | Broad identity and access management: account lifecycle, RBAC, sessions, MFA, federation, authentication, and security-event auditing. |
| [Twistlock / Prisma Cloud](https://repo1.dso.mil/big-bang/product/packages/twistlock/-/blob/main/oscal-component.yaml) | 18 | AU 2, CA 2, RA 3, SA 2, SC 3, SI 6 | Container vulnerability assessment, runtime monitoring, compliance reporting, audit capacity, network protection, and software integrity. |
| [Gatekeeper](https://repo1.dso.mil/big-bang/product/packages/policy/-/blob/main/oscal-component.yaml) | 6 | AU 4, CM 2 | Admission-policy enforcement and detailed auditing of policy violations, unauthorized changes, and software installation. |
| [Monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring/-/blob/main/oscal-component.yaml) | 17 | AC 1, AU 16 | Prometheus/Grafana-based audit collection, storage, dashboards, alerting, correlation, retention, and access restriction. |
| [GitLab](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/blob/main/oscal-component.yaml) | 68 | AC 15, AU 12, CM 11, CP 9, IA 15, MA 2, RA 3, SA 1 | Account and identity management, MFA, auditing, configuration and change control, backups and recovery, maintenance, and security scanning. |

## Comparison with the Big Bang aggregate

The existing [Big Bang `oscal-component.yaml`](./oscal-component.yaml) is an older, machine-readable roll-up. The table above is a current, human-readable inventory derived from package repositories.