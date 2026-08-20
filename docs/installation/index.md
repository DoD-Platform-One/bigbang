# Installation Guides

Installation documentation covers deployment patterns that differ after the common [Getting Started](../getting-started/) prerequisites and release-selection steps.

## Deployment Patterns

| Pattern | Use it for | Guide |
| --- | --- | --- |
| Disposable evaluation | Learning, demonstrations, and short-lived development | [Evaluation Quickstart](../getting-started/quick-start.md) |
| Customer-managed GitOps | Persistent development, staging, and production-oriented environments | [First Customer-managed Deployment](../getting-started/first-deployment.md) |
| Disconnected | Environments that must mirror sources and images internally | [Disconnected Environments](environments/airgap.md) |
| Resource-constrained example | Non-production evaluation with a reduced package profile | [Resource-constrained Configuration](environments/appliance-mode.md) |
| SSO evaluation | Extending the quickstart with an identity-provider example | [SSO Quickstart](environments/sso-quickstart.md) |
| Additional application package | Integrating a mission application through package or wrapper configuration | [Extra Package Deployment](environments/extra-package-deployment.md) |

All patterns use the same chart and must satisfy the selected release's [prerequisites](../getting-started/prerequisites.md). Environment guides describe deltas; they do not redefine Kubernetes compatibility, production sizing, or security requirements.

## After Installation

- Configure package behavior through [Configuration](../configuration/).
- Validate the deployment and establish [Operations](../operations/).
- Use [Installation Troubleshooting](../operations/troubleshooting/installation.md) when bootstrap or initial reconciliation fails.
