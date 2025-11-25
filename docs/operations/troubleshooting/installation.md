# Installation Issues

This guide helps you diagnose and resolve issues during Big Bang installation. Installation problems typically involve Flux deployment failures, configuration errors, or infrastructure prerequisites.

## Quick Installation Diagnostics

### 1. Check Installation Status

Verify the overall installation progress:

```bash
# Check Big Bang HelmRelease status
kubectl get helmrelease bigbang -n bigbang

# Check all package installations
kubectl get helmreleases -A

# Check Flux system health
kubectl get pods -n flux-system
```

### 2. Common Installation Failures

**Flux Controller Issues**:
```bash
# Check Flux controllers are running
kubectl get pods -n flux-system

# Check controller logs for errors
kubectl logs -n flux-system deployment/helm-controller
kubectl logs -n flux-system deployment/source-controller
```

**Git Repository Access**:
```bash
# Check GitRepository status
kubectl get gitrepository -n flux-system
kubectl describe gitrepository <repo-name> -n flux-system

# Check for authentication or network issues
kubectl get events -n flux-system --sort-by='.lastTimestamp'
```

## Installation-Specific Issues

### 1. Schema Validation Errors

Check for configuration problems:

```bash
# Look for schema validation failures
kubectl get helmrelease bigbang -n bigbang -o yaml | grep -A 10 "conditions:"

# Common issues:
# - Invalid Big Bang values
# - Missing required configuration
# - Type mismatches in values.yaml
```

### 2. Resource Prerequisites

Verify cluster meets requirements:

```bash
# Check node resources
kubectl get nodes
kubectl describe nodes

# Check storage classes
kubectl get storageclass

# Verify cluster networking
kubectl get pods -n kube-system
```

### 3. Package Dependencies

Some packages require specific prerequisites:

```bash
# Check for dependency issues in events
kubectl get events --all-namespaces | grep -i "failed\|error"

# Verify prerequisite packages are installed first
kubectl get helmreleases -A | grep -E "cert-manager|istio"
```

## Troubleshooting by Component

For detailed troubleshooting of specific issues:

- **Package Installation Failures**: See [Package Troubleshooting](packages.md)
- **Network Connectivity Issues**: See [Networking Troubleshooting](networking.md)
- **Resource and Performance Problems**: See [Performance Troubleshooting](performance.md)

### Quick Reference Commands

```bash
# Check overall Big Bang status
kubectl describe helmrelease bigbang -n bigbang

# Force reconciliation if stuck
flux reconcile helmrelease bigbang -n bigbang

# Check for drift from desired state
flux diff helmrelease bigbang -n bigbang

# Review installation events
kubectl get events -n bigbang --sort-by='.lastTimestamp'
```

## Recovery Steps

### 1. Reset Installation

If installation is completely broken:

```bash
# DANGER: This will delete your Big Bang installation! Ensure you have backups.
# Delete and recreate Big Bang HelmRelease
kubectl delete helmrelease bigbang -n bigbang
# Flux will recreate from Git source

# Force source reconciliation
flux reconcile source git <source-name> -n flux-system
```

### 2. Partial Installation Recovery

For partially failed installations:

```bash
# Identify failed packages
kubectl get helmreleases -A | grep -v "True.*True"

# Force reconciliation of specific packages
flux reconcile helmrelease <package-name> -n bigbang
```

## Common Installation Patterns

### 1. Prerequisites Not Met

Ensure the following before installation:
- Kubernetes cluster version compatibility
- Sufficient node resources
- Required storage classes
- Network connectivity to registries

### 2. Configuration Issues

Validate your values before installation:
- Check Big Bang values syntax
- Verify package-specific configurations
- Test with minimal configuration first

### 3. Infrastructure Dependencies

Some environments require additional setup:
- Load balancer provisioning
- DNS configuration
- Certificate management
- External secret management

## Next Steps

Once basic installation issues are resolved:

1. Review [Monitoring](../monitoring.md) to set up observability
2. Configure [Backup & Restore](../backup-restore.md) procedures
3. Plan [Upgrade](upgrades.md) strategies

For persistent installation issues, gather logs and events as described in the [Package Troubleshooting](packages.md) guide and engage with the Big Bang community.
