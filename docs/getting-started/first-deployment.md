# First Customer-managed Deployment

Use this path when building a persistent GitOps environment. For disposable evaluation, use the [Evaluation Quickstart](quick-start.md) instead.

The [Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template) is the maintained starting point for the environment repository. Its release-specific instructions are authoritative for the template's directory layout and bootstrap commands; this page describes the decisions that must be made before using it.

## 1. Select and Validate a Release

- Choose an immutable Big Bang release tag.
- Confirm that the target cluster satisfies that release's [`kubeVersion` constraint](../../chart/Chart.yaml).
- Review the Big Bang release notes and the enabled packages' upgrade or installation notes.
- Complete the [prerequisites](prerequisites.md) for capacity, networking, storage, ingress, credentials, and Flux.

## 2. Create the Environment Repository

Copy or fork the customer template into a repository controlled by your organization. Protect the default branch, require review, restrict Flux credentials to the required repositories, and define ownership for promotion and rollback.

Keep environment-specific configuration in this repository. Do not edit the Big Bang release source to hold customer values.

## 3. Configure Desired State

At minimum, define:

- The pinned Big Bang release and package source versions.
- The base domain, gateways, certificates, and DNS plan.
- Registry and repository credentials.
- The enabled package set and its capacity and persistence requirements.
- SOPS encryption and Flux decryption-key access.
- Cluster-specific CNI, CSI, load-balancer, identity, and policy settings.

Use the [configuration guide](../configuration/) and the selected release's generated [configuration reference](../configuration/base-config.md). Keep secrets encrypted in Git.

## 4. Bootstrap and Reconcile

Follow the customer template's bootstrap procedure to install the pinned Flux manifests and apply the top-level environment resources. Then follow reconciliation from the environment source to the Big Bang release and package releases:

```shell
flux check
flux get sources all -A
flux get kustomizations -A
flux get helmreleases -A
```

Do not treat a successful Helm action as complete validation.

## 5. Validate the Environment

Verify at least:

- All Flux sources, Kustomizations, and HelmReleases are ready.
- Workloads are healthy and remain schedulable during planned disruption.
- Storage, backup, and restore behavior meet the data requirements.
- Ingress, DNS, certificates, SSO, and authorization work as designed.
- Network and admission policies enforce the intended boundaries.
- Metrics, logs, alerts, and operational ownership are in place.
- Application-level smoke tests pass.

Before production promotion, establish the [operations](../operations/) and [upgrade](../operations/upgrades.md) procedures for this environment.
