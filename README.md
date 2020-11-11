# Umbrella

Work in progress umbrella package

## Usage

The following examples expect a cluster with fluxv2 preinstalled.  This can be done by [installing the flux cli](https://toolkit.fluxcd.io/get-started/#install-the-flux-cli) and running `flux install`.  (TODO: Convert to IB images).

### Simple Quickstart

A bare mininmum, simple quickstart is provided under `./examples/simple`:

```bash
kubectl apply -f examples/simple
```

### Complete Example

While simple to use, Big Bang also allows full flexibility in configuring individual packages, using encrypted secrets, and deploying to multiple environments with the same configuration base.  

See the [readme](./examples/complete/README.md) for more information.


### Developers

Developers can use the [Developer Setup](./examples/development/README.md) to faciliate a local setup for developing improvements to Big Bang.