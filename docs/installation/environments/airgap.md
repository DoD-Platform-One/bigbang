# Disconnected Environments

[[_TOC_]]

A disconnected Big Bang deployment requires operators to mirror and serve every dependency inside the security boundary. Big Bang does not create the registry, Git/OCI service, certificate authority, DNS, or transfer process used by the environment.

For a worked path through this — importing a release's images and charts into a registry and pointing Big Bang at them — see [Disconnected Environments with Hauler](airgap-hauler.md). Releases ship `bb-<tag>-images-charts.tar.zst`, a prebuilt form of the inventory described below that also carries the signing material noted in it.

## Plan the Dependency Set

Build the inventory from the exact Big Bang release and values that will be deployed. Include:

- The Big Bang source or chart and the matching `base/flux` controller manifests, which pin Flux's own controller images. No package renders those, so an inventory assembled only from package output will omit them and Flux will not start.
- Every enabled package chart or Git source, including transitive chart dependencies.
- Every container image and init-container image rendered by those packages.
- Image-signing keys or attestations required by configured verification policies.
- External files used by Helm values, Kustomize, SOPS, policies, dashboards, or jobs.

Each release publishes `images-v2-with-dependencies.txt` and `oci_package_list.txt`, which already account for everything above including the Flux controllers. Prefer them to a hand-assembled inventory.

Do not reuse an inventory from a different Big Bang release or from default values if the target environment enables additional packages. Preserve checksums and provenance through the approved transfer process.

## Provide Internal Services

Before deployment, make the mirrored dependencies available through services reachable from the cluster and Flux controllers:

- A container registry trusted by every node runtime.
- Git, Helm, or OCI endpoints matching the configured package source types.
- DNS and certificate chains for those endpoints.
- Credentials with the minimum required read access.

Test access from both a cluster node and a pod. A successful workstation login does not prove that the node runtime or Flux controller trusts the endpoint.

## Configure Big Bang

Charts and images reach the internal services by different routes, and only one of them is configured here.

**Charts are configured here.** Define internal repositories through `helmRepositories` and set each package's `sourceType` and `helmRepo` values accordingly. Flux fetches charts itself, so values are sufficient for them.

**Images are not.** Big Bang has no umbrella-level image-registry rewrite, so rendered pod specs keep naming `registry1.dso.mil` until something outside the chart changes them. `registryCredentials` does not do this — it builds the imagePullSecret for whatever registry the references already name, so it authenticates but does not redirect. Point it at the registry images are pulled from once they have been redirected, not instead of redirecting them.

Two mechanisms redirect them, compared in [Choosing an image mechanism](airgap-hauler.md#choosing-an-image-mechanism):

- Rewriting references at admission with `MutatingAdmissionPolicy`, stable in Kubernetes 1.36 and the only option on managed control planes.
- A containerd registry mirror, which works on any Kubernetes version but requires node-level configuration.

If policy enforcement is enabled, Kyverno validates *after* an admission rewrite, so `restrict-image-registries` must permit the registry the references were rewritten to.

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
