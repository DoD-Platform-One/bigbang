# Umbrella

Work in progress umbrella package

## Usage

The following examples expect a cluster with fluxv2 preinstalled.  This can be done by [installing the flux cli](https://toolkit.fluxcd.io/get-started/#install-the-flux-cli) and running `flux install`.  (TODO: Convert to IB images).

### Quickstart

A bare mininmum, simple quickstart is provided under `./examples/simple`:

```bash
kubectl apply -f examples/simple
```

### Multi Environment

Most production deployments follow a traditional Dev, Acceptance, Staging, Test (DAST) workflow.  This example demonstrates __one way__ of achieving multiple deployments with differing configurations.

```bash
# Apply dev
kustomize build examples/multi-env/overlays/dev | kubectl apply -f -

# Apply prod
kustomize build examples/multi-env/overlays/prod | kubectl apply -f -
```
