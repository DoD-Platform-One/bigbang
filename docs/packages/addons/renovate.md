# Renovate

## Overview

Renovate is an automated dependency update tool. In Big Bang, the Renovate package runs self-hosted Renovate as a Kubernetes CronJob so it can regularly scan configured Git repositories and open merge requests for dependency updates.

Common uses include:

- Updating Big Bang versions referenced by customer overlays or environment repositories
- Updating Big Bang package tags in values files
- Updating Helm chart, container image, and other dependency versions
- Creating a dependency dashboard so maintainers can review available updates

Renovate does not deploy updates into the cluster. It proposes changes in Git; normal review, testing, approval, and GitOps reconciliation still control what reaches an environment.

## Big Bang Touch Points

### Deployment

Renovate is disabled by default. Enable it with the top-level `renovate.enabled` value:

```yaml
renovate:
  enabled: true
```

When enabled, Big Bang deploys Renovate into the `renovate` namespace. Package-specific configuration is passed through `renovate.values` to the Renovate package chart.

Big Bang manages the package source under `renovate.git` or `renovate.helmRepo`; most deployments should leave those values at the version pinned by the Big Bang release.

### Basic Configuration

At minimum, configure a schedule and a Renovate config that tells Renovate which Git platform and repositories to scan.

```yaml
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
          "autodiscover": false,
          "dryRun": true,
          "repositories": ["group/project"]
        }
```

Start with `dryRun: true` to validate repository access and update detection before allowing Renovate to create merge requests.

Do not commit a real Renovate token in plaintext values. Store the value using the same secret-management process used for other Big Bang secret values.

### Authentication

Renovate needs a Git provider token that can read the target repositories and create branches and merge requests. Use the least-privileged token that works for the repositories Renovate manages.

For GitLab, the `repositories` entries use the project path format, such as `group/project`. If `autodiscover` is enabled, scope the token carefully because Renovate can discover every repository visible to that token.

### Scheduling

The package runs Renovate as a CronJob. Set `renovate.values.cronjob.schedule` with standard cron syntax.

```yaml
renovate:
  values:
    cronjob:
      schedule: "0 1 * * *"
```

Use a schedule that matches your review workflow. Daily runs are common, but production environments may prefer weekly or maintenance-window schedules to reduce merge request noise.

### Repository Configuration

Self-hosted Renovate has two layers of configuration:

- The Big Bang deployment config under `renovate.values.renovate.config`
- The per-repository Renovate config, usually `renovate.json` in each target repository

The deployment config controls how the Renovate job connects to the Git platform and which repositories it scans. The per-repository config controls which files and dependencies Renovate updates, how updates are grouped, labels, dependency dashboard behavior, and merge request behavior.

For Big Bang environment repositories, regex managers are commonly used to update Git tags or Big Bang package tags in YAML files.

### Network Policy, Istio, And Monitoring

The Renovate package receives Big Bang defaults for network policies, Istio, image pull secrets, and monitoring. When the related Big Bang packages are enabled, the Renovate HelmRelease also waits on them.

If Renovate needs to reach a private Git service, private registry, or proxy, make sure the package values and network policy configuration allow that egress.

### More Detailed Examples

For detailed examples of self-hosted Renovate config, scheduling options, and Big Bang-oriented `renovate.json` regex managers, see the [Renovate maintenance guide](../../operations/maintenance/renovate.md).

For full Renovate configuration behavior, use the upstream Renovate documentation rather than duplicating every option in Big Bang docs.
