# Renovate

## Overview

Renovate is an automated dependency update tool. Big Bang deploys self-hosted Renovate as a Kubernetes CronJob so it can scan configured Git repositories and propose dependency updates.

Renovate does not deploy updates into a cluster. It proposes changes in Git; normal review, testing, approval, and GitOps reconciliation determine what reaches an environment.

## Big Bang Integration

Configure the package under `packages.renovate` when using `packageConfiguration.version: v1`. For Big Bang 3.x configurations that have not enabled the unified package contract, the legacy path is `renovate`.

Renovate is disabled by default. When enabled, Big Bang deploys it into the `renovate` namespace and passes package-specific chart configuration through the package's `values` mapping.

At minimum, configure a schedule, Git platform, credentials, and the repositories Renovate should scan. Start with Renovate's dry-run behavior and use a least-privilege token. Do not store a real token in plaintext values.

```yaml
packageConfiguration:
  version: v1
packages:
  renovate:
    enabled: true
    values:
      cronjob:
        schedule: "0 1 * * *"
      renovate:
        config: |
          {
            "platform": "gitlab",
            "endpoint": "https://gitlab.example.com/api/v4",
            "token": "REPLACE_ME",
            "dryRun": true,
            "repositories": ["group/project"]
          }
```

Use the generated [Values Reference](../../configuration/base-config.md) for the exact Big Bang configuration contract. See the [Renovate maintenance guide](../../operations/maintenance/renovate.md) for detailed examples and the [Renovate package repository](https://repo1.dso.mil/big-bang/product/packages/renovate) for packaged chart values and its changelog.
