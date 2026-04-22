# Istio Ambient Mode on Windows Nodes

> **WARNING:** Windows ambient support is **experimental** and not part of any official Istio release. The code lives on the `experimental-windows-ambient` branch of [`istio/ztunnel`](https://github.com/istio/ztunnel/tree/experimental-windows-ambient) and is maintained by Microsoft engineers. Expect breaking changes.

> **Supportability:** This workflow is for experimentation and evaluation only. It is not currently validated as a Big Bang production deployment pattern.

[[_TOC_]]

## Overview

Istio ambient mode can run on Windows nodes using a [HostProcess container](https://kubernetes.io/docs/tasks/configure-pod-container/create-hostprocess-pod/) variant of ztunnel. Unlike Linux, which uses iptables/eBPF for traffic interception, the Windows implementation uses Windows HNS (Host Networking Service) APIs and runs as a privileged HostProcess DaemonSet on each Windows node.

This enables a **hybrid cluster** where Linux nodes run the standard ztunnel DaemonSet and Windows nodes run the Windows ztunnel DaemonSet, both managed by the same istiod control plane.

### What Works

According to the upstream PR authors (Microsoft):

- In-pod traffic redirection via Windows HostProcess containers
- HBONE protocol upgrade (L4 mTLS tunnel)
- Waypoint proxy forwarding
- ZDS (ztunnel discovery service) communication with istiod

### Known Limitations

| Limitation             | Details                                                                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **DNS resolution**     | HostProcess pods cannot resolve cluster-local DNS names. Requires `ALT_XDS_HOSTNAME` and `ALT_CA_HOSTNAME` environment variables as workarounds, or init container PowerShell scripts to configure DNS namespaces. |
| **Socket reuse**       | Not supported on Windows due to platform limitations.                                                                                                                                                              |
| **No published image** | Istio does not publish a Windows ztunnel image. You must build your own.                                                                                                                                           |
| **No IronBank image**  | No hardened image exists. There will not be one until the feature reaches GA and is submitted for hardening.                                                                                                       |
| **ARM64**              | Windows ARM64 builds are tracked in [ztunnel #1584](https://github.com/istio/ztunnel/issues/1584) but not yet available.                                                                                           |
| **Sidecar mode**       | Traditional Istio sidecar injection is not currently supported on Windows ([istio #27893](https://github.com/istio/istio/issues/27893)). Ambient is currently the only mesh data plane path for Windows workloads. |

## Architecture

```
Linux Node                               Windows Node
┌────────────────────────┐               ┌─────────────────────────┐
│  ztunnel (DaemonSet)   │               │  ztunnel.exe            │
│  - Linux container     │               │  (HostProcess DaemonSet)│
│  - iptables/eBPF       │◄──── HBONE ──►│  - Windows HNS APIs     │
│  - istio-cni plugin    │   (mTLS)      │  - No CNI plugin needed │
│                        │               │                         │
│  ┌───────┐ ┌───────┐   │               │  ┌──────┐ ┌──────┐      │
│  │Pod A  │ │Pod B  │   │               │  │Pod C │ │Pod D │      │
│  │(Linux)│ │(Linux)│   │               │  │(Win) │ │(Win) │      │
│  └───────┘ └───────┘   │               │  └──────┘ └──────┘      │
└────────────────────────┘               └─────────────────────────┘
         │                                       │
         └──────── istiod (control plane) ───────┘
                   PILOT_ENABLE_AMBIENT=true
```

Both the Linux and Windows ztunnel instances connect to the same istiod control plane. Cross-node traffic between Linux and Windows pods is encrypted via HBONE (mTLS over HTTP/2 CONNECT on port 15008).

## Building the Windows ztunnel Image

The `experimental-windows-ambient` branch contains:

- `Dockerfile.ztunnel-windows` - Multi-stage build that cross-compiles from Linux
- `daemonset-windows.yaml` - Kubernetes DaemonSet manifest for Windows nodes
- `WINDOWS.md` - Upstream build documentation

### Prerequisites

- Docker with buildx support (for container builds)
- OR a Debian-based system with `mingw-w64` (for local cross-compilation)
- A container registry you can push to

### Option 1: Docker Buildx (Recommended)

```bash
# Clone and checkout the experimental branch
git clone https://github.com/istio/ztunnel.git
cd ztunnel
git checkout experimental-windows-ambient

# Build the Windows container image
docker buildx build . \
  -f Dockerfile.ztunnel-windows \
  --platform=windows/amd64 \
  --output type=registry \
  -t <your-registry>/ztunnel-windows:experimental
```

### Option 2: Local Cross-Compilation

```bash
# Clone and checkout
git clone https://github.com/istio/ztunnel.git
cd ztunnel
git checkout experimental-windows-ambient

# Install cross-compilation toolchain
sudo apt-get install mingw-w64 protobuf-compiler cmake nasm
rustup target add x86_64-pc-windows-gnu

# Build
cargo build --target x86_64-pc-windows-gnu --release
```

The resulting binary is at `out/rust/x86_64-pc-windows-gnu/release/ztunnel.exe`.

### Dockerfile Reference

```dockerfile
ARG WINBASE=mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image:v1.0.0
FROM --platform=$BUILDPLATFORM rust AS build
WORKDIR /src
RUN apt-get update && apt-get install -y mingw-w64 protobuf-compiler cmake nasm \
    && rustup target add x86_64-pc-windows-gnu
COPY . .
RUN cargo build --target x86_64-pc-windows-gnu --release

FROM ${WINBASE}
COPY --from=build /src/out/rust/x86_64-pc-windows-gnu/release/ztunnel.exe ztunnel.exe
ENTRYPOINT [ "ztunnel.exe" ]
```

The base image (`windows-host-process-containers-base-image:v1.0.0`) is the Microsoft-published minimal image for Kubernetes HostProcess containers.

## Deploying in a Hybrid Cluster

### Step 1: Enable Ambient Infrastructure via Big Bang

```yaml
istio:
  ambient:
    enabled: true
```

This deploys the Linux ztunnel DaemonSet, istio-cni, gateway-api CRDs, and configures istiod with `PILOT_ENABLE_AMBIENT=true`.

### Step 2: Deploy the Windows ztunnel DaemonSet

The branch includes `daemonset-windows.yaml`. Apply it after the ambient infrastructure is running:

```bash
kubectl apply -f daemonset-windows.yaml
```

Or customize and apply manually. The key requirements:

- Must run in `istio-system` namespace (same as Linux ztunnel)
- Must be a HostProcess pod (`hostProcess: true` in securityContext)
- Must have a `nodeSelector` targeting Windows nodes:

  ```yaml
  nodeSelector:
    kubernetes.io/os: windows
  ```

- Must set DNS workaround environment variables:

  ```yaml
  env:
    - name: ALT_XDS_HOSTNAME
      value: "<istiod-service-ip>"
    - name: ALT_CA_HOSTNAME
      value: "<istiod-service-ip>"
  ```

### Step 3: Label Windows Namespaces for Ambient

```bash
kubectl label namespace <windows-workload-ns> istio.io/dataplane-mode=ambient
```

### Step 4: Verify

```bash
# Check ztunnel pods on both OS types
kubectl get pods -n istio-system -l app=ztunnel -o wide

# Verify namespace ambient label
kubectl get namespace <windows-workload-ns> -o jsonpath='{.metadata.labels.istio\.io/dataplane-mode}{"\n"}'

# Verify Windows workloads are in the labeled namespace
kubectl get pods -n <windows-workload-ns> -o wide

# Check ztunnel logs on Windows node
kubectl logs -n istio-system <windows-ztunnel-pod>
```

## Hybrid Ambient + Sidecar Considerations

In a mixed cluster, you can run three modes simultaneously:

| Mode        | Namespace Label                    | Use Case                                            |
| ----------- | ---------------------------------- | --------------------------------------------------- |
| **Ambient** | `istio.io/dataplane-mode: ambient` | Linux or Windows workloads, no sidecar overhead     |
| **Sidecar** | `istio-injection: enabled`         | Linux workloads needing L7 policy without waypoints |
| **None**    | `istio-injection: disabled`        | Workloads excluded from mesh                        |

Istio resolves the mode per namespace (or per pod) based on labels. Both ambient and sidecar workloads can communicate with each other through the mesh; istiod handles translation between HBONE (ambient) and direct Envoy-to-Envoy (sidecar) communication.

### Big Bang Core Packages

Big Bang core package namespaces (monitoring, logging, grafana, etc.) hardcode `istio-injection: enabled/disabled` in their namespace templates. To switch a core package to ambient mode, either:

1. **Post-deploy label override:**

   ```bash
   kubectl label namespace logging \
     istio.io/dataplane-mode=ambient \
     istio-injection-
   kubectl rollout restart deployment -n logging
   ```

2. **PostRenderers on the Big Bang HelmRelease** (if deployed via Flux):

   ```yaml
   # Applied at the Flux HelmRelease level that deploys Big Bang itself
   postRenderers:
     - kustomize:
         patches:
           - target:
               kind: Namespace
               name: logging
             patch: |
               - op: add
                 path: /metadata/labels/istio.io~1dataplane-mode
                 value: ambient
               - op: remove
                 path: /metadata/labels/istio-injection
   ```

3. **Kyverno mutating policy** (declarative and self-healing):

   ```yaml
   apiVersion: kyverno.io/v1
   kind: ClusterPolicy
   metadata:
     name: ambient-namespace-labeler
   spec:
     rules:
       - name: label-ambient-namespaces
         match:
           any:
             - resources:
                 kinds:
                   - Namespace
                 selector:
                   matchLabels:
                     bigbang.dev/ambient: "true"
         mutate:
           patchStrategicMerge:
             metadata:
               labels:
                 istio.io/dataplane-mode: ambient
                 istio-injection: "disabled"
   ```

Extra packages deployed via `packages:` in Big Bang values typically inherit ambient behavior when `istio.ambient.enabled: true` is set. Validate the rendered namespace labels in your environment before relying on this behavior.

## L7 Traffic Management (Waypoint Proxies)

Basic ambient provides L4 mTLS only. For L7 capabilities (HTTP routing, retries, header-based authorization), deploy a waypoint proxy for the namespace or service:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-waypoint
  namespace: <target-namespace>
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-waypoint
  listeners:
    - name: mesh
      port: 15008
      protocol: HBONE
```

Waypoint proxies are Linux Envoy pods - they do not need to run on Windows nodes. Traffic from Windows ambient pods flows through the waypoint when L7 policies are attached.

## Upstream References

### Branches and PRs

- [experimental-windows-ambient branch](https://github.com/istio/ztunnel/tree/experimental-windows-ambient)
- [PR #1461 - Initial experimental Windows support](https://github.com/istio/ztunnel/pull/1461) (merged Jun 2025)
- [PR #1816 - Rebase to master](https://github.com/istio/ztunnel/pull/1816) (merged Mar 2026)
- [PR #1608 - Retrying compartmentless containers](https://github.com/istio/ztunnel/pull/1608) (merged Oct 2025)
- [PR #1657 - Unblock Windows experiments for MVP](https://github.com/istio/ztunnel/pull/1657) (merged Oct 2025)

### Issues

- [istio/istio #27893 - Support Windows in Istio Data Plane](https://github.com/istio/istio/issues/27893) (open, tracking issue)
- [istio/ztunnel #1584 - Support Windows ARM64 builds](https://github.com/istio/ztunnel/issues/1584) (open)
- [istio/ztunnel #1609 - Handle partial ZDS adds between ztunnel and CNI](https://github.com/istio/ztunnel/issues/1609) (open)

### Presentations

- [Istio Ambient Mesh support on Windows - KubeCon EU 2025 / Istio Day](https://youtu.be/sULnWlj8sR8?si=ewQ2hgdEZ5ZSRGuK) (Microsoft)

### Big Bang Documentation

- [Ambient Mode Configuration](ambient.md)
- [ztunnel Package](../packages/core/ztunnel.md)
- [Gateway API Package](../packages/core/gateway-api.md)

### Upstream Istio Documentation

- [Istio Ambient Mode Overview](https://istio.io/latest/docs/ambient/overview/)
- [Ambient Mode Architecture](https://istio.io/latest/docs/ambient/architecture/)
- [Ztunnel Traffic Redirection](https://istio.io/latest/docs/ambient/architecture/traffic-redirection/)
