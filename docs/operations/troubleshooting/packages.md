# Package Troubleshooting

This guide helps you diagnose and resolve issues with Big Bang packages. Package problems can range from deployment failures and configuration issues to networking connectivity and policy violations.

## Overview

Big Bang packages are deployed using Flux and can encounter various types of issues:

- **Deployment Issues**: Pods failing to start, image pull errors, resource constraints
- **Configuration Problems**: Invalid Helm values, schema validation failures
- **Network Connectivity**: Service mesh issues, network policies, DNS resolution
- **Policy Violations**: Kyverno admission controller blocks, security policy denials
- **Resource Issues**: Insufficient resources, scaling problems, persistent volume issues

## Quick Diagnostics

### 1. Check Package Status

Start by examining the overall package health:

```bash
# Check Flux HelmRelease status
kubectl get helmreleases -A

# Check specific package status
kubectl get helmrelease <package-name> -n bigbang -o yaml

# Check pod status for the package
kubectl get pods -n <package-namespace>
```

### 2. Review Events

Events provide immediate insight into recent issues:

```bash
# Get events for a specific namespace
kubectl get events -n <package-namespace> --sort-by='.lastTimestamp'

# Get events for a specific pod
kubectl describe pod <pod-name> -n <package-namespace>

# Get cluster-wide events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Flux Troubleshooting

### 1. Check Flux Controllers

Verify Flux components are healthy:

```bash
# Check Flux system pods
kubectl get pods -n flux-system

# Check Flux controller logs
kubectl logs -n flux-system deployment/helm-controller
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller
```

### 2. HelmRelease Debugging

Examine HelmRelease status and conditions:

```bash
# Get detailed HelmRelease status
kubectl describe helmrelease <package-name> -n bigbang

# Check for reconciliation errors
kubectl get helmrelease <package-name> -n bigbang -o jsonpath='{.status.conditions[*].message}'

# Force reconciliation
flux reconcile helmrelease <package-name> -n bigbang
```

### 3. Common Flux Issues

**Schema Validation Errors**:
```bash
# Check for schema validation issues in HelmRelease status
kubectl get helmrelease <package-name> -n bigbang -o yaml | grep -A 10 "conditions:"

# Common schema errors indicate:
# - Invalid Helm values
# - Missing required fields
# - Type mismatches in configuration
```

**Source Errors**:
```bash
# Check GitRepository or HelmRepository status
kubectl get gitrepository -n flux-system
kubectl get helmrepository -n flux-system

# Check source controller logs for repository access issues
kubectl logs -n flux-system deployment/source-controller
```

**Helm Installation Failures**:
```bash
# Check Helm release status directly
helm list -A
helm status <release-name> -n <namespace>

# Get Helm release history
helm history <release-name> -n <namespace>
```

## Kyverno Policy Troubleshooting

### 1. Check Policy Violations

Identify admission policy blocks:

```bash
# Check Kyverno admission controller logs
kubectl logs -n kyverno deployment/kyverno-admission-controller

# Get policy violation events
kubectl get events --all-namespaces | grep -i "blocked\|denied\|failed"

# Check specific policy status
kubectl get cpol  # ClusterPolicy
kubectl get pol -A  # Policy
```

### 2. Policy Reports

Review policy evaluation results:

```bash
# Get cluster policy reports
kubectl get cpolr  # ClusterPolicyReport

# Get namespace policy reports
kubectl get polr -A  # PolicyReport

# Detailed policy report for a specific resource
kubectl describe cpolr <report-name>
```

### 3. Kyverno Reporter Setup

Follow the [Overview of Kyverno Reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter/-/blob/main/docs/overview.md) to set up detailed reporting and alerting for policy violations.

### 4. Common Policy Issues

**Resource Mutation Conflicts**:
- Check if multiple policies modify the same resource
- Review policy precedence and order
- Examine mutating vs validating policies

Review [Kyverno Exceptions](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies/-/blob/main/docs/exceptions.md) for guidance on handling necessary exceptions.

## Network Connectivity Issues

For network-related package problems, refer to the [networking troubleshooting guide](networking.md) which covers:

- **Service Mesh Issues**: Istio configuration, mTLS problems, traffic routing
- **Network Policies**: Connectivity blocks, policy misconfigurations
- **DNS Resolution**: Service discovery failures, external DNS issues
- **Ingress Problems**: Load balancer issues, certificate problems
- **Service Entries**: External service access, HTTPS/TLS configuration

### Quick Network Checks

```bash
# Test pod-to-pod connectivity
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>

# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Verify Istio sidecar injection
kubectl get pods -n <namespace> -o jsonpath='{.items[*].spec.containers[*].name}'
```

## Resource and Scaling Issues

### 1. Resource Constraints

Check for resource-related problems:

```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resource usage
kubectl top pods -A
kubectl describe pod <pod-name> -n <namespace>

# Check resource quotas
kubectl get resourcequota -A
kubectl describe resourcequota <quota-name> -n <namespace>
```

### 2. Persistent Volume Issues

Debug storage problems:

```bash
# Check PVC status
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>

# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv
kubectl describe pv <pv-name>
```

### 3. Scaling Problems

Address autoscaling issues:

```bash
# Check HPA status
kubectl get hpa -A
kubectl describe hpa <hpa-name> -n <namespace>

# Check VPA recommendations
kubectl get vpa -A
kubectl describe vpa <vpa-name> -n <namespace>

# Check deployment replica status
kubectl get deployment -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>
```

## Observability and Monitoring

### 1. Check Monitoring Stack

Use Big Bang's observability tools:

- **Grafana Dashboards**: Review package-specific dashboards
- **Prometheus Metrics**: Query application and infrastructure metrics
- **Tempo Tracing**: Analyze request flows and performance
- **AlertManager**: Check for active alerts

### 2. Application Logs

Examine application logs for errors:

```bash
# Get pod logs
kubectl logs <pod-name> -n <namespace>

# Get logs from all containers in a pod
kubectl logs <pod-name> -n <namespace> --all-containers

# Follow logs in real-time
kubectl logs -f <pod-name> -n <namespace>

# Get previous container logs (for crashed pods)
kubectl logs <pod-name> -n <namespace> --previous
```

### 3. Custom Metrics

Enable application-specific monitoring as described in the [monitoring guide](../monitoring.md):

```yaml
# Add Prometheus scraping annotations
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

## Configuration and Immutability Issues

### 1. Configuration Drift

Check for Flux drift detection and reconcile with Flux CLI:

```bash
# Inspect Flux resources and their conditions
flux get kustomizations -A
flux get helmreleases -A

# Inspect a specific resource for reconciliation status
flux get kustomization <name> -n <namespace> -o yaml
flux get helmrelease <name> -n <namespace> -o yaml
```

```bash
# Use flux diff to compare cluster state vs Git/source (detects drift)
flux diff kustomization <name> -n <namespace>
flux diff helmrelease <name> -n <namespace>
flux diff source gitrepository <repo-name> -n flux-system
```

```bash
# Remediate detected drift by forcing reconciliation from source
flux reconcile kustomization <name> -n <namespace> --with-source
flux reconcile helmrelease <name> -n <namespace>
# Reconcile source if Git/Helm repository changes need to be refreshed
flux reconcile source git <repo-name> -n flux-system
```

Interpretation and guidance:
- If flux diff shows differences, those are drifted resources (cluster != Git/source).
- Reconcile to reapply Git-desired state; if the drift is intentional, update the Git source instead of reconciling.
- Use consistent Kustomization/HelmRelease intervals and automation to reduce manual drift.
- Review Flux resource status (conditions and lastApplied/lastAttempted revisions) to determine why reconciliation failed and whether source updates are required.
- Consider adding alerting around failed reconciliations or large diffs to catch drift early.

### 2. Immutable Field Updates

Handle immutable field errors:

```bash
# Common immutable fields that cause issues:
# - Pod selectors in Deployments
# - Service ClusterIP
# - PVC storage size (depending on storage class)

# Solution: Delete and recreate the resource
kubectl delete deployment <deployment-name> -n <namespace>
# Flux will recreate based on GitOps
```

### 3. Helm Value Validation

Validate Helm values before deployment:

```bash
# Dry-run Helm install
helm install <release-name> <chart> --dry-run --debug --values values.yaml

# Template and validate manifests
helm template <release-name> <chart> --values values.yaml | kubectl apply --dry-run=client -f -
```

## Advanced Debugging

### 1. Debug Containers

Use debug containers for deeper investigation:

```bash
# Create debug container
kubectl debug <pod-name> -n <namespace> -it --image=busybox

# Debug with specific tools
kubectl debug <pod-name> -n <namespace> -it --image=nicolaka/netshoot
```

### 2. Package-Specific Issues

**Image Pull Problems**:
```bash
# Check image pull secrets
kubectl get secrets -n <namespace> | grep docker

# Verify registry access
kubectl describe pod <pod-name> -n <namespace>
```

**Init Container Failures**:
```bash
# Check init container logs
kubectl logs <pod-name> -n <namespace> -c <init-container-name>

# Check init container status
kubectl describe pod <pod-name> -n <namespace>
```

### 3. Rollback Procedures

When issues persist, consider rollback:

```bash
# Rollback Helm release
helm rollback <release-name> <revision> -n <namespace>

# Rollback via Flux (revert Git commit)
git revert <commit-hash>
git push origin main
```

## Escalation and Support

### 1. Gather Debug Information

Before escalating, collect:

```bash
# Create debug bundle
kubectl cluster-info dump --output-directory=./debug-info

# Export relevant logs
kubectl logs -n <namespace> --all-containers --prefix=true > package-logs.txt

# Export events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > events.txt
```

### 2. Community Resources

- Check Big Bang documentation and troubleshooting guides
- Search Big Bang GitLab issues for similar problems
- Engage with the Big Bang community for complex issues
- Review package-specific documentation and upstream issues

### 3. Preventive Measures

- Implement comprehensive monitoring and alerting
- Use staging environments for testing changes
- Regularly review and update package configurations
- Maintain backup and restore procedures
- Document custom configurations and known issues

Remember to always test fixes in a non-production environment first and maintain detailed logs of troubleshooting steps for future reference.
