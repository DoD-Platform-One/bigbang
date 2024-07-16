# Quick Start

[[_TOC_]]

## Video Walkthrough

A 36-minute speed run video walkthrough of this quickstart can be found on the following two mirrored locations:
* [Google Drive - Video Mirror](https://drive.google.com/file/d/1m1pR0a-lrWr_Wed4EsI8-vimkYfb06GQ/view)
* [Repo1 - Video Mirror](https://repo1.dso.mil/platform-one/bullhorn-delivery-static-assets/-/blob/master/big_bang/bigbang_quickstart.mp4)

## Overview

This quick start guide explains in beginner-friendly terminology how to complete the following tasks in under an hour:

1. Turn a Virtual Machine (VM) into a k3d single-node Kubernetes cluster.
1. Deploy Big Bang on the cluster using a demonstration and local development-friendly workflow.

    > **NOTE:** This guide mainly focuses on the scenario of deploying Big Bang to a remote VM with enough resources to run Big Bang [(refer to step 1 for recommended resources)](#step-1-provision-a-virtual-machine). If your workstation has sufficient resources, or you are willing to disable packages to lower the resource requirements, then local development is possible. This quick start guide is valid for both remote and local deployment scenarios.

1. Customize the demonstration deployment of Big Bang.

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

* **Operating System Prerequisite:** Any Linux distribution that supports Docker should work.
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

## Step 1: Provision a Virtual Machine

The following requirements are recommended for Demonstration Purposes:

* 1 Virtual Machine with 32GB RAM, 8-Core CPU (t3a.2xlarge for AWS users), and 100GB of disk space should be sufficient.
* Ubuntu Server 20.04 LTS (Ubuntu comes up slightly faster than CentOS, in reality any Linux distribution with Docker installed should work).
* Most Cloud Service Provider provisioned VMs default to passwordless sudo being preconfigured, but if you're doing local development or a bare metal deployment then it's recommended that you configure passwordless sudo.
  * Steps for configuring passwordless sudo: [(source)](https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions)
  1. `sudo visudo`
  1. Change:

     ```plaintext
     # Allow members of group sudo to execute any command
     %sudo   ALL=(ALL:ALL) ALL
     ```

     To:

     ```plaintext
     # Allow members of group sudo to execute any command, no password
     %sudo   ALL=(ALL:ALL) NOPASSWD:ALL
     ```

* Network connectivity to Virtual Machine (provisioning with a public IP and a security group locked down to your IP should work. Otherwise a Bare Metal server or even a Vagrant Box Virtual Machine configured for remote ssh works fine.)

> **NOTE**: If your workstation has Docker, sufficient compute, and has ports 80, 443, and 6443 free, you can use your workstation in place of a remote virtual machine and do local development.

## Step 2: SSH to Remote VM

* ssh and passwordless sudo should be configured on the remote machine.
* You can skip this step if you are doing local development.

1. Set up SSH.

    ```shell
    # [admin@Unix_Laptop:~]
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    temp="""##########################
    Host k3d
      Hostname x.x.x.x  #IP Address of k3d node
      IdentityFile ~/.ssh/bb-onboarding-attendees.ssh.privatekey   #ssh key authorized to access k3d node
      User ubuntu
      StrictHostKeyChecking no   #Useful for vagrant where you'd reuse IP from repeated tear downs
    #########################"""
    echo "$temp" | tee -a ~/.ssh/config  #tee -a, appends to preexisting config file
    ```

1. SSH to instance.

      ```shell
      # [admin@Laptop:~]
      ssh k3d

      # [ubuntu@Ubuntu_VM:~]
      ```

## Step 3: Install Prerequisite Software

**NOTE:** This guide follows the DevOps best practice of left-shifting feedback on mistakes and surfacing errors as early in the process as possible. This is done by leveraging tests and verification commands.

1. Install Git.

    ```shell
    sudo apt install git -y
    ```

1. Install Docker and add $USER to Docker group.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    sudo apt update -y && sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update -y && sudo apt install docker-ce docker-ce-cli containerd.io -y && sudo usermod --append --groups docker $USER


    # Alternative command (less safe due to curl | bash, but more generic):
    # curl -fsSL https://get.docker.com | bash && sudo usermod --append --groups docker $USER
    ```

1. Log out and login to allow the `usermod` change to take effect.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    exit
    ```

    ```shell
    # [admin@Laptop:~]
    ssh k3d
    ```

1. Verify Docker Installation.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    docker run hello-world
    ```

    ```console
    Hello from Docker!
    ```

1. Install k3d.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    # The following downloads the 64 bit linux version of k3d v5.5.1, checks it
    # against a copy of the sha256 checksum, if they match k3d gets installed
    wget -q -O - https://github.com/k3d-io/k3d/releases/download/v5.5.1/k3d-linux-amd64 > k3d

    echo 4849027dc5e835bcce49070af3f4eeeaada81d96bce49a8b89904832a0c3c2c0 k3d | sha256sum -c | grep OK
    # 4849027dc5e835bcce49070af3f4eeeaada81d96bce49a8b89904832a0c3c2c0 came from running the following against a trusted internet connection.
    # wget -q -O - https://github.com/k3d-io/k3d/releases/download/v5.5.1/k3d-linux-amd64 | sha256sum | cut -d ' ' -f 1

    if [ $? == 0 ]; then chmod +x k3d && sudo mv k3d /usr/local/bin/k3d; fi


    # Alternative command (less safe due to curl | bash, but more generic):
    # wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.5.1 bash
    ```

1. Verify k3d installation.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    k3d --version
    ```

    ```console
    k3d version v5.5.1
    k3s version v1.26.4-k3s1 (default)
    ```

1. Install kubectl.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    # The following downloads the 64 bit linux version of kubectl v1.23.5, checks it
    # against a copy of the sha256 checksum, if they match kubectl gets installed
    wget -q -O - https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl > kubectl

    echo 715da05c56aa4f8df09cb1f9d96a2aa2c33a1232f6fd195e3ffce6e98a50a879 kubectl | sha256sum -c | grep OK
    # 715da05c56aa4f8df09cb1f9d96a2aa2c33a1232f6fd195e3ffce6e98a50a879 came from
    # wget -q -O - https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl.sha256

    if [ $? == 0 ]; then chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl; fi

    # Create a symbolic link from k to kubectl
    sudo ln -s /usr/local/bin/kubectl /usr/local/bin/k
    ```

1. Verify kubectl installation.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    kubectl version --client
    ```

    ```console
    Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.5", GitCommit:"c285e781331a3785a7f436042c65c5641ce8a9e9", GitTreeState:"clean", BuildDate:"2022-03-16T15:58:47Z", GoVersion:"go1.17.8", Compiler:"gc", Platform:"linux/amd64"}
    ```

1. Install Kustomize.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    # The following downloads the 64 bit linux version of kustomize v4.5.4, checks it
    # against a copy of the sha256 checksum, if they match kustomize gets installed
    wget -q -O - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.4/kustomize_v4.5.4_linux_amd64.tar.gz > kustomize.tar.gz

    echo 1159c5c17c964257123b10e7d8864e9fe7f9a580d4124a388e746e4003added3 kustomize.tar.gz | sha256sum -c | grep OK
    # 1159c5c17c964257123b10e7d8864e9fe7f9a580d4124a388e746e4003added3
    # came from https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.4/checksums.txt

    if [ $? == 0 ]; then tar -xvf kustomize.tar.gz && chmod +x kustomize && sudo mv kustomize /usr/local/bin/kustomize && rm kustomize.tar.gz ; fi  


    # Alternative commands (less safe due to curl | bash, but more generic):
    # curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    # chmod +x kustomize
    # sudo mv kustomize /usr/bin/kustomize
    ```

1. Verify Kustomize installation.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    kustomize version
    ```

    ```console
    {Version:kustomize/v4.5.4 GitCommit:cf3a452ddd6f83945d39d582243b8592ec627ae3 BuildDate:2022-03-28T23:12:45Z GoOs:linux GoArch:amd64}
    ```

1. Install Helm.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    # The following downloads the 64 bit linux version of helm v3.8.1, checks it
    # against a copy of the sha256 checksum, if they match helm gets installed
    wget -q -O - https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz > helm.tar.gz

    echo bbb6e7c6201458b235f335280f35493950dcd856825ddcfd1d3b40ae757d5c7d helm.tar.gz | sha256sum -c | grep OK
    # bbb6e7c6201458b235f335280f35493950dcd856825ddcfd1d3b40ae757d5c7d
    # came from https://github.com/helm/helm/releases/tag/v3.13.3

    if [ $? == 0 ]; then tar -xvf helm.tar.gz && chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 && rm helm.tar.gz ; fi  


    # Alternative command (less safe due to curl | bash, but more generic):
    # curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    ```

1. Verify Helm installation.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    helm version
    ```

    ```console
    version.BuildInfo{Version:"v3.13.3", GitCommit:"c8b948945e52abba22ff885446a1486cb5fd3474", GitTreeState:"clean", GoVersion:"go1.20.11"}
    ```

## Step 4: Configure Host Operating System Prerequisites

* Run Operating System Pre-configuration

  ```shell
  # [ubuntu@Ubuntu_VM:~]
  # Needed for ECK to run correctly without OOM errors
  echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.d/vm-max_map_count.conf
  # Alternatively can use (not persistent after restart):
  # sudo sysctl -w vm.max_map_count=524288


  # Needed by Sonarqube
  echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.d/fs-file-max.conf
  # Alternatively can use (not persistent after restart):  
  # sudo sysctl -w fs.file-max=131072

  # Also Needed by Sonarqube
  ulimit -n 131072
  ulimit -u 8192

  # Load updated configuration
  sudo sysctl --load --system

  # Preload kernel modules, required by istio-init running on SELinux enforcing instances
  sudo modprobe xt_REDIRECT
  sudo modprobe xt_owner
  sudo modprobe xt_statistic

  # Persist kernel modules settings after reboots
  printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules

  # Kubernetes requires swap disabled
  # Turn off all swap devices and files (won't last reboot)
  sudo swapoff -a

  # For swap to stay off, you can remove any references found via
  # cat /proc/swaps
  # cat /etc/fstab
  ```

## Step 5:  Create a k3d Cluster

After reading the notes on the purpose of k3d's command flags, you will be able to copy and paste the command to create a k3d cluster.

### Explanation of k3d Command Flags, Relevant to the Quick Start

* `SERVER_IP="10.10.16.11"` and `--k3s-arg "--tls-san=$SERVER_IP@server:0"`:  
  These associate an extra IP to the Kubernetes API server's generated HTTPS certificate.  

  **Explanation of the effect:**

   1. If you are running k3d from a local host or you plan to run 100% of kubectl commands while ssh'd into the k3d server, then you can omit these flags or paste unmodified incorrect values with no ill effect.

   1. If you plan to run k3d on a remote server, but run kubectl, helm, and kustomize commands from a workstation, which would be needed if you wanted to do something like kubectl port-forward then you would need to specify the remote server's public or private IP address here. After pasting the ~/.kube/config file from the k3d server to your workstation, you will need to edit the IP inside of the file from 0.0.0.0 to the value you used for SERVER_IP.

  **Tips for looking up the value to plug into SERVER_IP:**

  * Method 1: If your k3d server is a remote box, then run the following command from your workstation.  
  `cat ~/.ssh/config | grep k3d -A 6`
  * Method 2: If the remote server was provisioned with a Public IP, then run the following command from the server hosting k3d.  
  `curl ifconfig.me --ipv4`
  * Method 3: If the server hosting k3d only has a Private IP, then run the following command from the server hosting k3d  
  `ip address`  
  (You will see more than one address, use the one in the same subnet as your workstation)  

* `--volume /etc/machine-id:/etc/machine-id`:  
This is required for fluentbit log shipper to work.

* `IMAGE_CACHE=${HOME}/.k3d-container-image-cache`, `cd ~`, `mkdir -p ${IMAGE_CACHE}`, and `--volume ${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content`:  
These make it so that if you fully deploy Big Bang and then want to reset the cluster to a fresh state to retest some deployment logic. Then after running `k3d cluster delete k3s-default` and redeploying, subsequent deployments will be faster because all container images used will have been prefetched.

* `--servers 1 --agents 3`:  
These flags are not used and shouldn't be added. This is because the image caching logic works more reliably on a one node Dockerized cluster, vs a four node Dockerized cluster. If you need to add these flags to simulate multi nodes to test pod and node affinity rules, then you should remove the image cache flags, or you may experience weird image pull errors.

* `--port 80:80@loadbalancer` and `--port 443:443@loadbalancer`:  
These map the virtual machine's port 80 and 443 to port 80 and 443 of a Dockerized LB that will point to the NodePorts of the Dockerized k3s node.

* `--k3s-arg "--disable=traefik@server:0"`:  
This flag prevents the traefik ingress controller from being deployed. Without this flag traefik would provision a service of type LoadBalancer, and claim k3d's only LoadBalancer that works with ports 80 and 443. Disabling this makes it so the Istio Ingress Gateway will be able to claim the service of type LoadBalancer.

### k3d Cluster Creation Commands

```shell
# [ubuntu@Ubuntu_VM:~]
SERVER_IP="10.10.16.11" #(Change this value, if you need remote kubectl access)

# Create image cache directory
IMAGE_CACHE=${HOME}/.k3d-container-image-cache

mkdir -p ${IMAGE_CACHE}

k3d cluster create \
  --k3s-arg "--tls-san=$SERVER_IP@server:0" \
  --volume /etc/machine-id:/etc/machine-id \
  --volume ${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
  --k3s-arg "--disable=traefik@server:0" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --api-port 6443
```

### k3d Cluster Verification Command

```shell
# [ubuntu@Ubuntu_VM:~]
kubectl config use-context k3d-k3s-default
kubectl get node
```

```console
Switched to context "k3d-k3s-default".
NAME                       STATUS   ROLES                  AGE   VERSION
k3d-k3s-default-server-0   Ready    control-plane,master   11m   v1.22.7+k3s1
```

## Step 6: Verify Your IronBank Image Pull Credentials

1. Here we continue to follow the DevOps best practice of enabling early left-shifted feedback whenever possible; Before adding credentials to a configuration file and not finding out there is an issue until after we see an ImagePullBackOff error during deployment, we will do a quick left-shifted verification of the credentials.

1. Look up your IronBank image pull credentials.

    1. In a web browser go to [https://registry1.dso.mil](https://registry1.dso.mil).
    1. Login via OIDC provider.
    1. In the top right of the page, click your name, and then User Profile.
    1. Your image pull username is labeled "Username."
    1. Your image pull password is labeled "CLI secret."

    > **NOTE:** The image pull credentials are tied to the life cycle of an OIDC token which expires after ~3 days, so if 3 days have passed since your last login to IronBank, the credentials will stop working until you re-login to the [https://registry1.dso.mil](https://registry1.dso.mil) GUI.

1. Verify your credentials work.

    ```shell
    # [ubuntu@Ubuntu_VM:~]
    # Turn off bash history
    set +o history

    export REGISTRY1_USERNAME=<REPLACE_ME>
    export REGISTRY1_PASSWORD=<REPLACE_ME>
    echo $REGISTRY1_PASSWORD | docker login registry1.dso.mil --username $REGISTRY1_USERNAME --password-stdin

    # Turn on bash history
    set -o history
    ```

## Step 7: Clone Your Desired Version of the Big Bang Umbrella Helm Chart

```shell
# [ubuntu@Ubuntu_VM:~]
cd ~
git clone https://repo1.dso.mil/big-bang/bigbang.git

# Checkout version latest stable version of Big Bang
cd ~/bigbang
git checkout tags/$(grep 'tag:' base/gitrepository.yaml | awk '{print $2}')
git status
cd ~

# Note you can do the following to checkout a specific version of bigbang
# cd ~/bigbang
# git checkout tags/1.30.1
```

```console
HEAD detached at (latest version)
```

> **NOTE:** HEAD is git speak for current context within a tree of commits.

## Step 8: Install Flux

The `echo $REGISTRY1_USERNAME` is there to verify that the value of your environmental variable is still populated. If you switch terminals or re-login, you may need to reestablish these variables.

  ```shell
  # [ubuntu@Ubuntu_VM:~]
  echo $REGISTRY1_USERNAME
  cd ~/bigbang
  $HOME/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_PASSWORD
  # NOTE: After running this command the terminal may appear to be stuck on
  # "networkpolicy.networking.k8s.io/allow-webhooks created"
  # It's not stuck, the end of the .sh script has a kubectl wait command, give it 5 min
  # Also if you have slow internet/hardware you might see a false error message
  # error: timed out waiting for the condition on deployments/helm-controller

  # As long as the following command shows STATUS Running you're good to move on
  kubectl get pods --namespace=flux-system
  ```

  ```console
  NAME                                      READY   STATUS    RESTARTS   AGE
  helm-controller-746d586c6-ln7dl           1/1     Running   0          3m8s
  notification-controller-f6658d796-fdzjx   1/1     Running   0          3m8s
  kustomize-controller-5887bb8dd7-jzp7m     1/1     Running   0          3m8s
  source-controller-7c4564d74c-7ffrf        1/1     Running   0          3m8s  
  ```

## Step 9: Create Helm Values .yaml Files To Act as Input Variables for the Big Bang Helm Chart

> Note for those new to linux: The following are multi line copy pasteable commands to quickly generate config files from the CLI, make sure you copy from cat to EOF, if you get stuck in the terminal use ctrl + c

```shell
# [ubuntu@Ubuntu_VM:~]
cat << EOF > ~/ib_creds.yaml
registryCredentials:
  registry: registry1.dso.mil
  username: "$REGISTRY1_USERNAME"
  password: "$REGISTRY1_PASSWORD"
EOF


cat << EOF > ~/demo_values.yaml
elasticsearchKibana:
  values:
    kibana:
      count: 1
      resources:
        requests:
          cpu: 400m
          memory: 1Gi
        limits:
          cpu: null  # nonexistent cpu limit results in faster spin up
          memory: null
    elasticsearch:
      master:
        count: 1
        resources:
          requests:
            cpu: 400m
            memory: 2Gi
          limits:
            cpu: null
            memory: null
      data:
        count: 1
        resources:
          requests:
            cpu: 400m
            memory: 2Gi
          limits:
            cpu: null
            memory: null

clusterAuditor:
  values:
    resources:
      requests:
        cpu: 400m
        memory: 2Gi
      limits:
        cpu: null
        memory: null

gatekeeper:
  enabled: false
  values:
    replicas: 1
    controllerManager:
      resources:
        requests:
          cpu: 100m
          memory: 512Mi
        limits:
          cpu: null
          memory: null
    audit:
      resources:
        requests:
          cpu: 400m
          memory: 768Mi
        limits:
          cpu: null
          memory: null
    violations:
      allowedDockerRegistries:
        enforcementAction: dryrun

istio:
  values:
    values: # possible values found here https://istio.io/v1.5/docs/reference/config/installation-options (ignore 1.5, latest docs point here)
      global: # global istio operator values
        proxy: # mutating webhook injected istio sidecar proxy's values
          resources:
            requests:
              cpu: 0m # null get ignored if used here
              memory: 0Mi
            limits:
              cpu: 0m
              memory: 0Mi

twistlock:
  enabled: false # twistlock requires a license to work, so we're disabling it

# to set all Kyverno policies to audit only
kyvernoPolicies:
  enabled: true
  values:
    validationFailureAction: "audit"

# under Neuvector section
neuvector:
  enabled: true
  values:
    k3s:
      enabled: true
EOF
```

## Step 10: Install Big Bang Using the Local Development Workflow

```shell
# [ubuntu@Ubuntu_VM:~]
helm upgrade --install bigbang $HOME/bigbang/chart \
  --values https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --values $HOME/ib_creds.yaml \
  --values $HOME/demo_values.yaml \
  --namespace=bigbang --create-namespace
```

Explanation of flags used in the imperative helm install command:

`upgrade --install`:  
This makes the command more idempotent by allowing the exact same command to work for both the initial installation and upgrade use cases.

`bigbang $HOME/bigbang/chart`:  
bigbang is the name of the helm release that you'd see if you run `helm list -n=bigbang`. `$HOME/bigbang/chart` is a reference to the helm chart being installed.

`--values https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml`:  
References demonstration HTTPS certificates embedded in the public repository. The *.bigbang.dev wildcard certificate is signed by Let's Encrypt, a free public internet Certificate Authority. Note the URL path to the copy of the cert on master branch is used instead of `$HOME/bigbang/chart/ingress-certs.yaml`, because the Let's Encrypt certs expire after 3 months, and if you deploy a tagged release of BigBang, like 1.15.0, the version of the cert stored in the tagged git commit/release of Big Bang could be expired. Referencing the master branches copy via URL ensures you receive the latest version of the cert, which won't be expired.

`--namespace=bigbang --create-namespace`:  
Means it will install the bigbang helm chart in the bigbang namespace and create the namespace if it doesn't exist.

## Step 11: Verify Big Bang Has Had Enough Time To Finish Installing

* If you try to run the command in Step 11 too soon, you'll see an ignorable temporary error message.

  ```shell
  # [ubuntu@Ubuntu_VM:~]
  kubectl get virtualservices --all-namespaces

  # Note after running the above command, you may see an ignorable temporary error message
  # The error message may be different based on your timing, but could look like this:
  #   error: the server doesn't have a resource type "virtualservices"
  #   or
  #   No resources found

  # The above errors could be seen if you run the command too early
  # Give Big Bang some time to finish installing, then run the following command to check it's status

  kubectl get po -A
  ```

* If after running `kubectl get po -A` (which is the shorthand of `kubectl get pods --all-namespaces`) you see something like the following, then you need to wait longer.

  ```console
  NAMESPACE           NAME                                                READY   STATUS          RESTARTS   AGE
  kube-system         metrics-server-86cbb8457f-dqsl5                     1/1     Running             0      39m
  kube-system         coredns-7448499f4d-ct895                            1/1     Running             0      39m
  flux-system         notification-controller-65dffcb7-qpgj5              1/1     Running             0      32m
  flux-system         kustomize-controller-d689c6688-6dd5n                1/1     Running             0      32m
  flux-system         source-controller-5fdb69cc66-s9pvw                  1/1     Running             0      32m
  kube-system         local-path-provisioner-5ff76fc89d-gnvp4             1/1     Running             1      39m
  flux-system         helm-controller-6c67b58f78-6dzqw                    1/1     Running             0      32m
  gatekeeper-system   gatekeeper-controller-manager-5cf7696bcf-xclc4      0/1     Running             0      4m6s
  gatekeeper-system   gatekeeper-audit-79695c56b8-qgfbl                   0/1     Running             0      4m6s
  istio-operator      istio-operator-5f6cfb6d5b-hx7bs                     1/1     Running             0      4m8s
  eck-operator        elastic-operator-0                                  1/1     Running             1      4m10s
  istio-system        istiod-65798dff85-9rx4z                             1/1     Running             0      87s
  istio-system        public-ingressgateway-6cc4dbcd65-fp9hv              0/1     ContainerCreating   0      46s
  logging             logging-fluent-bit-dbkxx                            0/2     Init:0/1            0      44s
  monitoring          monitoring-monitoring-kube-admission-create-q5j2x   0/1     ContainerCreating   0      42s
  logging             logging-ek-kb-564d7779d5-qjdxp                      0/2     Init:0/2            0      41s
  logging             logging-ek-es-data-0                                0/2     Init:0/2            0      44s
  istio-system        svclb-public-ingressgateway-ggkvx                   5/5     Running             0      39s
  logging             logging-ek-es-master-0                              0/2     Init:0/2            0      37s
  ```

* Wait up to 10 minutes then re-run `kubectl get po -A`, until all pods show STATUS Running.

* `helm list -n=bigbang` should also show STATUS deployed

  ```console
  NAME                           	NAMESPACE        	REVISION	UPDATED                                	STATUS  	CHART                            	APP VERSION
  bigbang                        	bigbang          	1       	2022-03-31 12:07:49.239343968 +0000 UTC	deployed	bigbang-1.30.1
  cluster-auditor-cluster-auditor	cluster-auditor  	1       	2022-03-31 12:14:23.004377605 +0000 UTC	deployed	cluster-auditor-1.4.0-bb.0       	0.0.4
  eck-operator-eck-operator      	eck-operator     	1       	2022-03-31 12:09:52.921098159 +0000 UTC	deployed	eck-operator-2.0.0-bb.0          	2.0.0
  gatekeeper-system-gatekeeper   	gatekeeper-system	1       	2022-03-31 12:07:53.52890717 +0000 UTC 	deployed	gatekeeper-3.7.1-bb.0            	v3.7.1
  istio-operator-istio-operator  	istio-operator   	1       	2022-03-31 12:07:55.111321595 +0000 UTC	deployed	istio-operator-1.13.2-bb.1       	1.13.2
  istio-system-istio             	istio-system     	1       	2022-03-31 12:08:23.439981427 +0000 UTC	deployed	istio-1.13.2-bb.0                	1.13.2
  jaeger-jaeger                  	jaeger           	1       	2022-03-31 12:12:58.068313509 +0000 UTC	deployed	jaeger-operator-2.29.0-bb.0      	1.32.0
  kiali-kiali                    	kiali            	1       	2022-03-31 12:12:57.011215896 +0000 UTC	deployed	kiali-operator-1.47.0-bb.1       	1.47.0
  logging-ek                     	logging          	1       	2022-03-31 12:10:52.785810021 +0000 UTC	deployed	logging-0.7.0-bb.0               	7.17.1
  logging-fluent-bit             	logging          	1       	2022-03-31 12:12:53.27612266 +0000 UTC 	deployed	fluent-bit-0.19.20-bb.1          	1.8.13
  monitoring-monitoring          	monitoring       	1       	2022-03-31 12:10:02.31254196 +0000 UTC 	deployed	kube-prometheus-stack-33.2.0-bb.0	0.54.1
  ```

## Step 12: Edit Your Workstation’s Hosts File To Access the Web Pages Hosted on the Big Bang Cluster

Run the following command, which is the short hand equivalent of `kubectl get virtualservices --all-namespaces` to see a list of websites you'll need to add to your hosts file.

```shell
kubectl get vs -A
```

```console
NAMESPACE    NAME                                      GATEWAYS                  HOSTS                          AGE
logging      kibana                                    ["istio-system/public"]   ["kibana.bigbang.dev"]         10m
monitoring   monitoring-monitoring-kube-alertmanager   ["istio-system/public"]   ["alertmanager.bigbang.dev"]   10m
monitoring   monitoring-monitoring-kube-grafana        ["istio-system/public"]   ["grafana.bigbang.dev"]        10m
monitoring   monitoring-monitoring-kube-prometheus     ["istio-system/public"]   ["prometheus.bigbang.dev"]     10m
kiali        kiali                                     ["istio-system/public"]   ["kiali.bigbang.dev"]          8m21s
jaeger       jaeger                                    ["istio-system/public"]   ["tracing.bigbang.dev"]        7m46s
```

### Linux/Mac Users

```shell
# [admin@Laptop:~]
sudo vi /etc/hosts
```

### Windows Users

1. Right click Notepad -> Run as Administrator
1. Open C:\Windows\System32\drivers\etc\hosts

### Linux/Mac/Windows Users

Add the following entries to the Hosts file, where x.x.x.x = k3d virtual machine's IP.

> Hint: find and replace is your friend

```plaintext
x.x.x.x  kibana.bigbang.dev
x.x.x.x  alertmanager.bigbang.dev
x.x.x.x  grafana.bigbang.dev
x.x.x.x  prometheus.bigbang.dev
x.x.x.x  kiali.bigbang.dev
x.x.x.x  tracing.bigbang.dev
x.x.x.x  argocd.bigbang.dev
```

## Step 13: Visit a Webpage

In a browser, visit one of the sites listed using the `kubectl get vs -A` command.

Note, default credentials for Big Bang packages can be found [here](../using-bigbang/default-credentials.md).

## Step 14: Play

Here's an example of post deployment customization of Big Bang.  
After looking at <https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.yaml>  
It should make sense that the following is a valid edit.

```shell
# [ubuntu@Ubuntu_VM:~]

cat << EOF > ~/tinkering.yaml
addons:
  argocd:
    enabled: true
EOF

helm upgrade --install bigbang $HOME/bigbang/chart \
--values https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
--values $HOME/ib_creds.yaml \
--values $HOME/demo_values.yaml \
--values $HOME/tinkering.yaml \
--namespace=bigbang --create-namespace

# NOTE: There may be a ~1 minute delay for the change to apply

kubectl get vs -A
# Now ArgoCD should show up, if it doesn't wait a minute and rerun the command

kubectl get po -n=argocd
# Once these are all Running you can visit argocd's webpage
```

> Remember to un-edit your Hosts file when you are finished tinkering.

## Step 15: Implementing Mission Applications within your bigbang environment

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

helm upgrade --install bigbang $HOME/bigbang/chart \
--values https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
--values $HOME/ib_creds.yaml \
--values $HOME/demo_values.yaml \
--values $HOME/podinfo_wrapper.yaml \
--namespace=bigbang --create-namespace

# NOTE: There may be a ~1 minute delay for the change to apply

kubectl get vs -A
# Now missionapp should show up, if it doesn't wait a minute and rerun the command

kubectl get po -n=missionapp
# Once these are all Running you can visit missionapp's webpage
```

Wrappers also allow you to abstract out Monitoring, Secrets, Network Policies, and ConfigMaps. Additional Configuration information can be found [here](./extra-package-deployment.md)

## Troubleshooting
This section will provide guidance for troubleshooting problems that may occur during your Big Bang installation and instructions for additional configuration changes that may be required in restricted networks. 

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

As one option to provide IP to the istio-system/public-ingressgateway, metallb can be run. The following steps will demonstrate a standard configuration, however, some changes may need to be made for each individual system (e.g., specific /ets/hosts addresses).

#### Step 1: K3d Deploy

To facilitate metallb, servicelb needs to be disabled on the initial install.  Replace the above k3d deploy command with the following:
```shell
k3d cluster create \
  --k3s-arg "--tls-san=$SERVER_IP@server:0" \
  --volume /etc/machine-id:/etc/machine-id \
  --volume ${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
  --k3s-arg "--disable=traefik@server:0" \
  --k3s-arg "--disable=servicelb@server:0" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --api-port 6443
```

#### Step 2: Deploy MetalLB

After following the above instructions to deploy flux, deploy the metallb controller and speaker.
```shell
kubectl create -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```
Wait for the pods to be running:
```shell
kubectl get po -n metallb-system
```

```console
NAME                          READY   STATUS    RESTARTS   AGE
controller-5684477f66-s99jg   1/1     Running   0          30s
speaker-jrddv                 1/1     Running   0          30s
```

#### Step 3: Configure MetalLB

**NOTE:** This step will not work if either the controller or speaker are not in a running condition.

The following configuration addresses will need to be filled with the values that match your configuration. These can typically be found by looking at your docker subnet using the 'docker network ls' command.  If there is no subnet currently configured you can use the following as an example to set up your subnet. 'docker network create --opt com.docker.network.bridge.name=$NETWORK_NAME $NETWORK_NAME --driver=bridge -o "com.docker.network.driver.mtu"="1450" --subnet=172.x.x.x/16 --gateway 172.x.x.x'. Be sure to replace the network name, subnet and gateway values as needed.

```shell
export SUBNET_RANGE=172.x.x.x-172.x.x.x
cat << EOF > ~/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - $SUBNET_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement1
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF

kubectl create -f $HOME/metallb-config.yaml
```
#### Step 4: Configure /etc/hosts

Lastly, configure /etc/hosts/ with the new IP Addresses (**NOTE:** you can add your own as needed for services). You will need to fill in the values used for the subnet.

```shell
  export PASSTHROUGH_GATEWAY_IP=172.x.x.x
  export PUBLIC_GATEWAY_IP=172.x.x.x
  sudo sed -i '/bigbang.dev/d' /etc/hosts
  sudo bash -c "echo '## begin bigbang.dev section (METAL_LB)' >> /etc/hosts"
  sudo bash -c "echo $PASSTHROUGH_GATEWAY_IP keycloak.bigbang.dev vault.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo $PUBLIC_GATEWAY_IP anchore-api.bigbang.dev anchore.bigbang.dev argocd.bigbang.dev gitlab.bigbang.dev registry.bigbang.dev tracing.bigbang.dev kiali.bigbang.dev kibana.bigbang.dev chat.bigbang.dev minio.bigbang.dev minio-api.bigbang.dev alertmanager.bigbang.dev grafana.bigbang.dev prometheus.bigbang.dev nexus.bigbang.dev sonarqube.bigbang.dev tempo.bigbang.dev twistlock.bigbang.dev >> /etc/hosts"
  sudo bash -c "echo '## end bigbang.dev section' >> /etc/hosts"
  # run kubectl to add keycloak and vault's hostname/IP to the configmap for coredns, restart coredns
  kubectl get configmap -n kube-system coredns -o yaml | sed '/^    $PASSTHROUGH_GATEWAY_IP host.k3d.internal$/a\ \ \ \ $PASSTHROUGH_GATEWAY_IP keycloak.bigbang.dev vault.bigbang.dev' | kubectl apply -f -
  kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

From this point continue with the helm upgrade command above.

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
