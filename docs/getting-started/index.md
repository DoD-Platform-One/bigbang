# Getting Started with Big Bang

This section takes a new operator from orientation to the correct deployment path. It intentionally does not repeat architecture, package configuration, or day-two operational reference material.

## What is Big Bang?

Big Bang is an umbrella Helm chart. Flux reconciles the Big Bang chart, and the chart renders the Flux and Kubernetes resources needed to deploy enabled packages.

The selected Big Bang values determine:

- Which integrated or additional packages are enabled.
- Where package charts or Git sources are retrieved.
- Which common settings Big Bang passes into package charts.
- How Flux reconciles and remediates those package releases.

See [Packages](../packages/) for the available integrations and [Architecture](../concepts/architecture.md) for the component relationships.

### What *isn't* Big Bang?

Big Bang does not provision or fully secure the underlying Kubernetes cluster. Cluster lifecycle, node hardening, CNI, CSI, load balancing, DNS, identity infrastructure, external data services, backups, and organizational security processes remain operator responsibilities.

It is also not, by itself, proof of compliance or an authorization to operate. See the [Security Model](../concepts/security-model.md) for the platform boundary.

## What are the benefits of using Big Bang?

Big Bang gives platform teams a versioned way to integrate and reconcile multiple Kubernetes packages through one GitOps configuration. It can reduce repeated integration work, make intended state reviewable in Git, and provide consistent package defaults and upgrade relationships. Those benefits depend on pinning releases, testing configuration, protecting Git and registry access, and operating the resulting platform.

## Choose Your Path

| If you want to… | Start with… | Result |
| --- | --- | --- |
| Learn or evaluate Big Bang | [Evaluation Quickstart](quick-start.md) | A disposable k3d-based environment, not a production baseline |
| Build a customer-managed environment | [First Deployment](first-deployment.md) | A version-controlled GitOps repository based on the customer template |
| Deploy without external network access | [Disconnected Environments](../installation/environments/airgap.md) | A plan for mirrored sources, images, credentials, and validation |
| Add Big Bang to an existing environment | [Prerequisites](prerequisites.md), then [First Deployment](first-deployment.md) | Validation of cluster capabilities before reconciliation |
| Upgrade an existing installation | [Upgrades](../operations/upgrades.md) | A release-by-release upgrade workflow |

## Before You Deploy

For the exact Big Bang release you intend to use:

1. Confirm that the cluster satisfies the [`kubeVersion` constraint](../../chart/Chart.yaml).
2. Inventory enabled packages and plan capacity, storage, networking, ingress, and external dependencies.
3. Prepare Git, registry, identity, certificate, and SOPS access.
4. Decide whether the deployment is an evaluation or a production-oriented environment.
5. Read the release notes and test the complete configuration before production.

The detailed requirements are maintained in [Prerequisites](prerequisites.md).

## After Installation

Continue with:

- [Configuration](../configuration/) to manage Big Bang and package values.
- [Operations](../operations/) for upgrades, backup, monitoring, and maintenance.
- [Troubleshooting](../operations/troubleshooting/) when a Flux source or release is not ready.
- [Frequently Asked Questions](faq.md) for licensing, support, and deployment boundaries.
