# Quick Start

[[_TOC_]]

## Big Bang in 1 hour

An SRE with a reasonable amount of experience operating in a command line environment, equipped with a fast internet connection and a workstation they can install software on, should be able to complete this process and have an operational Big Bang dev environment in 1 hour or less.

### Satisfy the Prerequisites

1. Ensure your workstation has a functional GNU environment with `git`. Mac OS and Linux should be good to go out of the box. For Windows, the **only** supported method for this guide is to install WSL and run a WSL bash terminal, following the rest of the guide as a Linux user inside WSL.
1. Install [jq](https://jqlang.github.io/jq/download/).
1. Install [yq](https://github.com/mikefarah/yq/#install). yq needs to be available in your system path PATH as `yq`, so we recommend not using a dockerized installation.
1. Install kubectl. Follow the instructions for [windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/), [macos](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/) or [linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/). (If you are running on WSL in Windows, you should install kubectl using the package manager inside of WSL to install kubectl.)
1. [Install helm](https://helm.sh/docs/intro/install/).
1. [Install the Flux CLI](https://fluxcd.io/flux/installation/).
1. Ensure you have bash version 4 installed. Linux and Windows with WSL users probably don't need to worry about this. For Mac OS users, install bash4 with homebrew or a similar package manager, as the bash that ships with Mac OS is hopelessly old. Mac OS users will use `/opt/homebrew/bin/bash` whenever `bash` is mentioned in this guide.
1. Ensure you have an account on [PlatformOne RegistryOne](https://registry1.dso.mil). You will need your username and access token ("CLI Secret") for this process. (To retrieve your token, login to registry1, click your name in the top right, and copy the "CLI Secret" field.)
1. If you do not plan to deploy the bigbang quickstart cluster onto your own VM, and want the quickstart script to provision an AWS VM for you, you need to install and configure [the AWS cli](https://aws.amazon.com/cli/) for your AWS account.

### Download the Quickstart Script

Run the following commands in your terminal to download the quickstart script, which you will use in the next step:

```
export REGISTRY1_USERNAME=YOUR_REGISTRY1_USERNAME
export REGISTRY1_TOKEN=YOUR_REGISTRY1_TOKEN
export REPO1_LOCATION=LOCATION_ON_FILESYSTEM_TO_CHECK_OUT_BIGBANG_CODE

curl --output quickstart.sh https://repo1.dso.mil/big-bang/bigbang/-/raw/master/docs/assets/scripts/quickstart.sh?ref_type=heads
```

### Build the Cluster

#### Using a VM or other hardware you built yourself

1. Spin up an Ubuntu VM somewhere with 8 CPUs and 32gB of RAM. Make sure you can SSH to it. It doesn't matter what cloud provider you're using, it can even be on your local system if you have enough horsepower for it. 
1. Run the following command in your command terminal:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH
```

#### Using Amazon Web Services

1. If your system is already configured to use AWS via the `aws-cli` and you don't want to go to the trouble of building your own VM, the quickstart can attempt to do it for you; simply run the quickstart with no arguments. Pay attention to the script output; the IP addresses of the created AWS EC2 instance will be printed after the cluster is built and before big bang is deployed. You may need these later.
    1. The quickstart is only so smart, and AWS environments can vary greatly. If the quickstart is not able to build an EC2 instance in AWS for you, please go build an EC2 instance suitable for your use case, then come back and follow the instructions for "Using a VM or other hardware you built yourself".
1. Run the following commands in your command terminal:

```
bash quickstart.sh
```

### It's thinking

The process takes about 45 minutes. Make a sandwich, go for a walk, play with the dog. Check on it every 10 minutes or so. Once the command finishes, your cluster should be ready to use. Proceed to fix your DNS and access your big bang installation.

If it seems like it's taking too long, the script will tell you what it's currently waiting on. The most frequent cause of long delays is slow connection between your cluster and registry1. All container images are fetched from registry1, so if your cluster is running on a slow internet uplink, this process can take a long time the first time bigbang is deployed. If your helmreleases say `PodInitializing` or `ContainerInitializing` or `Init:2/3` for a long time, this is usually the cause. There's not much cure for this but patience. Try contemplating the nature of the universe, marvel at the fact that object oriented COBOL exists in `current year`, or peruse the Commander's reading list.

Eventually the bigbang release process will finish, and you'll see output like this:

```
==================================================================================
                          INSTALLATION   COMPLETE

To access your kubernetes cluster via kubectl, export this variable in your shell:

    export KUBECONFIG=~/.kube/192.168.1.123-quickstart-dev-config

To access your kubernetes cluster in your browser, add this line to your hosts file:

    192.168.1.123        alertmanager.dev.bigbang.mil prometheus.dev.bigbang.mil grafana.dev.bigbang.mil

To SSH to the instance running your cluster, use this command:

    ssh -i ~/.ssh/192.168.1.123-dev-quickstart.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@192.168.1.123
================================================================================
```

Congratulations, it's ready!

### What Just Happened? In Detail

The quickstart.sh script performs several actions:

1. Checks your system to make sure the prerequisites we talked about are present
1. If you're an AWS Cloud user who didn't provide `-H`, `-K`, and `-U` settings, attempts to build an EC2 instance suitable for use as a Big Bang cluster inside the default VPC in your configured AWS account and region
1. Connects to your system over SSH to perform several configuration steps, including:
    1. Enabling passwordless sudo
    1. Ensuring your system packages are up to date
    1. Installing k3d/k3s
    1. Configuring a single-node Kubernetes cluster on your VM using k3d
1. Installs the flux kubernetes extensions on your k3d cluster
1. Checks out the PlatformOne Big Bang repository to the location specified when you ran the command
1. Installs the Big Bang umbrella chart into your k3d cluster
1. Waits for Big Bang to completely deploy, which may take a significant amount of time

### Fix DNS to access the services in your browser

You can now access your bigbang kubernetes cluster from the command line using `kubectl`, but you will need to perform one extra step to easily access bigbang services in your web browser. You will need to manually override some DNS settings to send specific website requests to your kubernetes cluster. This was included in the final message of the quickstart, but here are the instructions again.

**Remember to un-do this step when you are done experimenting with the bigbang quickstart.**

#### Linux/Mac Users

Run this command in your terminal:

```shell
echo YOUR_VM_IP       $(kubectl get virtualservices -A -o json | jq -r .items[].spec.hosts[0] | tr "\n" "\t") | sudo tee -a /etc/hosts
```

#### Windows Users

Run this command in your bash terminal, and copy the output to your clipboard.

```shell
echo YOUR_VM_IP       $(kubectl get virtualservices -A -o json | jq -r .items[].spec.hosts[0] | tr "\n" "\t")
```

1. Right click Notepad -> Run as Administrator
1. Open C:\Windows\System32\drivers\etc\hosts
1. Add the line from your clipboard to the bottom of the file
1. Save and close

### Access a BigBang Service

In a browser, visit one of the sites that you just added to your hosts file.

Note, default credentials for Big Bang packages can be found [here](../using-bigbang/default-credentials.md).

### Tinker With It

You can use the quickstart script to update your bigbang quickstart deployment with your own modifications. Here's an example of post deployment customization of Big Bang.  After looking at <https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.yaml>, you can see that this will enable the ArgoCD addon, which is not enabled by default.

```shell
# [ubuntu@Ubuntu_VM:~]

cat << EOF > ~/tinkering.yaml
addons:
  argocd:
    enabled: true
EOF
```

Now we redeploy using the same command as before, but adding some additional options to point to the tinkering.yaml file we just created.

If you're deploying your own infrastructure:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  --deploy \
  -- -f ${HOME}/tinkering.yaml
```

If you're using the script to provision your own infrastructure on AWS:

```
bash quickstart.sh --deploy -- -f ${HOME}/tinkering.yaml
```

You will see the same kind of output as before, with the big bang release being updated, and the script waiting for all releases to be present.

Now you should be able to see the ArgoCD virtual service:

```
kubectl get vs -A
kubectl get po -n=argocd
```

... And you can update your hosts file from the previous step to include the ArgoCD address from the virtualservice, and view it in your browser.

### Implementing Mission Applications within your bigbang environment

Big Bang by itself serves as a jumping off point, but many users will want to implement their own mission specific applications in to the cluster. BigBang has implemented a `packages:` and `wrapper:`  section to enable and support this in a way that ensures connectivity between your mission specific requirements and existing BigBang utilities, such as istio, the monitoring stack, and network policy management. [Here](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/deployment-scenarios/extra-package-deployment.md) is the documentation for the `packages` utility.

We will implement a simple additional utility as a proof of concept, starting with a basic podinfo client. This will use the `wrapper` key to provide integration between bigbang and the Mission Application, without requiring the full Istio configuration to be placed inside BigBang specific keys of the dependent chart.


```shell
cat << EOF > ~/podinfo_wrapper.yaml
packages:
  # -- Package name.  Each package will be independently wrapped for Big Bang integration.
  # @default -- Uses `defaults/<package name>.yaml` for defaults.  See `package` Helm chart for additional values that can be set.
  podinfo:
    # -- Toggle deployment of this package
    # @default -- true
    enabled: true

    # -- Toggle wrapper functionality. See https://docs-bigbang.dso.mil/latest/docs/guides/deployment-scenarios/extra-package-deployment/#Wrapper-Deployment for more details.
    # @default -- false
    wrapper:
      enabled: true

    # -- Use a kustomize deployment rather than Helm
    kustomize: false

    # -- HelmRepo source is supported as an option for Helm deployments. If both `git` and `helmRepo` are provided `git` will take precedence.
    helmRepo:
      # -- Name of the HelmRepo specified in `helmRepositories`
      # @default -- Uses `registry1` Helm Repository if not specified
      repoName:
      # -- Name of the chart stored in the Helm repository
      # @default -- Uses values key/package name if not specified
      chartName:
      # -- Tag of the chart in the Helm repo, required
      tag:

    # -- Git source is supported for both Helm and Kustomize deployments. If both `git` and `helmRepo` are provided `git` will take precedence.
    git:
      # -- Git repo URL holding the helm chart for this package, required if using git
      repo: "https://repo1.dso.mil/big-bang/product/packages/podinfo.git"
      # -- Git commit to check out.  Takes precedence over semver, tag, and branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      commit:
      # -- Git semVer tag expression to check out.  Takes precedence over tag. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      semver:
      # -- Git tag to check out.  Takes precedence over branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      tag: "6.0.0-bb.7"
      # -- Git branch to check out.  [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference).
      # @default -- When no other reference is specified, `master` branch is used
      branch:
      # -- Path inside of the git repo to find the helm chart or kustomize
      # @default -- For Helm charts `chart`.  For Kustomize `/`.
      path: "chart"

    # -- Override flux settings for this package
    flux: {}

    # -- After deployment, patch resources.  [More info](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers)
    postRenderers: []

    # -- Specify dependencies for the package. Only used for HelmRelease, does not effect Kustomization. See [here](https://fluxcd.io/flux/components/helm/helmreleases/#helmrelease-dependencies) for a reference.
    dependsOn: []

    # -- Package details for Istio.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    istio:
      hosts:
        - names:
            - missionapp
          gateways:
            - public
          destination:
            service: missionapp-missionapp
            port: 9898

    # -- Package details for monitoring.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    monitor: {}

    # -- Package details for network policies.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    network: {}

    # -- Secrets that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    secrets: {}

    # -- ConfigMaps that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    configMaps: {}

    # -- Values to pass through to package Helm chart
    values: 
      istio:
        enabled: "{{ .Values.istio.enabled }}"
      ui:
        color: "#fcba03" #yellow

EOF
```

If you're deploying on your own infrastructure:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  --deploy \
  -- -f $HOME/podinfo_wrapper.yaml
```

If you're using the script to provision your own infrastructure on AWS:

```
bash quickstart.sh --deploy -- -f $HOME/podinfo_wrapper.yaml
```

Now missionapp should show up, if it doesn't wait a minute and rerun the command

```
kubectl get vs -A

kubectl get po -n=missionapp
# Once these are all Running you can visit missionapp's webpage after editing DNS to include the new host
```

Wrappers also allow you to abstract out Monitoring, Secrets, Network Policies, and ConfigMaps. Additional Configuration information can be found [here](./extra-package-deployment.md)


## Important Security Notice

All Developer and Quick Start Guides in this repo are intended to deploy environments for development, demonstration, and learning purposes. There are practices that are bad for security, but make perfect sense for these use cases: using of default values, minimal configuration, tinkering with new functionality that could introduce a security misconfiguration, and even purposefully using insecure passwords and disabling security measures like Kyverno for convenience. Many applications have default username and passwords combinations stored in the public git repo, these insecure default credentials and configurations are intended to be overridden during production deployments.

When deploying a dev/demo environment there is a high chance of deploying Big Bang in an insecure configuration. Such deployments should be treated as if they could become easily compromised if made publicly accessible.

### Recommended Security Guidelines for Dev/Demo Deployments

* Ideally, these environments should be spun up on VMs with private IP addresses that are not publicly accessible. Local network access or an authenticated remote network access solution like a VPN or [sshuttle](https://github.com/sshuttle/sshuttle#readme) should be used to reach the private network.
* DO NOT deploy publicly routable dev/demo clusters into shared VPCs (i.e., like a shared dev environment VPCs) or on VMs with IAM Roles attached. If the demo cluster were compromised, an adversary might be able to use it as a stepping stone to move deeper into an environment.
* If you want to safely demo on Cloud Provider VMs with public IPs you must follow these guidelines:
  * Prevent Compromise:
    * Use firewalls that only allow the two VMs to talk to each other and your whitelisted IP.
  * Limit Blast Radius of Potential Compromise:
    * Only deploy to an isolated VPC, not a shared VPC.
    * Only deploy to VMs with no IAM roles/rights attached.

## Network Requirements Notice

This install guide by default requires network connectivity from your server to external DNS providers, specifically the Google DNS server at `8.8.8.8`, you can test that your node has connectivity to this DNS server by running the command `nslookup google.com 8.8.8.8` (run this from the node).

If this command returns `DNS request timed out`, then you will need to follow the steps in [troubleshooting](#Troubleshooting) to change the upstream DNS server in your kubernetes cluster to your networks DNS server.

Additionally, if your network has a proxy that has custom/internal SSL certificates then this may cause problems with pulling docker images as the image verification process can sometimes fail. Ensure you are aware of your network rules and restrictions before proceeding with the installation in order to understand potential problems when installing.

## Important Background Contextual Information

`BLUF:` This quick start guide optimizes the speed at which a demonstrable and tinker-able deployment of Big Bang can be achieved by minimizing prerequisite dependencies and substituting them with quickly implementable alternatives. Refer to the [Customer Template Repo](https://repo1.dso.mil/big-bang/customers/template) for guidance on production deployments.

`Details of how each prerequisite/dependency is quickly satisfied:`  

* **Operating System Prerequisite:** Ubuntu is presumed by the guide and all supporting scripts. Any linux distribution that supports Docker can be made to run k3d or kubernetes, but this guide presumes Ubuntu for the sake of efficiency.
* **Operating System Pre-configuration:** This quick start includes easy paste-able commands to quickly satisfy this prerequisite.
* **Kubernetes Cluster Prerequisite:** is implemented using k3d (k3s in Docker)
* **Default Storage Class Prerequisite:** k3d ships with a local volume storage class.
* **Support for automated provisioning of Kubernetes Service of type LB Prerequisite:** is implemented by taking advantage of k3d's ability to easily map port 443 of the VM to port 443 of a Dockerized LB that forwards traffic to a single Istio Ingress Gateway. Important limitations of this quick start guide's implementation of k3d to be aware of:
  * Multiple Ingress Gateways aren't supported by this implementation as they would each require their own LB, and this trick of using the host's port 443 only works for automated provisioning of a single service of type LB that leverages port 443.
  * Multiple Ingress Gateways makes a demoable/tinkerable KeyCloak and locally hosted SSO deployment much easier.
  * Multiple Ingress Gateways can be demoed on k3d if configuration tweaks are made, MetalLB is used, and you are developing using a local Linux Desktop. (network connectivity limitations of the implementation would only allow a the web browser on the k3d host server to see the webpages.)
  * If you want to easily demo and tinker with Multiple Ingress Gateways and Keycloak, then MetalLB + k3s (or another non-Dockerized Kubernetes distribution) would be a happy path to look into. (or alternatively create an issue ticket requesting prioritization of a keycloak quick start or better yet a Merge Request.)
* Access to Container Images Prerequisite is satisfied by using personal image pull credentials and internet connectivity to <https://registry1.dso.mil>
* Customer Controlled Private Git Repo Prerequisite isn't required due to substituting declarative git ops installation of the Big Bang Helm chart with an imperative helm cli based installation.
* Encrypting Secrets as code Prerequisite is substituted with clear text secrets on your local machine.
* Installing and Configuring Flux Prerequisite: Not using GitOps for the quick start eliminates the need to configure flux, and installation is covered within this guide.
* HTTPS Certificate and hostname configuration Prerequisites: Are satisfied by leveraging default hostname values and the demo HTTPS wildcard certificate that's uploaded to the Big Bang repo, which is valid for *.bigbang.dev, *.admin.bigbang.dev, and a few others. The demo HTTPS wildcard certificate is signed by the Lets Encrypt Free, a Certificate Authority trusted on the public internet, so demo sites like grafana.bigbang.dev will show a trusted HTTPS certificate.
* DNS Prerequisite: is substituted by making use of your workstation's Hosts file.

## Troubleshooting
This section will provide guidance for troubleshooting problems that may occur during your Big Bang installation and instructions for additional configuration changes that may be required in restricted networks. 

### Connection Failures and Read API Failures

Sometimes you will see Read API failures and connection failures immediately after the k3d cluster has been configured, when the flux extensions are being deployed to the cluster. If this happens, wait a few minutes, and re-try the deployment step. Run the same command you just ran, but add the `--deploy` option to it.

If you're deploying your own infrastructure:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  --deploy
```

If you're using the script to provision your own infrastructure on AWS:

```
bash quickstart.sh --deploy
```

### Timed Out

If you see errors that talk about something timing out while waiting for conditions, re-run your `quickstart.sh` command again, but add the `--wait` flag to it. This will cause the script to resume after the deployment step and continue to wait for the release to become healthy.

If you're deploying your own infrastructure:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  --wait
```

If you're using the script to provision your own infrastructure on AWS:

```
bash quickstart.sh --wait
```

### Changing CoreDNS upstream DNS server:
After completing step 5, if you are unable to connect to external DNS providers using the command `nslookup google.com 8.8.8.8`, to test the connection. Then use the steps below to change the upstream DNS server to your networks DNS server. Please note that this change will not perist after a restart of the host server therefore, if you restart or shutdown your server you will need to re-apply these changes to CoreDNS. 

1. Open config editor to change the CoreDNS pod configuration.

    ```shell
    kubectl -n kube-system edit configmaps CoreDNS -o yaml 
    ```

1. Change: 

    ```plaintext
    forward . /etc/resolv.conf
    ```

    To:

    ```plaintext
    forward . <DNS Server IP>
    ```

1. Save changes in editor (for vi use `:wq`).

1. Verify changes in terminal output that prints new config 

### Useful Commands for Obtaining Detailed Logs from Kubernetes Cluster or Containers

* Print all pods including information related to the status of each pod.
	```shell
	kubectl get pods --all-namespaces
	```
* Print logs for specified pod.
	```shell 
	kubectl logs <pod name> -n=<namespace of pod> 
	```
* Print a dump of relevent information for debugging and diagnosing your kubernetes cluster.
	```shell
	kubectl cluster-info dump
	```

### Documentation References for Command Line Tools Used

* Kubectl - https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands 
* k3d - https://k3d.io/v5.5.1/usage/k3s/
* Docker - https://docs.docker.com/desktop/linux/troubleshoot/#diagnosing-from-the-terminal
* Helm - https://helm.sh/docs/helm/helm/

### NeuVector "Failed to Get Container"

If the NeuVector pods come online but give errors like:

```shell
ERRO|AGT|container.(*containerdDriver).GetContainer: Failed to get container - error=container "4d9a6e20883271ed9f921e86c7816549e9731fbd74cefa987025f27b4ad59fa1" in namespace "k8s.io │
ERRO|AGT|main.main: Failed to get local device information - error=container "4d9a6e20883271ed9f921e86c7816549e9731fbd74cefa987025f27b4ad59fa1" in namespace "k8s.io": not found 
```

It could be because Ubuntu prior to 21 ships with cgroup v1 by default, and NeuVector on cgroup v1 with containerd doesn't work well. To check if your installation is running cgroup v1, run:

```shell
cat /sys/fs/cgroup/cgroup.controllers
```

If you get a "No such file or directory", that means its running v1, and needs to be running v2. Follow the documentation here - https://rootlesscontaine.rs/getting-started/common/cgroup2/#checking-whether-cgroup-v2-is-already-enabled to enable v2

### "Too Many Open Files"

If the NeuVector pods fail to open, and you look at the K8s logs only to find that it's giving the "too many open files" error, you'll need to increase your inotify max's. Consider grabbing your current fs.inotify.max values and increasing them like the following

```shell
sudo sysctl fs.inotify.max_queued_events=616384
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=501208
```
### Failed to provide IP to istio-system/public-ingressgateway

As one option to provide IP to the istio-system/public-ingressgateway, metallb can be run. The following steps will demonstrate a standard configuration.

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  -R LOCATION_ON_FILESYSTEM_TO_CHECK_OUT_BIGBANG_CODE \
  -m
```

### WSL2 

This section will provide guidance for troubleshooting problems that may occur during your Big Bang installation specifically involving WSL2.

#### NeuVector "Failed to Get Container"

In you receive a similar error to the above "Failed to get container" with NeuVector it could be because of the cgroup configurations in WSL2. WSL2 often tries to run both cgroup and cgroup v2 in a unified manner which can confuse docker and affect deployments. To remedy this you need to create a .wslconfig file in the C:\Users\<UserName>\ directory.  In this file you need to add the following:

```shell
[wsl2]
kernelCommandLine = cgroup_no_v1=all
```

Once created you need to restart wsl2.

If this doesn't remedy the issue and the cgroup.controllers file is still located in the /sys/fs/cgroup/unified directory you may have to modify /etc/fstab and add the following:

```shell
cgroup2 /sys/fs/cgroup cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate 0 0
```

#### Container Fails to Start: "Not Enough Memory"

Wsl2 limits the amount of memory available to half of what your computer has. If you have 32g or less (16g or less available) this is often not enough to run all of the standard big bang services. If you have more available memory you can modify the initial limit by modifying (or creating) the C:\Users\<UserName>\.wslconfig file by adding:

```shell
[wsl2]
memory=24GB
```
