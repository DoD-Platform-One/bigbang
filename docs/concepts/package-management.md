# Package Management

Big Bang uses a declarative approach to package management, allowing you to enable, disable, and configure packages through values-based configuration. This document covers the core concepts of managing packages within Big Bang.

## Package Categories

Big Bang organizes packages into three main categories:

- **Core Packages**: Essential infrastructure components (Istio, Fluentd, Monitoring, etc.)
- **Add-on Packages**: Optional but commonly used applications (ArgoCD, GitLab, Nexus, etc.)
- **Custom Packages**: User-defined applications following Big Bang patterns

## Enabling and Disabling Packages

### Core Packages

Core packages are enabled by default but can be disabled:

```yaml
# Disable monitoring stack
monitoring:
  enabled: false

# Disable log aggregation
fluentd:
  enabled: false

# Disable service mesh
istio:
  enabled: false
```

### Add-on Packages

Add-on packages are disabled by default and must be explicitly enabled:

```yaml
addons:
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
addons:
  gitlab:
    enabled: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/gitlab.git
      tag: "7.7.0-bb.4"
      path: "./chart"
```

### OCI Sources

For packages available as OCI artifacts:

```yaml
addons:
  gitlab:
    enabled: true
    oci:
      registry: registry1.dso.mil
      repository: bigbang/gitlab
      tag: "7.7.0-bb.4"
```

## Passing Values to Packages

### Basic Value Configuration

Pass values directly to packages using the `values` key:

```yaml
addons:
  gitlab:
    enabled: true
    values:
      global:
        hosts:
          domain: bigbang.dev
        ingress:
          enabled: true
      upstream:
 .      gitlab:
          webservice:
            replicas: 2
```

### Advanced Configuration

Use YAML anchors and references for complex configurations:

```yaml
# Define common values
commonDomain: &domain "example.com"

addons:
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
addons:
  gitlab:
    enabled: true
    flux:
      timeout: 10m
      interval: 2m
      retries: 3
    values:
      # package values here
```

### Namespace Configuration

Specify custom namespaces for packages:

```yaml
addons:
  gitlab:
    enabled: true
    namespace: custom-gitlab-namespace
    values:
      # package values here
```

### Dependency Management

Control package installation order with dependencies:

```yaml
addons:
  gitlab:
    enabled: true
    dependsOn:
      - name: istio
        namespace: istio-system
    values:
      # package values here
```

## Best Practices

1. **Environment-Specific Values**: Organize values by environment (dev, staging, prod)
2. **Secret Management**: Use external secret management for sensitive values
3. **Validation**: Test package configurations in non-production environments first

## Example: Complete Package Configuration

Look at [test values](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/tests/test-values.yaml) for comprehensive examples of (non-production) package configurations.

For detailed package-specific configuration options, refer to each package's individual documentation and the [Package Troubleshooting](../operations/troubleshooting/packages.md) guide for resolving configuration issues.
