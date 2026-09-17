# Migrating to a Permanent Registry

[[_TOC_]]

[Disconnected Environments with Hauler](airgap-hauler.md) ends with a working cluster and
a caveat: `hauler store serve registry` is one process serving local disk, and for a
long-lived cluster you should import into a real registry instead. This guide is how you
get from one to the other, using the Harbor that Big Bang itself ships.

It assumes you have finished that guide — the archive is loaded, `hauler store serve` is
running, and Big Bang is deployed with image references rewritten at admission to the
serving host. If you imported into an existing registry rather than serving one, you have
already arrived and this guide is not for you.

Throughout, `hauler.example.mil:5000` stands for the bootstrap registry you are leaving
and `harbor.example.mil` for the Harbor you are moving to. `<tag>` is the Big Bang
release.

The work is in four parts: [stand Harbor up](#1-stand-harbor-up-from-the-bootstrap-registry),
[seed it](#2-seed-harbor-from-the-store), [repoint the cluster](#3-repoint-in-this-order),
and [retire the bootstrap registry](#4-retire-the-bootstrap-registry). The ordering in
part 3 is not cosmetic — getting it wrong denies every new pod at admission.

## Prerequisites

- A cluster running Big Bang from a hauler-served registry, per
  [Disconnected Environments with Hauler](airgap-hauler.md)
- The content store still on disk. Part 2 pushes from the **store**, not from the
  serving registry, so do not delete it yet
- Persistent storage for Harbor, and a TLS certificate for it
- Somewhere durable and off-cluster to keep `bb-<tag>-images-charts.tar.zst`. See
  [The archive is your disaster recovery](#the-archive-is-your-disaster-recovery)

## 1. Stand Harbor up from the bootstrap registry

Harbor is a Big Bang package, so it deploys the same way everything else does:

```yaml
addons:
  harbor:
    enabled: true
    sourceType: "helmRepo"
```

**The chart and images are already in the archive**, even though `addons.harbor` defaults
to `enabled: false`. It is reasonable to assume a disabled package was excluded — it was
not. The image list is built across every package regardless of enablement, so
`harbor:<version>` and its `goharbor/*` images shipped with the release you already have.
Nothing needs to be fetched.

`sourceType` matters as much as `enabled`: every package defaults to `"git"`, which would
send Flux to repo1 for the chart instead of to your registry.

At this point there is no circular dependency. The admission policy still rewrites to
`hauler.example.mil:5000`, so Harbor's own images come from the bootstrap registry like
everything else.

Size the volume with the whole archive in mind, not just Harbor: a Big Bang release is
roughly 26 GB once expanded into a registry, and you will want headroom for the next
release before you delete the last one.

Wait for Harbor to be genuinely healthy — reachable, logged into, and serving — before
continuing. Everything after this point depends on it.

## 2. Seed Harbor from the store

Create the `ironbank` and `bigbang` projects first. Harbor treats the first path segment
as a project and will not create one on push; see
[Harbor: create the projects first](airgap-hauler.md#harbor-create-the-projects-first)
for the full list and the single-project alternative.

Then push, with the same command that seeded the bootstrap registry:

```shell
hauler store copy registry://harbor.example.mil
```

Two things worth knowing:

- **This reads from the content store, not from the running registry.** The store has to
  still be on disk. If you already cleaned it up, `hauler store load -f
  bb-<tag>-images-charts.tar.zst` rebuilds it from the archive.
- **Cosign signatures and attestations come along.** They were carried into the store by
  the original `hauler store sync`, so Harbor inherits verifiable provenance rather than
  bare images. See
  [Verifying signatures](airgap-hauler.md#verifying-signatures).

## 3. Repoint, in this order

The order is the point of this section. Each step assumes the one before it.

### Kyverno first

Add Harbor to the allowlist **before** anything rewrites to it, keeping the bootstrap
registry allowed until the cutover is complete:

```yaml
kyvernoPolicies:
  values:
    policies:
      restrict-image-registries:
        parameters:
          allow:
            - hauler.example.mil:5000
            - harbor.example.mil
```

`MutatingAdmissionPolicy` is a mutating plugin and runs before Kyverno's validating
webhook, so Kyverno inspects the image *after* rewriting. Flip the rewrite first and
every new pod is denied with `restrict-image-registries: 'Image registry is not in the
approved list.'` Big Bang merges this into the default allowlist rather than replacing
it, so the DoD registries stay permitted. See
[Kyverno: allowlist the destination, not the source](airgap-hauler.md#kyverno-allowlist-the-destination-not-the-source).

Keep `hauler.example.mil:5000` in the list throughout the transition. Big Bang retains
the default registries, not previous custom allowlist entries; removing Hauler now
would deny new pods while the rewrite still targets it. Remove it only in part 4.

### Then the admission policy

Change the destination in the `MutatingAdmissionPolicy` from
[Images, option A](airgap-hauler.md#images-option-a-rewrite-at-admission-recommended):

```yaml
    - name: dst
      expression: '"harbor.example.mil/"'
```

Existing pods keep running with their old references — nothing re-pulls an image it
already has. The change takes effect as workloads churn.

### Then the charts

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://harbor.example.mil/bigbang"
    type: "oci"
    existingSecret: "harbor-credentials"
```

**Authentication changes here, and it is easy to miss.** `hauler store serve` has no
authentication at all; Harbor does. The chart path now needs real credentials, and if
Harbor's certificate is signed by a private CA, source-controller needs that CA too — it
runs as a pod, so the node trust store does not reach it. Put `ca.crt` alongside the
credentials in the same secret: use an `Opaque` Secret with `username` and `password`, or
a `kubernetes.io/dockerconfigjson` Secret with `.dockerconfigjson`. See
[TLS is required for an OCI chart registry](airgap-hauler.md#tls-is-required-for-an-oci-chart-registry).

Set `registryCredentials` to Harbor as well, so the kubelet can authenticate the rewritten
image pulls:

```yaml
registryCredentials:
  registry: harbor.example.mil
  username: <username>
  password: <password>
```

Let Flux reconcile, then confirm the cluster is actually pulling from Harbor before you
tear anything down — [Verify it came from your registry](airgap-hauler.md#3-verify-it-came-from-your-registry)
applies unchanged, with Harbor's logs in place of the bootstrap registry's.

## 4. Retire the bootstrap registry

Stop `hauler store serve`, and drop `hauler.example.mil:5000` from the Kyverno allowlist.

**Do not keep it running permanently as a fallback.** The failure it would guard against
needs two things at once: Harbor fully down, *and* the node that has to start a pod
lacking the image layers. Containerd's content store lives on disk and survives reboots,
and the kubelet will not garbage-collect images belonging to running pods, so in practice
that means a disaster-recovery rebuild or a scale-out onto a fresh node during a Harbor
outage. Standing infrastructure maintained forever is the wrong shape for a rare event
the archive already covers.

## Operating it

This part matters more than the migration itself.

### Harbor is now a single point of failure for image pulls

Not just for itself — for everything. Once every reference rewrites to Harbor, any node
that needs any image it has not cached is stuck while Harbor is down. Harbor depending on
Harbor for its own images is one instance of that, not a special case.

So put the effort where it pays: replica count, durable and backed-up storage, and
replicas not all landing on one node. Solve Harbor's availability and its self-reference
stops being interesting.

### The archive is your disaster recovery

Keep `bb-<tag>-images-charts.tar.zst` somewhere durable and off-cluster, permanently. It
is not a transit format you discard after import. With Harbor on in-cluster volumes,
losing that storage loses both your registry and the means to rebuild it.

If you have to rebuild, the runbook is
[part 1 of the hauler guide](airgap-hauler.md#1-import-the-archive-into-your-registry)
followed by this one:

1. `hauler store load` and `hauler store serve registry` again
2. Bring the cluster up with the policy pointing at the serving host
3. Stand Harbor up, seed it, repoint

**The ordering trap is the same one, inverted:** do not start a rebuild with the policy
pointing at Harbor. Nothing can be admitted until Harbor is running, and Harbor cannot
start, because it is waiting on itself. Begin recovery exactly as the first install did.

### Later releases are the same command

Migration is repeatable, not one-shot. For the next Big Bang release, load the new archive
and run `hauler store copy registry://harbor.example.mil` again. No repointing — the
cluster is already looking at Harbor. The one-time work was the projects, the credentials,
and the decision in part 4.

### Optional: preload Harbor's images onto nodes

If you already build your own node images, importing Harbor's `goharbor/*` images into
containerd at build time means `IfNotPresent` always hits and a rebuild never needs the
archive to get Harbor running:

```shell
ctr -n k8s.io images import <harbor-images>.tar
```

This is worth doing only if you have that pipeline already; it has to be repeated whenever
the node image is rebuilt. Skip it otherwise and rely on the recovery runbook above.

### One edge worth knowing

If Harbor is scaled to zero for long enough that its images count as unused, and a node
then comes under disk pressure, the kubelet can garbage-collect them. Narrow, but it is
the one way the cache disappears without a rebuild. Accept it knowingly rather than
discover it.
