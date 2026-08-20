# Security Model

Big Bang is a GitOps deployment and integration layer for Kubernetes packages. It provides configurable security capabilities, but it does not by itself secure the underlying cluster, make every workload compliant, or grant an authorization to operate. The resulting security posture depends on the selected packages and values, the Kubernetes distribution, infrastructure controls, identities, application design, and operational processes.

## Trust Boundaries

Big Bang manages resources inside a Kubernetes cluster through Flux. The platform owner remains responsible for controls outside or below that boundary, including:

- Kubernetes control-plane, node, container-runtime, and operating-system hardening.
- Cloud accounts, networks, load balancers, DNS, storage, backups, and key-management services.
- Git, registry, and identity-provider administration.
- Application security, data classification, retention, recovery, and incident response.
- Physical and administrative controls and the evidence required by an authorizing official.

See [Architecture](architecture.md) and [GitOps Engine](git-ops-engine.md) for the deployment boundary.

## Security Capabilities

The following capabilities are available when their packages are enabled and correctly configured.

### GitOps Reconciliation

Flux reconciles declared sources and Helm releases into the cluster. Pin immutable release references, restrict repository write access, require review, encrypt secrets, and monitor reconciliation failures. Git history and Flux status contribute useful change evidence, but neither replaces an organizational audit system.

See [GitOps Workflow](git-ops-workflow.md) and [Encryption](encryption.md).

### Workload and Admission Policy

Kyverno, Kyverno Policies, and Gatekeeper can validate Kubernetes resources at admission time. Their effectiveness depends on which policies are installed, whether they audit or enforce, and which exclusions apply. Kubernetes Pod Security Admission may also be configured by the cluster owner.

`PodSecurityPolicy` is not part of this model; Kubernetes removed that API in version 1.25. Review the [prerequisites](../getting-started/prerequisites.md#pod-security-and-admission-control) before choosing admission controls.

### Network Isolation and Service Mesh

Big Bang packages can render Kubernetes `NetworkPolicy` resources. Enforcement requires a compatible CNI. Istio can provide workload identity, traffic policy, ingress controls, and mutual TLS for workloads enrolled in the mesh. Traffic outside the mesh, excluded namespaces, and infrastructure endpoints require separate controls.

Enabling Istio does not prove that every connection is encrypted or authorized. Verify mesh enrollment, peer-authentication mode, authorization policies, gateway exposure, and certificate behavior for the deployed configuration.

### Identity and Secrets

Supported packages can integrate with configured OIDC or SAML providers. Big Bang does not operate the external identity provider or define the organization's account lifecycle, multifactor authentication, privileged-access, or access-review processes.

Environment secrets can be encrypted with SOPS before being stored in Git. Protect the decryption keys, limit access to plaintext Kubernetes Secrets, and use an external secrets system when required by the threat model. See [Encryption](encryption.md).

### Images and Software Supply Chain

Big Bang references package sources and container images through configurable Git, Helm, OCI, and registry locations. Platform owners must verify the provenance and vulnerability posture required by their organization, protect registry credentials, approve version changes, and retain applicable software-bill-of-materials and attestation evidence.

The presence of an image in a registry or a package in Big Bang is not a guarantee that it satisfies a particular risk decision. Pin versions and apply the organization's admission and promotion policies.

### Observability and Runtime Security

Monitoring, Grafana, logging packages, and optional runtime-security products can collect different parts of the operational and security signal. Coverage depends on package selection, licensing, configuration, retention, alert routing, and response procedures. Big Bang does not automatically provide a SIEM, threat-intelligence feed, incident-response program, or complete audit record.

See [Logging](logging.md), [Monitoring](../operations/monitoring.md), and the documentation for each enabled runtime-security package.

## Compliance

Big Bang can help implement and observe technical controls, but compliance is a property of a scoped system and its operation. It cannot automatically confer NIST, FedRAMP, DoD, or continuous-authorization status.

For each required control:

1. Identify the responsible system component and owner.
2. Configure the relevant Big Bang, package, cluster, and infrastructure settings.
3. Test the control in the deployed environment.
4. Collect versioned evidence and document exclusions or compensating controls.
5. Reassess after Big Bang, package, Kubernetes, infrastructure, or policy changes.

## Secure Deployment Checklist

- Pin the Big Bang release and all package sources to reviewed versions.
- Confirm the Kubernetes version satisfies the release's chart constraint.
- Encrypt environment secrets and restrict decryption-key access.
- Review rendered manifests, admission policies, network policies, and exemptions.
- Verify CNI enforcement, Istio enrollment, ingress exposure, TLS, and identity flows.
- Configure backups and test restoration for all persistent data.
- Route actionable metrics, logs, policy results, and runtime alerts to owned response processes.
- Test upgrades in a representative environment and retain the resulting evidence.
- Document controls that remain the responsibility of the cluster, infrastructure, application, or organization.

Package defaults and capabilities change. Use the documentation and rendered output from the exact Big Bang release under review as the implementation source of truth.
