# Current Pipeline Outline and Notes

1. .pre

    1. **changelog**

        Does a diff to lint what has changed for the logs.
    1. **commits**

        Enforces the conventional commits stuff.
    1. **pre vars**

        pre checks
    1. **version**

        Gets various versions to build a complex version number for the build.

1. **smoke tests**

    1. **clean install**

        Doesn't really effect airgap, this sets up things like cluster names and such.
    1. **upgrade**

        Splits out testing and determines if there are breaking changes for testing of upgrades.

1. **network up**

    1. **airgap/network up**

        Creates a VPC and subnets for the cluster to be deployed in.
    1. **aws/airgap/package**

        Packages everything needed for the airgap install into a tar file. This leaves the repositories and images bundled in the Releases section for BB [https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases)

1. **airgap up**

    1. **aws/airgap/utility up**

        Sets up proxies using Route 53 to essentially fake out where Repo 1 and Registry 1 exist for the purposes of using an air gap registry and git repo.

1. **cluster up**

    1. **airgap/rke2/cluster up**

        Stands up an RKE2 cluster for BB in an airgapped network. \*\* Uses terraform ./gitlab-ci/jobs/rke2/dependencies/terraform/

        Both this and the non-airgapped use the same image registry.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/k3d-builder:0.0.1

1. **bigbang up**

    1. **airgap/rke2/bigbang up**

        Stands up the Big Bang instance.

1. **test**

    1. **airgap/rke2/bigbang test**

        Runs some basic tests to make sure that Big Bang is up and working.

1. **bigbang down**

    1. **airgap/rke2/bigbang down**

        Tears down the Big Bang instance.

1. **cluster down**

    1. **airgap/rke2/cluster down**

1. **airgap down**

    1. **aws/airgap/package delete**

    1. **aws/airgap/utility down**

1. **network down**

    1. **airgap/network down**
