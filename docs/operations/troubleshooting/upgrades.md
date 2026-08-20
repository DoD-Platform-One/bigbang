# Troubleshoot Upgrades

Treat an upgrade failure as a reconciliation failure: determine which Flux resource stopped becoming ready, read its status and events, correct the desired state in Git, and reconcile again.

## 1. Find the Failing Layer

Start with the Flux controllers and then move from the Big Bang source and release to the package releases:

```shell
flux check
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
```

The first non-ready resource usually identifies the layer to investigate:

| Status | Investigate |
| --- | --- |
| Big Bang `GitRepository` not ready | Repository URL/ref, credentials, certificate trust, egress, or an unavailable artifact |
| Environment `Kustomization` not ready | SOPS decryption, build errors, missing resources, or invalid manifests |
| Big Bang `HelmRelease` not ready | Big Bang values/schema errors, Kubernetes compatibility, rendering, or chart upgrade hooks |
| Package `GitRepository` not ready | Package version/ref, credentials, network access, or source verification |
| Package `HelmRelease` not ready | Package values, dependencies, hooks, immutable fields, storage, or workload health |

Do not assume the last package shown by `flux get` caused the failure; use its Ready condition and events.

## 2. Read Conditions and Events

Set the affected namespace and release name, then inspect the complete status:

```shell
kubectl describe helmrelease RELEASE_NAME -n RELEASE_NAMESPACE
kubectl get helmrelease RELEASE_NAME -n RELEASE_NAMESPACE -o yaml
kubectl get events -n RELEASE_NAMESPACE --sort-by=.lastTimestamp
```

For source failures, run the equivalent commands against `gitrepository`. For environment reconciliation failures, inspect `kustomization`.

Controller logs can add detail that was truncated in a condition:

```shell
flux logs --kind=HelmRelease --name=RELEASE_NAME \
  --namespace=RELEASE_NAMESPACE --since=30m
```

Also review the Big Bang release notes and the affected package's changelog for required value migrations, removed APIs, and upgrade ordering.

## 3. Correct the Desired State

Make the correction in the environment repository. Common corrections include:

- Updating a renamed or removed chart value.
- Selecting a package version compatible with the target Big Bang and Kubernetes releases.
- Restoring repository or registry credentials and certificate authorities.
- Providing storage, scheduling capacity, or permissions required by an upgrade hook.
- Removing an environment patch that targets a resource or field no longer rendered.

Avoid `helm upgrade`, hand-editing a Flux-managed object, or deleting persistent resources as a first response. Those actions create drift or data-loss risk and Flux may immediately reverse them.

## 4. Reconcile in Dependency Order

After committing and pushing the correction, reconcile the source before the affected release:

```shell
flux reconcile source git SOURCE_NAME -n SOURCE_NAMESPACE
flux reconcile helmrelease RELEASE_NAME -n RELEASE_NAMESPACE --with-source
```

If an environment `Kustomization` owns the changed values, reconcile it before the HelmRelease:

```shell
flux reconcile kustomization KUSTOMIZATION_NAME -n KUSTOMIZATION_NAMESPACE --with-source
```

## 5. Verify Recovery

```shell
flux get all -A
kubectl get pods -A
```

Confirm that the affected release has a current Ready condition, its workloads are healthy, and application-level smoke tests pass. A successful Helm action alone does not prove that data migrations, ingress, authentication, or package integrations work.

If automatic remediation or rollback also fails, preserve the controller events and logs before making further changes. Consult the current Flux [HelmRelease troubleshooting guidance](https://fluxcd.io/flux/components/helm/helmreleases/) and the package's recovery procedure, especially before changing or restoring persistent data.
