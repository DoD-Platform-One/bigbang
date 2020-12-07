# Umbrella

Work in progress umbrella package

## Iron Bank Images

Per the Charter, all Big Bang packages will leverage container images from [IronBank](https://ironbank.dsop.io/).  In order to pull these images, ImagePullSecrets must be provided to BigBang.  For developers to obtain access 
to the images, follow the guides below.  These steps should NOT be used for production since the API keys for a user are only valid when the user is logged into [Registry1](https://registry1.dsop.io)

1) Register for a free Ironbank account [Here](https://sso-info.il2.dsop.io/new_account.html)
2) Log into the [Iron Bank Registry](https://registry1.dsop.io), in the top right click your *Username* and then *User Profile* to get access to your *CLI secret*/API keys.
3) When installing BigBang, set the Helm Values `registryCredentials.username` and `registryCredentials.password` to match your Registry1 username and API token

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

### Contributing

Please see our [contributing guide](./CONTRIBUTING.md) if you are interested in contributing to Big Bang.