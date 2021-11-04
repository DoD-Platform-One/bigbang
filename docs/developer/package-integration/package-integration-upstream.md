# Big Bang Package: Upstream Integration

Before beginning the process of integrating a package into Big Bang, you will need to create a workspace and create or sync the package's Helm chart.  This document shows you how to setup the workspace and sync the upstream Helm chart.

## Prerequisites

- [Kpt](https://googlecontainertools.github.io/kpt/installation/)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

> Throughout this document, we will be setting up an application called `podinfo` as a demonstration.

## Project

It is recommended that you create your project in [Big Bang's Sandbox](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox).  This allows you to leverage Big Bang's pipelines, collaborate with Big Bang developers, and easily migrate to a fully graduated project.

You will need to request a sandbox project and Developer access from a Big Bang team member.

## Helm Chart

Big Bang requires a Helm chart to deploy your package.  This Helm chart must be enhanced to support full integration with Big Bang components.

### Cloning Upstream

To minimize maintenance, it is preferable to reuse existing Helm charts available in the community (upstream).  Changes to the upstream Helm chart should be made with new files when possible, and always clearly marked as Big Bang additions.

> Sometimes, it is not possible to find an upstream Helm chart and you must develop your own.  This is beyond the scope of this document.

1. Identify the location of an existing Helm chart for the package.

   > If selecting between several Helm charts, give preference to a Helm chart that:
   >
   > - Was created by the company that owns the package
   > - Has recent and frequent updates
   > - Offers maximum flexibility through values
   > - Does not bundle several packages together (unless they can be individually disabled)
   > - Provides advanced features like high availability, scaling, affinity, taints/tolerations, and security context

1. Using [Kpt](https://googlecontainertools.github.io/kpt/installation/), create a clone of the package's Helm chart

   ```shell
   # Change these for your upstream helm chart
   export GITREPO=https://github.com/stefanprodan/podinfo
   export GITDIR=charts/podinfo
   export GITTAG=5.2.1

   # Clone
   kpt pkg get $GITREPO/$GITDIR@$GITTAG chart
   ```

   > Always use an release tag for `GITTAG` so your chart is immutable.  Never use a branch or `latest`.

1. Add `-bb.0` suffix on `chart/Chart.yaml`, `version`.  For example:

   ```yaml
   version: 6.0.0-bb.0
   ```

   > The `bb.#` will increment for each change we merge into our `main` branch.  It will also become our release label.

1. Add the following files to the Git repository at the root:

   - CHANGELOG.md

      The format of the changelog should be based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) with versions equivalent to the Helm chart version.

      Example:

      ```markdown
      # Changelog

      Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

      ## [6.0.0-bb.0] - 2021-09-30
      ### Added
      - Initial creation of the chart
      ```

   - CODEOWNERS

      Code owners are required approvals on merge requests in the Big Bang repository.  This file should be setup based on [GitLab's Code Owners guidance](https://docs.gitlab.com/ee/user/project/code_owners.html).

      Example:

      ```text
      * @gitlabuser
      ```

   - CONTRIBUTING.md

      This document should outline the steps required for someone new to contribute to the repository.

      Example:

      ```markdown
      # Contributing

      This repository uses the following conventions:

      * [Semantic Versioning](https://semver.org/)
      * [Keep a Changelog](https://keepachangelog.com/)
      * [Conventional Commits](https://www.conventionalcommits.org/)
      * [Cypress](https://www.cypress.io) or a shell script for testing

      Development requires the following tools

      * [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
      * [helm](https://helm.sh/docs/intro/install/)
      * [fluxcd](https://fluxcd.io/docs/installation/)

      To contribute a change:

      1. Open an issue in GitLab describing the scope of your work
      1. Assign yourself to the issue
      1. Label the issue with `status::doing`
      1. Create a branch in the repository using your issue number as a prefix
      1. Make changes in code and push to your branch
      1. Write tests using [cypress](https://www.cypress.io) and/or shell scripts.
      1. Make commits using the [Conventional Commits](https://www.conventionalcommits.org/) format
      1. Update `CHANGELOG.md` using the [Keep a Changelog](https://keepachangelog.com) format
      1. Open a merge request into the `main` branch
      1. Add a reference to the issue in the merge request description
      1. Resolve any failures from the pipeline
      1. Resolve any merge conflicts
      1. Label the Merge Request with `status::review`
      1. Contact the code owners to expedite your Merge Request review
      1. Address any review comments and merge conflicts during the review process
      1. Wait for a code owner to approve and merge your changes
      1. Request a repository maintainer to create a release and tag
      ```

   - LICENSE

      The license file should contain the license terms and conditions for using the Helm charts.  In general, Big Bang uses the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).

   - README.md

      The readme contains high-level information about the package.  This document covers the following topics:

      - Upstream References: Links to external documentation
      - Documents: Links to /docs in repository
      - Prerequisites: Tools needed to install and use
      - Deployment: How to install / upgrade
      - Values: How to configure Helm chart values
      - Contributing: Link to contributing guide

      There is a standard Big Bang template used for all packages.  This can be created by following the [templating instructions](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md)

      > This process produces a `README.md`, `README.md.gotpl`, and `.helmdocsignore`.  The `gotpl` file is used as values to update the `README.md`.

      > To avoid having the `flux` helm chart also added to the `README.md`, run `echo 'flux/*' >> .helmdocsignore`

      Example:

      ```markdown
      # podinfo

      ![Version: 6.0.0-bb.0](https://img.shields.io/badge/Version-6.0.0--bb.0-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square)

      Podinfo Helm chart for Kubernetes

      ## Upstream References
      * <https://github.com/stefanprodan/podinfo>

      ## Learn More
      * [Application Overview](docs/overview.md)
      * [Other Documentation](docs/)

      ## Pre-Requisites

      * Kubernetes Cluster deployed
      * Kubernetes config installed in `~/.kube/config`
      * Helm installed

      Kubernetes: `>=1.19.0-0`

      Install Helm

      https://helm.sh/docs/intro/install/

      ## Deployment

      * Clone down the repository
      * cd into directory
      * helm install podinfo chart/

      ## Values

      | Key | Type | Default | Description |
      |-----|------|---------|-------------|
      | replicaCount | int | `1` |  |
      | logLevel | string | `"info"` |  |
      | host | string | `nil` |  |
      | backend | string | `nil` |  |
      ...

      ## Contributing

      Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
      ```

1. Commit changes

   ```shell
   git add -A
   git commit -m "feat: initial helm chart"
   git push --set-upstream origin bigbang
   ```

### Updating Upstream

If a new version of the upstream Helm chart is released, this is how to sync it and retain the Big Bang enhancements.

```shell
export GITTAG=6.0.0

# Before upgrading, identify changes made to upstream chart
kpt pkg diff chart > bb-mods-pre.txt

# Sync with new Helm chart release
kpt pkg update chart@$GITTAG --strategy alpha-git-patch

# Resolve merge conflicts, if any, by
# - Manually merging conflicts identified
# - Add changes to git using `git add`
# - Continuing the patch with `git am --continue`

# After upgrading, identify deltas to upstream chart
kpt pkg diff chart > bb-mods-post.txt

# Look at the differences between the pre and post changes to make sure nothing was missed.  Add any missing items back into the chart
diff bb-mods-pre.txt bb-mods-post.txt

# Commit and push changes
rm bb-mods-*.txt
git add -A
git commit -m "chore: update helm chart to $GITTAG"
git push
```

> In Kpt 1.0, `alpha-git-patch` was renamed to `resource-merge`.

## Validation

If you are not already familiar with the package, deploy the package using the upstream helm chart onto a Kubernetes cluster and explore the functionality before continuing.  The Helm chart can be deployed according to the upstream package's documentation.

 > It is recommended that you follow the instructions in [development environment](../development-environment.md) to get a Kubernetes cluster running.
