# Umbrella

Work in progress umbrella package

## Iron Bank Images

Per the Charter, all Big Bang packages will leverage container images from [IronBank](https://ironbank.dsop.io/).  In order to pull these images, ImagePullSecrets must be provided to BigBang.  For developers to obtain access 
to the images, follow the guides below.  These steps should NOT be used for production since the API keys for a user are only valid when the user is logged into [Registry1](https://registry1.dsop.io)

1) Register for a free Ironbank account [Here](https://sso-info.il2.dsop.io/new_account.html)
2) Log into the [Iron Bank Registry](https://registry1.dsop.io), in the top right click your *Username* and then *User Profile* to get access to your *CLI secret*/API keys.
3) When installing BigBang, set the Helm Values `registryCredentials.username` and `registryCredentials.password` to match your Registry1 username and API token

## Usage

The following examples expect a cluster with fluxv2 preinstalled.  This can be done by [installing the flux cli](https://toolkit.fluxcd.io/get-started/#install-the-flux-cli) and running `flux install`.  This will install flux from the internet.  If you wish to install the Iron Bank approved images, run `hack/flux-install.sh` to install flux from the [Iron Bank Registry](https://registry1.dsop.io).

### Quickstart

A quickstart BigBang environment template is provided [here](https://repo1.dsop.io/platform-one/big-bang/customers/bigbang/-/tree/master/bigbang).  See the README.md to get started.

### Contributing

Please see our [contributing guide](./CONTRIBUTING.md) if you are interested in contributing to Big Bang.