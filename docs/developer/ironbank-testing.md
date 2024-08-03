# Big Bang Integration Testing Strategy

This document is to detail the Big Bang integration testing strategy for changes to Big Bang images by the container hardening team.

## Using Big Bang repository to Test Changes to Big Bang images

Developers can leverage the Big Bang repository Continuous Integration (CI) pipelines to test the integration with Big Bang core components. Big Bang CI installs core Big Bang applications by default plus additional applications using Merge Request (MR) labels. For example, adding the Nexus label to a Big Bang MR will install Big Bang core (e.g., istio, kyverno, monitoring, tempo, kiali, neuvector, promtail, loki and/or grafana) plus Nexus Repository.

## Big Bang Core Integration Test

To perform an integration test with Big Bang core, complete the following:

1. Create branch in the [Big Bang repository](https://repo1.dso.mil/big-bang/bigbang).
2. Add an override in [bigbang/chart/values.yaml](../../chart/values.yaml) for the image and repository to be tested on your branch. An example is provided below. If testing Nexus, navigate to the Nexus configuration section and modify the values with image and repository overrides. Our CI can pull images from ironbank or ironbank-staging within registry1.dso.mil. 

### Find section in Big Bang chart values:

    NexusRepositoryManager:
        values: {}

### Replace with:

    NexusRepositoryManager:
        values:
            image:
                repository: registry1.dso.mil/ironbank-staging/sonatype/nexus/nexus
                tag: <tagToBeTested>

Big Bang package values can differ from this example. Navigate to the specific Big Bang package in [product packages](https://repo1.dso.mil/big-bang/product/packages) to verify how to override repository and image tag. Repository and image tag can be found in the package values. For example, [Nexus package values](https://repo1.dso.mil/big-bang/product/packages/nexus/-/blob/main/chart/values.yaml)

3. Push branch to repo1.

4. Create draft Merge Request (MR) from your branch into master branch. Be sure to leave the MR in draft status and do not include a review label. If you're testing a package not included in Big Bang core, add the appropriate label for that package. Fill out the description with details, such as testing x.y.z image - container hardening team.

5. Creating an MR should trigger a CI run under the pipelines tab. If the correct package label was added prior to opening the MR, the pipeline should install that package. Review the results of your MR pipeline. Two pipeline jobs are created in the same stage to test the Big Bang umbrella helm chart installation.

**Clean install: Installs Big Bang core, plus any packages included in labels off of the branch being tested. This tests a clean install of Big Bang to a k3d cluster.**

**Upgrade: Installs Big Bang core, plus any packages included in labels off of master. Followed by a helm upgrade to the branch being tested. This tests the upgrade path on a k3d cluster.**

6. Reviewing results of pipeline -> navigate to the output of the pipeline jobs.

### Things to observe from pipeline output:

* Expand the 03_wait_for_helmreleases.sh. At the bottom of this section, users can review that all pods were running on the cluster at completion of this script.
* Collapse the previous section and review the 03_helm_tests.sh. This section should contain results of our CI tests on the live applications installed by Big Bang. Each package testing is different. Packages with frontends typically include a cypress test. Cypress test artifacts can typically be reviewed from the Job Artifacts. Navigate to browse job artifacts to watch a .mp4 video file of the cypress test for your package.
* Some packages do not include cypress tests. Some do not include tests at all (e.g., istioOperator) In this case we recommend validating that the package installed to the cluster and that the tenant application ran successfully in the CI job output. Verify pods running using the 03_wait_for_helmreleases.sh section and all helmReleases succeeded using the Helmreleases section.

7. Once testing is complete, close the MR and the branch will be cleaned up automatically.
