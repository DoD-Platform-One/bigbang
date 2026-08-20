# Disconnected Environments

[[_TOC_]]

A disconnected Big Bang deployment requires operators to mirror and serve every dependency inside the security boundary. Big Bang does not create the registry, Git/OCI service, certificate authority, DNS, or transfer process used by the environment.

## Plan the Dependency Set

Build the inventory from the exact Big Bang release and values that will be deployed. Include:

- The Big Bang source or chart and the matching `base/flux` controller manifests.
- Every enabled package chart or Git source, including transitive chart dependencies.
- Every container image and init-container image rendered by those packages.
- Image-signing keys or attestations required by configured verification policies.
- External files used by Helm values, Kustomize, SOPS, policies, dashboards, or jobs.

Do not reuse an inventory from a different Big Bang release or from default values if the target environment enables additional packages. Preserve checksums and provenance through the approved transfer process.

## Provide Internal Services

Before deployment, make the mirrored dependencies available through services reachable from the cluster and Flux controllers:

- A container registry trusted by every node runtime.
- Git, Helm, or OCI endpoints matching the configured package source types.
- DNS and certificate chains for those endpoints.
- Credentials with the minimum required read access.

Test access from both a cluster node and a pod. A successful workstation login does not prove that the node runtime or Flux controller trusts the endpoint.

## Configure Big Bang

Point `registryCredentials` and each package source at the internal services. If packages use OCI charts, define their internal repositories through `helmRepositories` and set each package's `sourceType` and `helmRepo` values accordingly.

The global `offline` value has a narrow purpose:

```yaml
offline: true
```

When `offline` is `true`, the chart does not create package `GitRepository` resources. The referenced source objects must already exist with the expected names and namespaces. This setting does not mirror artifacts, rewrite URLs, disable network access, or make an otherwise connected configuration suitable for a disconnected cluster.

Review the current generated [configuration reference](../../configuration/base-config.md) and rendered manifests for the selected release; package source fields vary by source type.

## Install and Validate

1. Install Flux from the selected release's local [`base/flux`](../../../base/flux) manifests.
2. Create the required repository and registry credentials using the environment's encrypted-secret workflow.
3. Reconcile the Big Bang source and `HelmRelease`.
4. Confirm that every source and release is ready:

   ```shell
   flux check
   flux get sources all -A
   flux get helmreleases -A
   ```

5. Verify workloads, persistent storage, ingress, authentication, policies, and application smoke tests.
6. Enforce the intended egress restrictions and repeat reconciliation and restart tests. This catches dependencies that were satisfied accidentally through an external route or a node cache.

## Upgrade Procedure

Treat each upgrade as a new dependency set:

1. Diff the target release, enabled-package versions, and rendered images against the deployed release.
2. Mirror and verify all new artifacts before changing Git desired state.
3. Test the upgrade and rollback procedure in a representative disconnected environment.
4. Transfer the approved artifacts and configuration through the controlled boundary.
5. Upgrade using the normal GitOps process and follow [upgrade troubleshooting](../../operations/troubleshooting/upgrades.md) if reconciliation fails.

Never point a disconnected production environment at a moving branch or depend on a developer workstation, public image cache, or undocumented proxy to complete reconciliation.
