# Big Bang Getting Started

Table of Contents

- [Big Bang Getting Started](#big-bang-getting-started)
  - [System Requirements](#system-requirements)
  - [Flux Installation](#flux-installation)
  - [Configuration Template](#configuration-template)
    - [Overview](#overview)
    - [Environments (Multi-cluster)](#environments-multi-cluster)
  - [Next Steps](#next-steps)

## System Requirements

- Admin tools
  - [Docker](https://docs.docker.com/engine/install/)
  - [Flux CLI](https://toolkit.fluxcd.io/get-started/#install-the-flux-cli):     `brew install fluxcd/tap/flux`
  - [Git](https://git-scm.com/download/)
  - [Helm](https://helm.sh/docs/intro/install/)
  - [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
  - [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
  - [SOPS](https://github.com/mozilla/sops/releases)

- Kubernetes cluster
  > CPU, Memory, and Disk space vary depending on what is enabled.  If everything is enabled, the following is the minimum viable setup:
  - vCores - 8
  - Memory - 32GB
  - Disk Space - 20GB

## Flux Installation

[Flux v2](https://toolkit.fluxcd.io/) must be installed into the Kubernetes cluster before deploying Big Bang.  There are three options for doing this:

1. (Recommended) Deploy officially through [Iron Bank](registry1.dso.mil)

    ```bash
    # The script will do the following:
    #   Check flux prerequisites
    #   Interactively login to Iron Bank and store credentials in Secret
    #   Install flux into Kubernetes cluser using Iron Bank repo
    #   Remove Iron Bank credentials from cluster
    hack/flux-install.sh
    ```

1. Deploy unofficially through [Big Bang's Repo](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/fluxv2/container_registry)

   ```bash
   flux install --registry registry.dso.mil/platform-one/big-bang/apps/sandbox/fluxv2
   ```

1. Deploy for development through [DockerHub](https://hub.docker.com/search?q=fluxcd)

   ```bash
   flux install
   ```

## Configuration Template

A [template for configuring multi-cluster environments](https://repo1.dso.mil/platform-one/big-bang/customers/template/) is provided to assist with getting Big Bang setup correctly.  You should make a copy of the `./bigbang` folder from the [customer Big Bang repository](https://repo1.dso.mil/platform-one/big-bang/customers/template) and place it into a Git repository under your control.

### Overview

The template is setup to allow you to customize the Big Bang deployment for your environment.  The template contains support for two cluster environments, `dev` and `prod`, but can be easily extended to more.  At a minimum, the following must be configured in the template for a properly working deployment:

- Big Bang version - allows you to control when to upgrade
- Environment Git repository - where your copy of the configuration template is located
- Hostname - the base domain to use for your packages
- Reference to SOPS private key - See the [encryption help](3_encryption.md) for more information.
- Iron Bank pull credentials

The [Configuration Template help](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/blob/main/README.md) contains details on how to setup these items.

If there is additional configuration you want, refer to the [configuration help](4_configuration.md) for details.

### Environments (Multi-cluster)

In the template, there are two folders used for each cluster environment, `base` and a named folder (e.g. `dev` or `prod`).  `base` is used as a shared folder between all the environments and a `<env>` folder is specific to an environment.  Overrides proceed as follows, with `<env>` having the highest precedence.

```mermaid
graph LR
  pkg[Package values]-->bb[Big Bang values]-->base[`base` values]-->named[`<env>` values]
```

## Next Steps

Follow the steps in the [encryption](3_encryption.md) and [configuration](4_configuration.md) documentation to setup the minimum viable configuration for deployment.
