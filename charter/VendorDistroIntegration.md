# Testing Vendor Distributions in our Pipeline

## Overview

Vendor distributions are tested within the umbrella project's ci [pipelines][0]. These pipelines include jobs from the [umbrella-templates][1] repository.

The main thing to take into account is your cluster should have:

* Single stage for spinning up
* Single stage for spinning down
* Within each job you're allowed whatever tools/resources needed just store them in the `jobs/<your-job>/dependencies` folder
* We provision a VPC and subnets inside a separate job, you can access this information via `terraform remote_state`
* We expect you to export the `kubeconfig` file to connect to your cluster as a `GitLab artifact`

Vendors can ignore the `smoke tests` as they are run against a k3d cluster. All other stages are important for vendors to understand. We have also made the assumption that `terraform` is the base tool that all vendors will use to deploy their clusters in our pipelines.

### Working Example

A working example for rke2 can be found [here][2] (Note this link is pinned to a specific commit to show you exactly where in the code it is being implemented, look at the code to get a gist then view `master` branch to make sure nothing has changed).

You can find more information about specific jobs in each jobs specific README.md inside [umbrella-templates][1]

[0]: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/pipelines
[1]: https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/umbrella-templates
[2]: https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/a1b7926ce05127a57661fe5ff72c6d7a23db0470/.gitlab-ci.yml#L148
