# Upstream Integration

Before beginning the process of integrating a package into Big Bang, you will need to create a workspace and create or sync the package's Helm chart. This document shows you how to set up the workspace and sync the upstream Helm chart.

## Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Helm](https://helm.sh/docs/intro/install/)

> Throughout this document, we will be setting up an application called `podinfo` as a demonstration.

## Project

It is recommended that you create your project in [Big Bang's Sandbox](https://repo1.dso.mil/big-bang/apps/sandbox). This allows you to leverage Big Bang's pipelines, collaborate with Big Bang developers, and easily migrate to a fully graduated project.

You will need to request a sandbox project and Developer access from a Big Bang team member.

## Helm Chart

Big Bang requires a Helm chart to deploy your package. This Helm chart must be enhanced to support full integration with Big Bang components.

### Cloning Upstream

To minimize maintenance, we reuse existing Helm charts available in the community (upstream). _We do not fork upstream charts._ Changes to the upstream Helm chart should be avoided when possible, additional templates can be added to the chart in a /bigbang templates folder. Leverage mutating webhooks with Kyverno or postRenderers to overlay changes to an upstream chart.

> Sometimes, it is not possible to find an upstream Helm chart and you must develop your own. This is beyond the scope of this document.

1. Identify the location of an existing Helm chart for the package.

    > If selecting between several Helm charts, give preference to a Helm chart that:
    >
    > * Was created by the company that owns the package;
    > * Has recent and frequent updates;
    > * Offers maximum flexibility through values;
    > * Does not bundle several packages together (unless they can be individually disabled); and
    > * Provides advanced features like high availability, scaling, affinity, taints/tolerations, and security context.

1. With the release of Big Bang 3.0, we are transitioning our package charts to a passthrough pattern. Rather than forking upstream charts with the kpt.dev tool, we now pull in charts and wrap them with a package chart. Passing the upstream chart through without modifications greatly reduces the update workload. When updating with custom modifications there are challenging merge conflicts to resolve. Passthrough pattern avoids this problem and should streamline the process of bringing in new packages and updating them via Renovate updater. 

   Helm can be used to pull down the chart initially: 
    
   ```shell
    helm pull podinfo/podinfo
   ```
   This will pull a number of superfluous files that we will not need for our repo. 

   After that, copy the upstream `Chart.yaml` file into your repo under the `/chart` directory. Since this Chart.yaml will serve as a wrapper chart for the package, remove things like annotations from artifacthub.io and upstream maintainers. Leave version and description. As part of our integration, we want a helm.sh/images annotation with a list of deployable images from the package, as well as a number of bigbang.dev annotations. Next, in order to wrap the upstream chart, we simply add the package chart itself as a dependency in the Big Bang chart, like so: 

   ```yaml
    apiVersion: v1
    version: 6.9.0-bb.0
    appVersion: 6.9.0
    name: podinfo
    engine: gotpl
    description: Podinfo Helm chart for Kubernetes
    dependencies:
      - name: podinfo 
        version: 6.9.0
        repository: https://stefanprodan.github.io/podinfo
        alias: upstream
    kubeVersion: ">=1.23.0-0"
    annotations:
      bigbang.dev/maintenanceTrack: bb_integrated
      helm.sh/images: |
        - name: podinfo
          image: registry1.dso.mil/ironbank/opensource/podinfo:6.9.0 
   ```

1. Add `-bb.0` suffix on `chart/Chart.yaml`, `version`.  For example:

    ```yaml
    version: 6.0.0-bb.0
    ```

    > The `bb.#` will increment for each change we merge into our `main` branch.  It will also become our release label.
   
   Please note, `version` and `appVersion` are not [necessarily the same](https://repo1.dso.mil/big-bang/product/packages/keycloak/-/blob/main/chart/Chart.yaml?ref_type=heads), especially if the chart is not maintained by the creator of the application. 

1. Add the following files to the Git repository at the root:

   - CHANGELOG.md

   The format of the changelog should be based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) with versions equivalent to the Helm chart version. An example is provided in the following:

      ```markdown
      # Changelog

      Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

      ## [6.0.0-bb.0] - 2021-09-30
      ### Added
      - Initial creation of the chart
      ```

   - CODEOWNERS

      Code owners are required approvals on merge requests in the Big Bang repository. This file should be setup based on [GitLab's Code Owners guidance](https://docs.gitlab.com/user/project/codeowners/). An example is provided in the following:

      ```plaintext
      * @gitlabuser
      ```

   - CONTRIBUTING.md

      This document should outline the steps required for someone new to contribute to the repository. An example is provided in the following:

    ```markdown
   # Contributing

      This repository uses the following conventions:

      * [Semantic Versioning](https://semver.org/)
      * [Keep a Changelog](https://keepachangelog.com/)
      * [Conventional Commits](https://www.conventionalcommits.org/)
      * [Cypress](https://www.cypress.io) or a shell script for testing

      Development requires the following tools:

      * [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
      * [helm](https://helm.sh/docs/intro/install/)
      * [fluxcd](https://fluxcd.io/docs/installation/)

      To contribute a change:

      1. Open an issue in GitLab describing the scope of your work.
      2. Assign yourself to the issue.
      3. Label the issue with `status::doing`.
      4. Create a branch in the repository using your issue number as a prefix.
      5. Make changes in code and push to your branch.
      6. Write tests using [cypress](https://www.cypress.io) and/or shell scripts.
      7. Make commits using the [Conventional Commits](https://www.conventionalcommits.org/) format.
      8. Update `CHANGELOG.md` using the [Keep a Changelog](https://keepachangelog.com) format.
      9. Open a merge request into the `main` branch.
      10. Add a reference to the issue in the merge request description.
      11. Resolve any failures from the pipeline.
      12. Resolve any merge conflicts.
      13. Label the Merge Request with `status::review`.
      14. Contact the code owners to expedite your Merge Request review.
      15. Address any review comments and merge conflicts during the review process.
      16. Wait for a code owner to approve and merge your changes.
      17. Request a repository maintainer to create a release and tag.
      ```

   - LICENSE

      The license file should contain the license terms and conditions for using the Helm charts. In general, Big Bang uses the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).

   - README.md

      The readme contains high-level information about the package.  This document covers the following topics:

      - Upstream References: Links to external documentation
      - Documents: Links to /docs in repository
      - Prerequisites: Tools needed to install and use
      - Deployment: How to install / upgrade
      - Values: How to configure Helm chart values
      - Contributing: Link to contributing guide

      There is a standard Big Bang template used for all packages.  This can be created by following the [templating instructions](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-package-readme.md)

      > This process produces a `README.md`, `README.md.gotpl`, and `.helmdocsignore`.  The `gotpl` file is used as values to update the `README.md`.
      > To avoid having the `flux` helm chart also added to the `README.md`, run `echo 'flux/*' >> .helmdocsignore`.

      Example:

<!-- markdownlint-disable -->
      ```markdown
      # podinfo

      ![Version: 6.0.0-bb.0](https://img.shields.io/badge/Version-6.0.0--bb.0-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square).

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

      | Key          | Type   | Default  | Description |
      | ------------ | ------ | -------- | ----------- |
      | replicaCount | int    | `1`      |             |
      | logLevel     | string | `"info"` |             |
      | host         | string | `nil`    |             |
      | backend      | string | `nil`    |             |
      ...

      ## Contributing

      Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
      ```
<!-- markdownlint-enable -->



5. Commit changes.

   ```shell
   git add -A
   git commit -m "feat: initial helm chart"
   git push --set-upstream origin bigbang
   ```

### Updating Upstream

If a new version of the upstream Helm chart is released, the passthrough pattern makes updating very simple.
1. Update the `chart.yaml` to the new chart version:

   ```yaml
    apiVersion: v1
    version: X.X.X-bb.0
    appVersion: 6.9.0
    name: podinfo
    engine: gotpl
    description: Podinfo Helm chart for Kubernetes
    dependencies:
      - name: podinfo 
        version: X.X.X
        repository: https://stefanprodan.github.io/podinfo
        alias: upstream
   ```
1. Run `helm dependency update ./chart`. This will pull the new version of the chart into `chart/charts` 
 1. Document changes in `CHANGELOG.md` and update the `README.md` using the [gluon library script](https://repo1.dso.mil/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md)


## Validation

If you are not already familiar with the package, deploy the package using the upstream helm chart onto a Kubernetes cluster and explore the functionality before continuing. The Helm chart can be deployed according to the upstream package's documentation.

 > It is recommended that you follow the instructions in [development environment](../development-environment.md) to get a Kubernetes cluster running.
