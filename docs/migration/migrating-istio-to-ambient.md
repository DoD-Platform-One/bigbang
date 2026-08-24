# Migrating a Big Bang Environment from Sidecar Mode to Ambient Mode

> [!WARNING]
> Ambient mode is currently **beta** in Big Bang. It is planned to be promoted to stable ahead of Big Bang 4.0, giving
> users time to test prior to it becoming the default in 4.0. It is advisable to test the migration
> in a dev or test environment first.

[[_TOC_]]

## Overview

Migrate a live Big Bang environment from Istio **sidecar mode** (`istio-injection:
enabled`, per-pod Envoy) to **ambient mode** (node-level `ztunnel` for L4/mTLS, optional
waypoints for L7).

Standing up a **new** ambient environment instead? See
[Configuring Istio Ambient Mode in Big Bang](../configuration/ambient.md).

### Related documentation

- [Configuring Istio Ambient Mode in Big Bang](../configuration/ambient.md)
- [Running Mission Applications in Ambient](../tutorials/ambient-mission-applications/index.md)
- [ztunnel Package](../packages/core/ztunnel.md) / [Gateway API Package](../packages/core/gateway-api.md)
- Upstream: [Migrating to Ambient Mode](https://istio.io/latest/docs/ambient/install/)

## What Changes

For the broad sidecar-vs-ambient concepts (ztunnel, waypoints, HBONE, the
`istio.io/dataplane-mode` label, default-deny authz), see Istio's
[Ambient overview](https://istio.io/latest/docs/ambient/overview/). Below is only what is
**Big Bang-specific**.

Setting the single switch `istio.ambient.enabled: true` automatically:

1. Deploys the required infra packages: **ztunnel**, **istio-cni**, **gateway-api**.
2. Sets `PILOT_ENABLE_AMBIENT: "true"` on istiod.
3. Swaps `istio-injection` for `istio.io/dataplane-mode: ambient` on Big Bang-managed
   package namespaces and disables sidecar injection.
4. Enables default authorization policies and injects the HBONE port (15008) into
   generated network policies.

## Migration Procedure

> [!NOTE]
> Strongly encouraged to test end-to-end in non-production first.

### Step 1: Enable ambient mode

Add the switch to your **existing** Big Bang values:

```yaml
istio:
  ambient:
    enabled: true
```

For a live sidecar→ambient migration, pair the switch with the temporary bridge for any
clustered package rolling through the mixed window (see
[Handling Special Cases](#clustered-workloads-that-break-under-strict-mtls-during-the-mixed-window)).
The complete values look like:

```yaml
istio:
  ambient:
    enabled: true

# Temporary during sidecar to ambient migration only. Remove this whole block once
# every neuvector pod is ambient.
neuvector:
  values:
    istio:
      mtls:
        mode: PERMISSIVE
      authorizationPolicies:
        custom:
          - name: neuvector-migration-allow-all
            spec:
              action: ALLOW
              rules:
                - {}
```

### Step 2: Deploy the change and roll out the infrastructure

Apply via Helm or commit and push the updated values to your environment's Git repository.

```bash
helm upgrade --install bigbang <chart> -n bigbang \
  -f existing-values.yaml -f ambient-migration.yaml
```

> [!IMPORTANT]
> **Most Big Bang managed pods roll into ambient automatically.** Enabling ambient changes the
> `dev.bigbang.mil/istioDataplane` annotation Big Bang stamps onto nearly every package. When Flux
> applies the Helm upgrade, the changed pod template makes Kubernetes roll those pods, and they
> restart without sidecars. Workloads deployed outside of Big Bang need to be addressed separately.
>

This Helm upgrade should reconcile without any manual intervention in most circumstances. As
the namespace rolls through the mixed sidecar/ambient window, clustered workloads can lose
member-to-member connectivity under STRICT mTLS — see
[Clustered workloads that break under STRICT mTLS during the mixed window](#clustered-workloads-that-break-under-strict-mtls-during-the-mixed-window)
for why this happens and the temporary bridge that addresses it.

### Step 3: Find and restart any pods still on a sidecar

After the upgrade finishes, some workloads may keep their sidecar until restarted. Use
`scripts/istio-sidecars.sh` to identify them — Istio injects native sidecars, so a leftover
`istio-proxy` runs as an init container and the pod shows `2/2` with a single app container.
The script finds these and excludes ztunnel and the ingress gateways:

```bash
scripts/istio-sidecars.sh list             # all namespaces
scripts/istio-sidecars.sh list -n gitlab   # a single namespace
```

Restart the owning workloads of any pods it reports:

```bash
scripts/istio-sidecars.sh restart
```

Re-run `list` afterwards; it should report no sidecar pods.

### Step 4: Migrate mission apps and non-integrated charts

See [Running Mission Applications in Ambient](../tutorials/ambient-mission-applications/index.md)

## Handling Special Cases

### Clustered workloads that break under STRICT mTLS during the mixed window

Workloads that cluster by **direct pod IP** (headless Services / StatefulSets: Consul,
raft, gossip, Elasticsearch, Redis-cluster, MinIO, Vault) can lose member-to-member
connectivity **while a namespace is half sidecar, half ambient** under STRICT mTLS.

**Why:** a sidecar pod dialing a bare pod IP uses Envoy's `PassthroughCluster`: plaintext,
no HBONE tunnel, no mTLS identity. Two ztunnel layers reject it: (1) namespace
`PeerAuthentication: STRICT` drops non-mTLS inbound; (2) the default `allow-all-in-ns`
policy matches on peer identity, which passthrough lacks, so it hits default-deny. The tell
in the ztunnel log is a denied connection with a populated `src.workload` but **empty
`src.identity`**. Only `sidecar → ambient` (by pod IP) breaks; `ambient ↔ ambient` carries
identity and passes STRICT.

**Bridge.** Relax both layers through the package's `values` so bb-common owns the objects:
set `istio.mtls.mode: PERMISSIVE` and add an allow-all custom authz policy (the default
allow-in-namespace matches on identity, which passthrough lacks). This is the issue addressed in the neuvector block shown in [Step 1](#step-1-enable-ambient-mode). 

**Follow-up (required).** Once every pod in the package is ambient, remove the block:
dropping `istio.mtls.mode` reverts to the default (**STRICT**) and dropping the custom
policy restores default-deny; the HelmRelease prunes both on reconcile.

### Workloads that need Authservice

ztunnel is L4 only, so L7 SSO enforcement (Authservice OIDC ext_authz) moves to a
**waypoint**. bb-common auto-creates one per package when a route enables authservice in
ambient mode. See
[bb-common: Protecting a route with Authservice](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/routes/README.md#protecting-a-route-with-authservice-oidc-ext_authz).

### `hostNetwork` workloads

hostNetwork pods cannot be enrolled in ambient (see
[Troubleshooting Istio Ambient](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient)).

**Twistlock is automatic:** with ambient enabled, the twistlock package sets
`istio.io/dataplane-mode: none` on the Defender pods (its `twistlock-defender.labels`
helper), opting them out while the rest of the namespace stays enrolled.

For **other**, unmanaged hostNetwork workloads, opt the pods out yourself with a **pod**
label:

```yaml
istio.io/dataplane-mode: none
```

## Validation

Check the ztunnel pod logs for errors — clean logs are the quickest sign the mesh is
healthy:

```bash
kubectl logs -n istio-system ds/ztunnel
```

In ambient there is no per-pod sidecar, so the L4/mTLS errors that a workload's sidecar used
to surface now appear on the **ztunnel pod running on that workload's node**. To troubleshoot
a specific pod, find its node and read that node's ztunnel:

```bash
node=$(kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.nodeName}')
ztunnel=$(kubectl get pod -n istio-system -l app=ztunnel \
  --field-selector spec.nodeName=$node -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n istio-system $ztunnel
```

## References

- [Configuring Istio Ambient Mode in Big Bang](../configuration/ambient.md)
- [Running Mission Applications in Ambient](../tutorials/ambient-mission-applications/index.md)
- [ztunnel Package](../packages/core/ztunnel.md) / [Gateway API Package](../packages/core/gateway-api.md)
- [Istio Ambient Overview](https://istio.io/latest/docs/ambient/overview/) /
  [Migrating to Ambient](https://istio.io/latest/docs/ambient/install/) /
  [Ambient and Kubernetes Network Policy](https://istio.io/latest/docs/ambient/usage/networkpolicy/)
