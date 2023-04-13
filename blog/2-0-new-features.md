---
revision_date: Last edited April 13, 2023
tags:
  - blog
---

# New Features in Big Bang 2.0

This is part 3 in a series of Big Bang 2.0 blog posts. If you haven't already, read through part 1 [here](./big-bang-2-0.md) which provides some backstory on 2.0 and part 2 [here](./2-0-breaking-changes.md) which will get you prepared for the breaking changes in 2.0. This post will dive more into some of the new features releasing with 2.0.

## Package Extensibility

As mentioned in the first post in this series, 2.0 will provide new extensibility for deploying additional packages (beyond what is providing in Big Bang core/addons). The ["extra package deployment guide"](../docs/guides/deployment-scenarios/extra-package-deployment.md) provides a lot of details on what is included and how to use it, so we won't reproduce all of that here. As a teaser for that more extensive document, 2.0 provides a new way to deploy extra packages, as seen in the example below which deploys podinfo directly from the GitHub source:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
```

We strongly encourage you look at using this for deploying any extra packages, whether they are from the Big Bang Community or directly from GitHub and other sources.

## OCI HelmRepositories

As mentioned previously Helm repositories will now be an option for deployment in 2.0. While we do encourage users to test and adopt this, Git repository sources will remain the default for 2.0 so you will not see any immediate changes unless you choose to test it out as laid out in the brief guide below.

To setup a `HelmRepository` source you will want to add a `helmRepositories` config to your values:

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
```

By using the `existingSecret: "private-registry"` you will be re-using your `registryCredentials` for authentication. If using a robot account you may need to get a new one issued with a broader scope since previous robot accounts only provided access to `registry1.dso.mil/ironbank`.

In order to start using the `HelmRepository`, you'll need to switch the `sourceType` for a package. The below example switches it for `istio`:

```yaml
istio:
  sourceType: "helmRepo"
```

Currently you would need to set the `sourceType` individually for each package, but once making that change your `HelmRelease` will be setup to pull from the `HelmRepository` instead of the `GitRepository`. As a side-note, you can also pull from other Helm repositories (even non-OCI type ones) and leverage this alongside the new `packages` functionality to deploy from any imaginable Helm repo.

Why should you be interested in switching? Big Bang is currently publishing all package Helm charts (including community packages) to our OCI Helm Repository (`registry1.dso.mil/bigbang`). This means that you can pull all of your charts from a single source object in cluster, rather than having a `GitRepository` per package. In the future we also plan to sign these charts and have Flux validate the signatures in cluster. If you're an airgap user this also has some future benefits depending on tooling, you may no longer need a Git server running to spin up Big Bang.

## Renovate for Upgrades

The last feature we want to highlight in this post is the new inclusion of Renovate for upgrades. This again is pretty well laid out in existing documentation [here](../docs/guides/renovate/deployment.md) so we won't dive too deep into configurations and how to use it in this post. We encourage you to take a look at that deployment document and explore the [package itself](https://repo1.dso.mil/big-bang/product/packages/renovate) to see how it might help you with updates. We've also updated the [customer template repo](https://repo1.dso.mil/big-bang/customers/template) with a sample Renovate config to show how it could be used directly in a config repo.
