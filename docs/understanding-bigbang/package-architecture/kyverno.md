# Kyverno

## Overview

Kyverno is a policy engine designed for Kubernetes, where policies are managed as Kubernetes resources rather than with some domain-specific language. Kyverno policies can be managed by kubectl, git, and kustomize just like app deployments. Kyverno policies can validate, mutate, and generate Kubernetes resources plus ensure OCI image supply chain security, among other things.

## Big Bang Touch Points

### Architecture: 
- [How Kyverno works](https://kyverno.io/docs/introduction/#how-kyverno-works)

### Storage

Data from Kyverno is not stored by the app directly, it is stored as objects in the Kubernetes API.

### Istio Configuration

When deploying to k3d, istio-system should be added from `excludedNamespaces` under the `allowedDockerRegistries` violations. This can be done by modifying `chart/values.yaml` file or passing an override file with the values set as seen below. This is for development purposes only: production should not allow containers in the `istio-system` namespace to be pulled from outside of Registry1. 

```yaml
kyvernopolicies:
  values:
    exclude:
      any:
      # Allows k3d load balancer to bypass policies.
      - resources:
          namespaces:
          - istio-system
          names:
          - svclb-*
```

## High Availability

High availability is accomplished by increasing the replicas in the values file of this helm chart. The recommended replica counts for HA is at least 3 which is enabled by default in BigBang chart.

```yaml
kyverno:
  values:
    replicaCount: 3
```

## Single Sign on (SSO)

None. This service doesn't have a web interface.

## Licencing

[Apache 2.0 License](https://github.com/kyverno/kyverno/blob/main/LICENSE)

## Dependencies

kyverno is a dependency of kyvernopolicies. KyvernoPolicies is a collection of Kyverno security and best-practice policies for Kyverno
