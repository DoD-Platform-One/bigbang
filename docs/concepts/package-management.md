# Package Management

Big Bang uses a declarative approach to package management, allowing you to enable, disable, and configure packages through values-based configuration. This document covers the core concepts of managing packages within Big Bang.

## Package Categories

Big Bang organizes packages into three main categories:

- **Core Packages**: Integrated infrastructure components (Istiod, Fluent Bit, Monitoring, etc.)
- **Add-on Packages**: Optional but commonly used applications (ArgoCD, GitLab, etc.)
- **Custom Packages**: User-defined applications following Big Bang patterns

All built-in packages can be configured through the unified `packages.<name>`
path. Existing top-level and `addons.<name>` paths remain supported until Big
Bang 4.x. In Big Bang 3.x, set `packageConfiguration.version` to `v1` to opt in
to the unified built-in package paths. The v1 discriminator remains supported
and becomes the default package contract in Big Bang 4.x. When both paths are
present, `packages.<name>` takes precedence.

```yaml
packageConfiguration:
  version: v1

packages:
  monitoring:
    enabled: true
  gitlab:
    enabled: false
```

## Enabling and Disabling Packages

### Core Packages

Core packages are enabled by default but can be disabled:

```yaml
packageConfiguration:
  version: v1

packages:
  # Disable monitoring stack
  monitoring:
    enabled: false

  # Disable the Fluent Bit log collector
  fluentbit:
    enabled: false

  # Disable the Istio control plane
  istiod:
    enabled: false
```

### Add-on Packages

Add-on packages are disabled by default and must be explicitly enabled:

```yaml
packageConfiguration:
  version: v1

packages:
  # Enable GitLab
  gitlab:
    enabled: true
  
  # Enable ArgoCD
  argocd:
    enabled: true
```

## Package Sources

Big Bang supports both Git and OCI (Open Container Initiative) sources for packages.

### Git Sources (Default)

Most packages use Git repositories by default:

```yaml
packageConfiguration:
  version: v1

packages:
  gitlab:
    enabled: true
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/gitlab.git
      tag: "9.11.7-bb.0"
      path: "./chart"
```

### OCI Sources

Define the OCI repository at the top level, then select it from the package with
`sourceType: helmRepo`:

```yaml
helmRepositories:
  - name: registry1
    repository: oci://registry1.dso.mil/bigbang
    type: oci
    existingSecret: private-registry

packageConfiguration:
  version: v1

packages:
  gitlab:
    enabled: true
    sourceType: helmRepo
    helmRepo:
      repoName: registry1
      chartName: gitlab
      tag: "9.11.7-bb.0"
```

## Passing Values to Packages

### Basic Value Configuration

Pass values directly to packages using the `values` key:

```yaml
packageConfiguration:
  version: v1

packages:
  gitlab:
    enabled: true
    values:
      upstream:
        gitlab:
          webservice:
            replicas: 2
```

### Advanced Configuration

Use YAML anchors and references for complex configurations:

```yaml
# Anchors can be attached to schema-supported values.
domain: &domain "example.com"

packageConfiguration:
  version: v1

packages:
  gitlab:
    enabled: true
    values:
      global:
        hosts:
          domain: *domain
```

## Additional Configuration Options

### Flux Settings

Configure Flux-specific behavior for packages:

```yaml
packageConfiguration:
  version: v1

packages:
  gitlab:
    enabled: true
    flux:
      timeout: 10m
      interval: 2m
      upgrade:
        remediation:
          retries: 3
    values:
      # package values here
```

### Namespace Configuration

Built-in packages use namespaces selected by Big Bang. For a custom package,
set its target namespace under `packages`:

```yaml
packages:
  podinfo:
    enabled: true
    sourceType: git
    namespace:
      name: custom-podinfo-namespace
      create: true
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: "6.3.4"
      path: charts/podinfo
    values:
      replicaCount: 2
```

### Dependency Management

Control a custom Helm package's installation order with dependencies:

```yaml
packages:
  podinfo:
    enabled: true
    sourceType: git
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: "6.3.4"
      path: charts/podinfo
    dependsOn:
      - name: monitoring
        namespace: bigbang
    values:
      replicaCount: 2
```

## Best Practices

1. **Environment-Specific Values**: Organize values by environment (dev, staging, prod)
2. **Secret Management**: Use external secret management for sensitive values
3. **Validation**: Test package configurations in non-production environments first

## Example: Complete Package Configuration

Look at [test values](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/tests/test-values.yaml) for comprehensive examples of (non-production) package configurations.

For detailed package-specific configuration options, refer to each package's individual documentation and the [Package Troubleshooting](../operations/troubleshooting/packages.md) guide for resolving configuration issues.
