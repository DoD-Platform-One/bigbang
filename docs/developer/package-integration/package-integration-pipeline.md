# Big Bang Package: Pipeline Integration

Big Bang contains and uses a continuous deployment tool to deploy packages using Helm charts sourced from Git.  This document will cover how to integrate a Helm chart from a mission application or other package into the pattern Big Bang requires.  Once complete, you will be able to deploy your package with Big Bang.

## Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Docker CLI](https://docs.docker.com/get-docker/)
- [Big Bang package project containing your Helm chart](./package-integration-upstream.md)
   > You will need to have the Container Registry enabled.This can be requested from the Big Bang team.

> Throughout this document, we will be setting up an application called `podinfo` as a demonstration.

## Package Pipeline

Pipelines provide rapid feedback to changes in our Helm chart as we develop and should be put in place as early as possible.  Big Bang has a few different pipelines that can be used for packages.

- [bigbang-package](https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/-/blob/master/pipelines/bigbang-package.yaml)
- [sandbox](https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/-/blob/master/pipelines/sandbox.yaml)
- [third-party](https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/-/blob/master/pipelines/third-party.yaml)

1. The pipeline **requires** that all images are stored in either Iron Bank (`registry1.dso.mil`) or Repo1 (`registry.dso.mil`).  In some cases, you may be able to substitute images already in Iron Bank for the ones in the Helm chart.  For example, images for `curl`, `kubectl` or `jq` can use `registry1.dso.mil/ironbank/big-bang/base`.  If you have not already submitted your containers to Iron Bank, [start the process](https://repo1.dso.mil/dsop/dccscr/-/blob/master/README.md).  While you are working your way to Iron Bank approval, you can temporarily put the images in `registry.dso.mil` for development by doing the following:

   > Check if the Container Registry is on by navigating to `https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/<your project>/container_registry`.  If you get a 404 error, you need to request a Maintainer turn this feature on in your project via Settings > General > Visibility > Container Registry.

   ```shell
   # Image Info
   export IMGSRC_REPO=docker.io
   export IMGSRC_PROJ=stefanprodan
   export IMGDST_REPO=registry.dso.mil
   export IMGDST_PROJ=platform-one/big-bang/apps/sandbox/podinfo
   export IMGNAME=podinfo
   export IMGTAG=6.0.0

   # Pull image locally
   docker pull $IMGSRC_REPO/$IMGSRC_PROJ/$IMGNAME:$IMGTAG

   # Retag image
   docker tag $IMGSRC_REPO/$IMGSRC_PROJ/$IMGNAME:$IMGTAG $IMGDST_REPO/$IMGDST_PROJ/$IMGNAME:$IMGTAG

   # Login in docker registry
   docker login $IMGDST_REPO

   # Push to registry
   docker push $IMGDST_REPO/$IMGDST_PROJ/$IMGNAME:$IMGTAG
   ```

1. Update `chart/values.yaml` with either the `registry1.dso.mil` or `registry.dso.mil` for images.  For example:

   ```yaml
   image:
     repository: registry.dso.mil/platform-one/big-bang/apps/sandbox/podinfo/podinfo
     tag: 6.0.0
   ```

1. Update the repo's CI/CD settings to call the pipeline (`Settings > CI/CD > General pipelines > Expand > CI/CD configuration file`).

    For Bigbang

   ```plaintext
   pipelines/bigbang-package.yaml@platform-one/big-bang/pipeline-templates/pipeline-templates:master
   ```

    For Third party

   ```plaintext
   pipelines/third-party.yaml@platform-one/big-bang/pipeline-templates/pipeline-templates:master
   ```

    For Sandbox

   ```plaintext
   pipelines/sandbox.yaml@platform-one/big-bang/pipeline-templates/pipeline-templates:master
   ```

1. Add overlay values for testing into `tests/test-values.yaml`.  This will be where you add values needed for running in the pipeline.  For now it can be a blank, placeholder.

1. Commit the changes

   ```shell
   git add -A
   git commit -m "feat: package pipeline"
   git push
   ```

1. Big Bang requires a Merge Request to run the pipeline.  Open a MR to merge your branch into the main branch.

   > You will need to add `SKIP UPDATE CHECK` and `SKIP UPGRADE` into the title of the first MR or it will fail.  Until you have a baseline Helm chart and CHANGELOG in place, these stages need to be skipped.

1. The pipeline will install the package, run any Helm tests (`chart/tests`), and run any custom tests (`tests`).

1. Troubleshoot and fix any failures from the pipeline.

## Big Bang Integration for Third-Party and Sandbox Packages

Big Bang uses a continuous deployment tool, [Flux](https://fluxcd.io) to deploy packages using Helm charts sourced from Git ([GitOps](https://www.weave.works/technologies/gitops/)).

Third-party and sandbox pipelines both have an `integration` stage that will deploy and test a package as a Big Bang compatible package. 

Examples of components that contribute to a package being "Big Bang compatible":

- Configuring a package to be deployed via Flux custom resource definitions ([GitRepositories](https://fluxcd.io/docs/components/source/gitrepositories/) and [HelmReleases](https://fluxcd.io/docs/components/helm/helmreleases/))

- Service mesh components ([Automatic Istio sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) and [Istio VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/))
 
This stage also allows any Big Bang Core or Addon packages to be deployed alongside a third-party or sandbox package for testing compatibility/functionality.

To set this up in a package repo, see the guide [here](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/developer/package-integration/package-integration-flux.md).
