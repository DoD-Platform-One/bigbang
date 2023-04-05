# Airgap w/Zarf

> ⚠️ This is a work in-progress.

### Requires Big Bang 1.54.0 and greater.

This section is currently purely devoted to building and testing packages on a development cluster.  The result could be a set of archives that can be used for moving across an airgap.  Essentially this automates a few of the steps indicated in this [documentation](https://github.com/defenseunicorns/zarf/blob/main/docs/13-walkthroughs/5-big-bang.md).

The first step would be to stand up a Big Bang dev cluster.  This is most easily represented by following the steps outlined here, but would ultimately result in running the below command, which stands up a larger development cluster.  Take note of the KeyName and Public IP address which will be used in a later step.

```shell
docs/assets/scripts/developer/k3d-dev.sh -b
```

Be sure to export your Registry1 credentials next as seen below:

```shell
export REGISTRY1_USERNAME=<username>
export REGISTRY1_CLI_SECRET=<password>
```

Now you can execute the following: 

```shell
KeyName=<KeyName> PublicIP=<Ip> docs/assets/scripts/airgap-zarf/zarf-dev.sh
```

The above will clone the latest  `main` branch of the [defenseunicorns/zarf](https://github.com/defenseunicorns/zarf) repository and execute the stock `examples/big-bang/zarf.yaml`.  If you want to use a different `zarf.yaml`, you can override this by setting any of these variables ahead of time, either by exporting them or setting them as part of the command.

* `ZARF_TEST_REPO`: sets the repository to clone from.
* `ZARF_TEST_REPO_BRANCH`: sets the branch to switch to from the cloned repo.
* `ZARF_TEST_REPO_DIRECTORY`: sets the directory where the desired `zarf.yaml` is.

Also since this all uses the same dev script, you should be able to use whatever k8s tooling (such as `kubectl` or `k9s`) you already might use on a dev cluster as `KUBECONFIG` is still transferred locally and available.
