# GitOps Workflow

Big Bang implements GitOps principles using Flux CD to manage the deployment and lifecycle of Kubernetes applications. This document outlines the GitOps workflow, best practices, and operational procedures for managing Big Bang deployments.

## GitOps Principles

GitOps is a declarative approach to continuous deployment that uses Git as the single source of truth for infrastructure and application configuration. The core principles include:

- **Declarative**: The entire system is described declaratively
- **Versioned and Immutable**: All changes are versioned in Git and immutable
- **Pulled Automatically**: Software agents automatically pull desired state from Git
- **Continuously Reconciled**: Actual state is continuously reconciled with desired state

## Big Bang GitOps Architecture

Big Bang uses Flux CD v2 as its GitOps engine. For detailed information about why Flux was chosen over other GitOps engines, see [GitOps Engines](git-ops-engine.md).

### Flux CD Components

Big Bang leverages these Flux CD v2 controllers:

- **Source Controller**: Manages Git repositories and OCI artifacts
- **Kustomize Controller**: Applies Kustomize configurations
- **Helm Controller**: Manages Helm releases with native Helm support
- **Notification Controller**: Sends alerts and notifications

### Repository Structure

A typical Big Bang deployment follows this repository structure:

```
big-bang-deployment/
├── base/                          # Base configurations
│   ├── flux-system/              # Flux system components
│   └── bigbang/                  # Big Bang core configuration
├── dev/                          # Development environment
│   ├── configmap.yaml
│   ├── kustomization.yaml
│   └── values.yaml
├── prod/                         # Production environment
│   ├── configmap.yaml
│   ├── kustomization.yaml
│   └── values.yaml
└── README.md                     # Environment documentation
```

## Configuration Management

### Environment-Specific Values

Each environment uses Kustomize overlays to manage configuration:

**Base Configuration** (`base/bigbang/bigbang.yaml`):
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: bigbang
  namespace: bigbang
spec:
  interval: 5m
  chart:
    spec:
      chart: ./chart
      sourceRef:
        kind: GitRepository
        name: bigbang
        namespace: bigbang
  valuesFrom:
    - kind: ConfigMap
      name: environment-config
```

**Environment Overlay** (`dev/kustomization.yaml`):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: bigbang

resources:
  - ../base/bigbang

configMapGenerator:
  - name: environment-config
    files:
      - values.yaml=values.yaml

generatorOptions:
  disableNameSuffixHash: true
```

**Environment Values** (`dev/values.yaml`):
```yaml
domain: dev.bigbang.mil

istio:
  enabled: true

monitoring:
  enabled: true

addons:
  gitlab:
    enabled: true
    values:
      global:
        hosts:
          domain: dev.bigbang.mil
```

## Development Workflow

### 1. Feature Development

```bash
# Clone your Big Bang configuration repository
git clone https://repo1.dso.mil/your-org/your-bigbang-config.git
cd your-bigbang-config

# Create feature branch
git checkout -b feature/enable-argocd

# Make configuration changes
vim dev/values.yaml

# Test changes locally (optional)
kubectl apply --dry-run=client -k dev/

# Commit changes
git add .
git commit -m "feat: enable ArgoCD addon in dev environment"

# Push and create merge request
git push origin feature/enable-argocd
```

### 2. Code Review Process

Before merging changes:

- **Automated Validation**: CI/CD pipelines validate configuration syntax
- **Security Scanning**: Policies are validated against security requirements
- **Peer Review**: Configuration changes are reviewed by team members
- **Environment Testing**: Changes are tested in development environment first

### 3. Deployment Process

Once changes are merged to the main branch:

1. **Flux Detection**: Source Controller detects Git repository changes
2. **Reconciliation**: Helm Controller pulls updated configurations
3. **Application**: Changes are applied to the Kubernetes cluster
4. **Notification**: Status updates are sent via configured channels

## Branch Strategies

### Recommended: Environment Directories

Use a single branch with environment-specific directories:

```
main
├── dev/           # Development configuration
├── staging/       # Staging configuration
└── prod/          # Production configuration
```

**Benefits**:
- Single source of truth
- Easy configuration comparison
- Simplified promotion process
- Reduced merge conflicts

### Environment Promotion

Promote configurations through environments by copying validated configurations:

```bash
# After dev testing is complete
cp dev/values.yaml staging/values.yaml

# Update staging-specific values
vim staging/values.yaml

# Commit staging deployment
git add staging/
git commit -m "promote: deploy validated config to staging"

# After staging validation
cp staging/values.yaml prod/values.yaml

# Update production-specific values (domains, replicas, etc.) or have additional files per environment
vim prod/values.yaml

# Commit production deployment
git add prod/
git commit -m "promote: deploy to production"
```

