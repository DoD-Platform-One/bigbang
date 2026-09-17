# Disconnected Environments with Hauler

[[_TOC_]]

Big Bang releases ship `bb-<tag>-images-charts.tar.zst`, a
[Hauler](https://github.com/hauler-dev/hauler) content archive holding every
container image Big Bang needs plus the OCI-published Big Bang Helm charts. It is
an alternative to `images.tar.gz`, which remains available and unchanged.

Use this guide if your environment has a registry (Harbor, Artifactory, Nexus, or any
OCI registry) to import into — or if it has none, since hauler can
[serve the archive as a registry itself](#no-registry-serve-one-from-the-archive). For
the general disconnected picture — what has to exist inside the boundary before any of
this matters — see [Disconnected Environments](airgap.md).

The work is in three parts: [import the archive](#1-import-the-archive-into-your-registry),
[point Big Bang at your registry](#2-point-big-bang-at-your-registry), and
[verify what the cluster actually pulled](#3-verify-it-came-from-your-registry).

Throughout, `registry.example.mil` stands for your registry and `<tag>` for the Big Bang
release you are installing. Substitute your own.

## Prerequisites

- The [`hauler` CLI](https://github.com/hauler-dev/hauler/releases) on the high side.
  Optional — see [Without the hauler CLI](#without-the-hauler-cli) if you cannot
  install it and would rather use `skopeo`.
- A registry you can push to, and credentials for it — or none, if you serve the
  archive with `hauler store serve registry` instead
- Roughly 2x the archive size in free disk for the unpacked store

On the cluster side, how you get images out of that registry depends on what you can
change — decide this before you start, because it affects the install order:

- **Kubernetes 1.36+**, and you can rewrite image references at admission. This is the
  recommended path and the only one available on managed control planes.
- **Root access to every node**, and you can configure a containerd registry mirror
  instead. Works on any Kubernetes version; not available on EKS managed node groups
  without launch template user data, or on Fargate at all.

## 1. Import the archive into your registry

### Download and verify

Download `bb-<tag>-images-charts.tar.zst` and the release checksums file from
the [release page](https://repo1.dso.mil/big-bang/bigbang/-/releases).

The release page always lists the archive; on the rare release where it failed to
build, that link returns 404. Confirm the file actually appears in the checksums
manifest before trusting it — `--ignore-missing` reports success for a file it
never checked.

```shell
grep images-charts bigbang-<tag>_checksums.txt
sha256sum -c bigbang-<tag>_checksums.txt --ignore-missing
```

### Load and push

The archive is named for its release, so `-f` is required — `hauler store load`
on its own looks for hauler's default `haul.tar.zst` and will not find it.

```shell
hauler store load -f bb-<tag>-images-charts.tar.zst
hauler login registry.example.mil -u <username> --password-stdin < token.txt
hauler store copy registry://registry.example.mil
```

`-p <password>` works too, but puts the credential in your shell history.

### Where the images land

Hauler strips the source registry host and preserves the rest of the repository
path, so an image published as

```
registry1.dso.mil/ironbank/big-bang/base:2.1.0
```

lands in your registry as

```
registry.example.mil/ironbank/big-bang/base:2.1.0
```

Nothing in Big Bang points at that path yet — that is what
[part 2](#2-point-big-bang-at-your-registry) does. If you are migrating from the older
`images.tar.gz` flow, compare a few entries against your current registry before
switching over.

### Harbor: create the projects first

Harbor treats the first path segment as a **project** and will not create one
automatically. Create the projects matching the top-level path segments in
`images-v2-with-dependencies.txt` and `oci_package_list.txt` — `ironbank` and
`bigbang` always, plus `gitlab` if you enable the GitLab package — before
running `hauler store copy`, or the pushes will fail with permission errors.

If you need everything under a *single* Harbor project instead, see
[Harbor under a single project](#harbor-under-a-single-project); that layout only
works with the registry-mirror approach.

### ECR: create the repositories first

ECR does not create repositories on push. Unless a repository creation template
matches, the push fails. Before `hauler store copy`, either pre-create every repository
or add a repository creation template with **Applied for: `CREATE_ON_PUSH`** and prefix
`ROOT`. This is a one-time registry setting, and the archive contains roughly 190
repositories.

ECR also constrains which rewriting mechanism you can use later — see
[AWS: EKS and ECR](#aws-eks-and-ecr).

### Self-signed registry certificates

```shell
hauler store copy registry://registry.example.mil --insecure
```

### No registry? Serve one from the archive

If there is no registry to import into, hauler will run one over the store it just
loaded. `hauler store serve registry` copies the store into a
[distribution](https://github.com/distribution/distribution) registry and serves it on
port 5000, read-only:

```shell
hauler store load -f bb-<tag>-images-charts.tar.zst
hauler store serve registry \
  --tls-cert /etc/ssl/certs/registry.crt \
  --tls-key /etc/ssl/private/registry.key
```

The repository paths are identical to those in
[Where the images land](#where-the-images-land) — it is the same `registry://` copy — so
everything in [part 2](#2-point-big-bang-at-your-registry) applies unchanged, with the
serving host in place of `registry.example.mil`.

Four things to know before you rely on it:

- **Pass the TLS flags for charts.** They are optional, and without them the registry is
  plain HTTP, which Flux will not use for OCI charts. See
  [TLS is required for an OCI chart registry](#tls-is-required-for-an-oci-chart-registry).
  Images are less picky — a containerd mirror can be pointed at an HTTP endpoint.
- **There is no authentication.** Anything that can reach the port can pull the whole
  archive. Put it where only the cluster can, and leave `registryCredentials: null`.
- **It must be reachable from every node**, so it belongs on a host inside the boundary
  rather than on the workstation you unpacked the archive on.
- **It is one process serving local disk** — no replication, no failover, and the store
  has to stay on that disk. That suits an appliance or edge install; for a long-lived
  cluster, import into a real registry — see
  [Migrating to a Permanent Registry](airgap-registry-migration.md) for moving to the
  Harbor Big Bang ships once the cluster is up.

## 2. Point Big Bang at your registry

Getting the archive into your registry is only half the job. Big Bang will not use it
until you tell it to, and **images and charts reach the registry by two different
routes**. Getting this wrong is the most common failure here:

| | Fetched by | Configured with |
|---|---|---|
| **Images** | kubelet/containerd, per node | admission-time rewriting, or a registry mirror |
| **Charts** | Flux source-controller, over HTTP | Big Bang **values** |

Neither substitutes for the other.

> **`registryCredentials` does not rewrite image references.** It only builds the
> imagePullSecret. Setting `registryCredentials.registry` to your registry will not move
> a single image pull, and the pods will sit in `ImagePullBackOff` while every rendered
> manifest looks correct.

### Choosing an image mechanism

| | Admission policy | Registry mirror |
|---|---|---|
| Node-level configuration | none | required, on every node |
| Managed control planes, Fargate | works (Kubernetes 1.36+) | not available |
| Kyverno allowlist override | required | not needed |
| Image refs in pod specs | rewritten to your registry | unchanged |
| Apply order matters | yes — before any workload is admitted | no |

### Images, option A: rewrite at admission (recommended)

`MutatingAdmissionPolicy` is stable and enabled by default in **Kubernetes 1.36+**. It
runs inside the API server, so there is no webhook to operate and no policy engine to
install, and it rewrites at pod admission — which is downstream of *every* way an image
reference is produced, including istio sidecar injection and operator-spawned pods.

```yaml
apiVersion: admissionregistration.k8s.io/v1   # v1beta1 on Kubernetes 1.34-1.35
kind: MutatingAdmissionPolicy
metadata:
  name: rewrite-image-registry
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
  failurePolicy: Fail
  # Required. Sidecars are injected by another webhook after this policy first runs;
  # without IfNeeded the injected containers are never rewritten.
  reinvocationPolicy: IfNeeded
  variables:
    - name: src
      expression: '"registry1.dso.mil/"'
    - name: dst
      expression: '"registry.example.mil/"'
  mutations:
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: >
          Object{
            spec: Object.spec{
              containers: object.spec.containers.map(c,
                Object.spec.containers{
                  name: c.name,
                  image: c.image.startsWith(variables.src)
                    ? variables.dst + c.image.substring(size(variables.src))
                    : c.image
                })
            }
          }
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: >
          Object{
            spec: Object.spec{
              initContainers: object.spec.?initContainers.orValue([]).map(c,
                Object.spec.initContainers{
                  name: c.name,
                  image: c.image.startsWith(variables.src)
                    ? variables.dst + c.image.substring(size(variables.src))
                    : c.image
                })
            }
          }
---
apiVersion: admissionregistration.k8s.io/v1   # v1beta1 on Kubernetes 1.34-1.35
kind: MutatingAdmissionPolicyBinding
metadata:
  name: rewrite-image-registry
spec:
  policyName: rewrite-image-registry
  matchResources:
    namespaceSelector: {}
```

Keep the `startsWith` guard. It confines the rewrite to Big Bang images and leaves the
cluster's own components — cloud CNI plugins, CoreDNS, kube-proxy — untouched.

The two mutations cover both container fields you need. Native sidecars are
`initContainers` with `restartPolicy: Always`, so they are handled by the second one.
Ephemeral containers are not, and cannot be — they are only settable through the
`pods/ephemeralcontainers` subresource on **update**, which a `CREATE` rule never sees.
So name your registry explicitly when you run `kubectl debug`.

#### Apply the policy before anything else

The rule matches `CREATE` only, so it never touches pods that already exist, and a pod
admitted before the policy is in place keeps its original reference and fails to pull.
Kubernetes does not re-admit pods, so that pod stays broken until its owner recreates it.
The order is:

```shell
# 1. create the cluster
# 2. apply the policy
kubectl apply -f rewrite-image-registry.yaml
# 3. install Flux from base/flux -- its manifests still say registry1.dso.mil
# 4. install Big Bang
```

Because the policy is live first, Flux's own controllers are rewritten as they are
admitted. Nothing needs pre-rewriting, including `base/flux`.

#### On Kubernetes 1.34 and 1.35

The feature exists but is beta and off by default. **Both** API-server flags are needed,
and they fail differently:

```
--runtime-config=admissionregistration.k8s.io/v1beta1=true
--feature-gates=MutatingAdmissionPolicy=true
```

With only the first, the API accepts the policy and `kubectl get mutatingadmissionpolicy`
reports it live with `MUTATIONS: 2` — and it silently rewrites nothing. If mutation
appears to do nothing, check the feature gate before debugging the CEL. Managed control
planes that do not expose API-server flags cannot use the beta version at all.

#### Kyverno: allowlist the destination, not the source

If you run `kyvernoPolicies`, its `restrict-image-registries` policy permits only
`registry1.dso.mil` and `registry.dso.mil`. `MutatingAdmissionPolicy` is a *mutating*
plugin and therefore runs **before** Kyverno's *validating* webhook, so Kyverno inspects
the image **after** rewriting. You must allowlist the registry you rewrote **to**, even
though every manifest you authored names `registry1.dso.mil`:

```yaml
kyvernoPolicies:
  values:
    policies:
      restrict-image-registries:
        parameters:
          allow:
            - registry.example.mil
```

If you have enabled the CEL-based policies, apply the same override to
`restrict-image-registries-cel`.

Without it, every pod is refused at admission:

```
admission webhook "validate.kyverno.svc-fail" denied the request:
restrict-image-registries: 'Image registry is not in the approved list.'
```

**This failure is delayed and easy to misread.** Pods admitted before Kyverno started
keep running, so a cluster that already looks healthy stays healthy until something
churns — the breakage surfaces on the next upgrade, node drain, or rollout, as workloads
that will not reschedule. If you enable Kyverno after rewriting is already in place,
apply this override in the same change.

### Images, option B: a containerd registry mirror

Where you control node configuration and would rather not run an admission policy, a
registry mirror achieves the same result at the pull layer. Image references stay
`registry1.dso.mil/...` and containerd redirects them. Configure the appropriate file
on every node that pulls images, including schedulable server nodes:

- K3s: `/etc/rancher/k3s/registries.yaml`
- RKE2: `/etc/rancher/rke2/registries.yaml`

```yaml
mirrors:
  "registry1.dso.mil":
    endpoint:
      - "https://registry.example.mil"

configs:
  "registry.example.mil":
    tls:
      ca_file: /etc/ssl/certs/your-ca.crt
```

Configure this file before starting K3s or RKE2, or restart the corresponding service
on each already-running node for the changes to take effect. See the
[K3s](https://docs.k3s.io/installation/private-registry) and
[RKE2](https://docs.rke2.io/install/private_registry) private registry documentation.

This works because the mirror and hauler are two halves of one convention. Hauler strips
the source registry host on push and keeps the repository path; the mirror substitutes
the host back and appends that same path, so
`registry1.dso.mil/ironbank/big-bang/base:2.1.0` is served from
`registry.example.mil/ironbank/big-bang/base:2.1.0` — exactly where `hauler store copy`
put it.

Two consequences worth knowing. Because references are unchanged, Kyverno's
`restrict-image-registries` keeps working with its default allowlist and needs no
override. And because the redirect happens below Kubernetes entirely, it covers every
image regardless of how it was referenced, with nothing to apply in the right order.

The trade-off is reach: it requires node-level configuration on every node, which rules
it out on managed control planes and on Fargate.

#### Harbor under a single project

Endpoint substitution appends the original path, so a mirror pointing at
`https://harbor.example.mil` yields `harbor.example.mil/ironbank/...` and needs an
`ironbank` project. If you require everything under one project instead
(`harbor.example.mil/bigbang/ironbank/...`), a plain endpoint will not do it — k3s
exposes a `rewrite` option taking regular expressions for that case.

### Charts: Big Bang values

Charts are fetched by Flux over HTTP, so neither admission rewriting nor a registry
mirror touches them — both operate on pods. Point the Helm repository at
your registry and switch the packages onto it:

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://registry.example.mil/bigbang"
    type: "oci"
    username: ""
    password: ""

istiod:
  sourceType: "helmRepo"
# ...and every other package you enable
```

Two things that will trip you up:

- **Every package defaults to `sourceType: "git"`.** Without flipping them the OCI charts
  in the archive go unused and you still need `repositories.tar.gz` plus a git server.
- **An unauthenticated registry is not directly expressible.** The values schema requires
  `existingSecret`, or `username` **and** `password`, or a non-generic `provider`. Empty
  strings satisfy the schema and stay falsy in the template, so no `secretRef` is
  rendered — that is the `username: ""` / `password: ""` above.

#### TLS is required for an OCI chart registry

Flux's `insecure` field — the one that allows a non-TLS registry — is only honoured when
`.spec.type` is `oci`, and Big Bang's `helmRepositories` template emits neither `insecure`
nor `certSecretRef`. The archive ships OCI charts, so that is the path you are on: the
chart registry needs a real certificate. (A classic `type: "default"` HTTP chart
repository is unaffected by this, but the archive does not give you one.)

If the certificate is signed by a private CA, **source-controller needs that CA** — it
runs as a pod, so the node trust store does not reach it. Two ways to get it there.

**With values only.** Create a Secret in the `bigbang` namespace and reference it as
`existingSecret`. Source-controller reads TLS material out of the auth secret and
*extends* the system pool with it. Use the format that matches the registry:

- For CA trust only, use an `Opaque` Secret containing `ca.crt`.
- For authentication plus CA trust, either use an `Opaque` Secret containing `username`,
  `password`, and `ca.crt`, or use a `kubernetes.io/dockerconfigjson` Secret containing
  `.dockerconfigjson` and `ca.crt`.

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://registry.example.mil/bigbang"
    type: "oci"
    existingSecret: "registry1-ca"
```

Flux logs this as deprecated (`certSecretRef` is the supported field), so it works today
but is worth watching. Big Bang has no `certSecretRef` passthrough, which is what forces
the choice.

**With a patch to Flux.** Longer-lived, at the cost of editing `base/flux`:

```yaml
patches:
  - target:
      kind: Deployment
      name: source-controller
    patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: source-controller
      spec:
        template:
          spec:
            containers:
            - name: manager
              env:
              - name: SSL_CERT_FILE
                value: /etc/ssl/certs/your-ca.crt
              volumeMounts:
              - name: registry-ca
                mountPath: /etc/ssl/certs/your-ca.crt
                subPath: ca.crt
                readOnly: true
            volumes:
            - name: registry-ca
              configMap:
                name: registry-ca
```

Mount it read-only; `base/flux` sets `readOnlyRootFilesystem: true`. Note `SSL_CERT_FILE`
replaces Go's trust store rather than adding to it, which is fine in a disconnected
environment. The symptom of getting this wrong is a consuming `HelmChart` reporting an
x509 error.

Flux's own controller images are in the archive at the versions `base/flux` pins, and the
mirror covers them, so no image changes are needed there.

### AWS: EKS and ECR

On EKS the choice of rewriting mechanism is made for you. (For getting the archive into
ECR in the first place, see [ECR: create the repositories
first](#ecr-create-the-repositories-first).)

- **A registry mirror is not available.** It needs node-level containerd configuration,
  which managed node groups allow only through launch template user data and Bottlerocket
  through settings — and Fargate not at all.
- **Use `MutatingAdmissionPolicy`.** On Kubernetes 1.36+ it is stable and on by default,
  so it needs no API-server flags and works on managed control planes. On 1.34-1.35 it is
  beta and requires flags EKS does not expose, so it is unavailable there.

Rewriting to ECR has a further advantage: the node's IAM role authenticates to ECR
natively, so no pull secret is required. Big Bang documents that case as
`registryCredentials: null`.

If you are on a Kubernetes version below 1.36 on EKS, neither a mirror nor an in-tree
policy is available, and the remaining option is a Kyverno mutating `ClusterPolicy`.
Note the bootstrap cost: Kyverno cannot mutate the pods that install Kyverno, so its own
images and the `kubectl` image in the `kyverno-policies` wait-job must be rewritten with
`postRenderers` first, and Flux's four controller images with a kustomize `images:`
transformer in your `base/flux` overlay.

### The values, all together

The pieces above are described where they matter; this is what they look like in one
file. For the admission-policy path:

```yaml
# Pull credentials for the registry the images were rewritten TO. This does not
# rewrite anything -- it only builds the imagePullSecret -- but without it a private
# registry answers the rewritten pulls with 401.
registryCredentials:
  registry: registry.example.mil
  username: <username>
  password: <password>

# Charts. Flux fetches these itself, so they are configured here rather than rewritten.
# Chart-pull credentials are configured separately from registryCredentials above.
helmRepositories:
  - name: "registry1"
    repository: "oci://registry.example.mil/bigbang"
    type: "oci"
    username: "<username>"
    password: "<password>"

# Kyverno validates AFTER the rewrite, so allow the destination.
kyvernoPolicies:
  values:
    policies:
      restrict-image-registries:
        parameters:
          allow:
            - registry.example.mil

# Every package defaults to sourceType "git". Flip each one you enable.
istiod:
  sourceType: "helmRepo"
istioGateway:
  sourceType: "helmRepo"
# ...and so on
```

With a registry mirror instead, drop the `kyvernoPolicies` override, leave
`registryCredentials` pointed at `registry1.dso.mil` (references are unchanged, so that
is the host the kubelet authenticates to), and give containerd the mirror's own
credentials under `configs:` in `registries.yaml`. The `helmRepositories` and
`sourceType` values are the same either way — charts never go through the mirror.

## 3. Verify it came from your registry

OCI `HelmRepository` objects are static configuration and do not report a `Ready`
condition. Check the consuming `HelmChart` and `HelmRelease` conditions instead; both
should report `Ready=True` once reconciliation succeeds. See
[Flux's OCI HelmRepository documentation](https://fluxcd.io/flux/components/source/helmrepositories/#working-with-helmrepositories).

```shell
kubectl get helmcharts.source.toolkit.fluxcd.io -A       # Ready=True: charts fetched
kubectl get helmreleases.helm.toolkit.fluxcd.io -A        # Ready=True: releases reconciled
kubectl get po -A                                       # no ImagePullBackOff
```

**If you rewrote at admission**, the pod specs are the evidence — they should name your
registry, not the one in the manifests you applied. This should return zero:

```shell
kubectl get po -A -o json \
  | jq '[.items[].spec | (.containers[]?, .initContainers[]?) | .image]
        | map(select(startswith("registry1.dso.mil"))) | length'
```

Check a pod in an istio-injected namespace specifically. The sidecar is added by a
separate webhook, so it is the case most likely to be missed — if `istio-proxy` still
names `registry1.dso.mil`, `reinvocationPolicy: IfNeeded` is not set.

**If you used a mirror**, pod specs still say `registry1.dso.mil` by design, so a running
pod proves nothing on its own. The registry's access log is the only evidence: if a pod
is Running and your registry logged nothing for that image, it reached upstream and the
mirror is not doing its job.

## Without the hauler CLI

The archive is not a proprietary format — it is a zstd-compressed tar of a standard
OCI image layout, so the archive can be unpacked and pushed with any OCI-aware
tooling if you cannot install `hauler` on the high side.

```shell
mkdir haul && tar --zstd -xf bb-<tag>-images-charts.tar.zst -C haul
```

That yields `index.json`, `manifest.json`, and `blobs/sha256/`. Older hauler versions
did not write an `oci-layout` marker file, and tools that validate the layout strictly
will want one. Check, and add it if it is missing — it is a single line:

```shell
[ -f haul/oci-layout ] || printf '{"imageLayoutVersion":"1.0.0"}' > haul/oci-layout
```

Each image is addressable by the ref name recorded in `index.json`, so a push loop
is short. Refs repeat across entries (signatures and attestations share the name of
the image they cover), hence the `sort -u`:

```shell
jq -r '.manifests[].annotations."org.opencontainers.image.ref.name" | select(. != null)' \
  haul/index.json | sort -u \
  | xargs -P4 -I{} skopeo copy --retry-times 3 oci:haul:{} docker://registry.example.mil/{}
```

Two notes if you go this route:

- `crane push` reads the layout but refuses a multi-image one without `--index`,
  which fuses every image into a single index rather than pushing them to separate
  repositories. Use `skopeo`, or `oras` for individual artifacts.
- The ref names in `index.json` have the source registry host stripped
  (`ironbank/big-bang/base:2.1.0`), which is what makes the push loop above land
  images at the right paths. If you need to know where an image originally came
  from, `manifest.json` retains the full original reference in its `RepoTags`.

## Verifying signatures

Hauler carries cosign signatures, attestations, and SBOMs alongside each image by
default, so they arrive in your registry as the usual `sha256-<digest>.sig`,
`.att`, and `.sbom` tags. Signature verification with `cosign` works against your
internal registry without reaching back to the source.

## What is not included

The archive contains images and OCI Helm charts only. If you deploy Big Bang
packages from **git** sources rather than the `helmRepo` (OCI) sources, you also
need `repositories.tar.gz` from the same release and a git server to host it.
Hauler has no git repository content type and does not replace that artifact.