## Operational Procedures

### Monitoring GitOps Health

**Check Flux Status**:
```bash
# Overall Flux health
flux check

# Check all Flux resources
flux get all

# Check specific GitRepository
flux get source git bigbang

# Check Big Bang HelmRelease
flux get helmrelease bigbang -n bigbang
```

**Monitor via Grafana**:
- Use Flux Control Plane dashboard
- Monitor GitOps reconciliation metrics
- Set up alerts for failed reconciliations

### Manual Reconciliation

Force immediate reconciliation when needed:

```bash
# Force source reconciliation
flux reconcile source git bigbang

# Force Big Bang HelmRelease reconciliation
flux reconcile helmrelease bigbang -n bigbang

# Check reconciliation status
flux get helmrelease bigbang -n bigbang
```

### Configuration Validation

Validate changes before applying:

```bash
# Dry-run Kustomize build
kubectl apply --dry-run=client -k dev/

# Diff against current state
flux diff kustomization dev-bigbang

# Validate Helm values
helm template bigbang ./chart --values dev/values.yaml --dry-run
```

## Troubleshooting GitOps Issues

### Common Issues

**Repository Access Problems**:
```bash
# Check GitRepository status
kubectl describe gitrepository bigbang -n bigbang

# Verify SSH key or token access
kubectl get secret flux-system -n flux-system
```

**Reconciliation Failures**:
```bash
# Check controller logs
kubectl logs -n flux-system deployment/helm-controller
kubectl logs -n flux-system deployment/source-controller

# Check events
kubectl get events -n bigbang --sort-by='.lastTimestamp'
```

**Helm Release Issues**:
```bash
# Check HelmRelease status
kubectl describe helmrelease bigbang -n bigbang

# Check Helm release directly
helm list -n bigbang
helm status bigbang -n bigbang
```

For detailed troubleshooting guidance, see [Package Troubleshooting](../operations/troubleshooting/packages.md).

## Security Best Practices

### Repository Security

1. **Access Control**: Use branch protection and required reviews
2. **Signed Commits**: Require GPG signed commits for production
3. **Secret Management**: Never commit secrets to Git repositories
4. **Audit Trail**: Enable comprehensive Git audit logging

### Runtime Security

1. **RBAC**: Configure minimal necessary permissions for Flux
2. **Network Policies**: Restrict Flux controller network access
3. **Image Scanning**: Scan all container images before deployment
4. **Policy Enforcement**: Use Kyverno policies to validate configurations

### Secret Management

Use external secret management instead of committing secrets:

```yaml
# Example: External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: bigbang
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "bigbang"
```

## Integration with CI/CD

### Automated Validation Pipeline

```yaml
# Example GitLab CI configuration
stages:
  - validate
  - security
  - deploy

validate-config:
  stage: validate
  script:
    - flux check --pre
    - kubectl apply --dry-run=client -k dev/
    - kubectl apply --dry-run=client -k prod/

security-scan:
  stage: security
  script:
    - conftest verify --policy policies/ dev/values.yaml
    - conftest verify --policy policies/ prod/values.yaml
```

### Automated Promotion

Use merge requests to promote between environments:

1. **Development**: Direct commits to `main` deploy to dev
2. **Staging**: Manual promotion via copying dev config
3. **Production**: Approval-required promotion with additional validation

## Best Practices

### Configuration Management

1. **Environment Parity**: Keep environments as similar as possible
2. **Gradual Rollouts**: Test in dev before promoting to production
3. **Version Pinning**: Use specific versions for production deployments
4. **Documentation**: Document all configuration decisions

### Operational Excellence

1. **Monitoring**: Monitor GitOps pipeline health continuously
2. **Alerting**: Set up alerts for failed reconciliations
3. **Backup**: Regularly backup Git repositories
4. **Recovery**: Test disaster recovery procedures

### Team Collaboration

1. **Training**: Ensure team understanding of GitOps principles
2. **Documentation**: Maintain clear operational procedures
3. **Communication**: Use Git commits and merge requests for change tracking
4. **Reviews**: Implement mandatory code reviews for all changes

## Getting Started

To implement this GitOps workflow:

1. **Fork Template**: Use the [Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template) as starting point
2. **Configure Environments**: Set up dev, staging, and production directories
3. **Deploy Flux**: Install Flux in your cluster pointing to your repository
4. **Test Workflow**: Make a small configuration change and verify deployment

For detailed setup instructions, refer to the customer template README and the [Installation documentation](../installation/).

## Conclusion

GitOps with Flux CD provides a robust, secure, and scalable approach to managing Big Bang deployments. By following these workflows and best practices, teams can achieve reliable, auditable, and efficient deployment processes while maintaining security and compliance requirements.
