# Big Bang Auth Service and Keycloak SSO Quick Start Demo

[[_TOC_]]

## Video Walkthrough
A 54min speed run with explanations video walkthrough of this sso quickstart guide can be found on the following 2 mirrored locations:
* [Google Drive - Video Mirror](https://drive.google.com/file/d/1xzRKhFQy4WXW97YWUFpixclLGAKfgA6Z/preview)
* [Repo1 - Video Mirror](https://repo1.dso.mil/platform-one/bullhorn-delivery-static-assets/-/blob/master/big_bang/bigbang_sso_quickstart.mp4)

## Blue Team Knowledge Drop

Imagine <https://authdemo.bigbang.dev> represents a mock-up of a custom-built mission application that doesn't have SSO, Authentication, or Authorization built-in. Auth Service can add those to it which creates layers of defense/defense in depth in the form only allowing authenticated users the ability to even see the page, enforcing MFA of authenticated users, and requiring that authenticated users are authorized to access that service (they must be in the correct group of their Identity Provider, and this means you can safely enable self-registration of users without hurting security. Auth Service's Authentication Proxy has an additional benefit in regards to defense in depth. You can add it in front of most frontend applications to create an additional layer of defense. Example: Grafana, Kibana, ArgoCD, and others have baked in support for OIDC/SSO and AuthN/AuthZ functionality, so you may think what benefit could be had from adding an authentication proxy in front of them (it seems redundant at first glance). Let's say that a frontend service was reachable from the public internet and it had some zero-day vulnerability that allowed authentication bypass or unauthenticated remote code execution to occur via a network-level exploit / uniquely crafted packet. Well someone on the internet wouldn't even be able to exploit these hypothetical zero-day vulnerabilities since it'd be behind an AuthN/AuthZ proxy layer of defense which would prevent them from even touching the frontend. Bonus: Istio, AuthService, and Keycloak are all Free Open Source Software (FOSS) solutions and they work in internet disconnect environments, we'll even demonstrate it working using only Kubernetes DNS and workstation hostfile edits / without needing to configure LAN/Internet DNS.

## Overview

This SSO Quick Start Guide explains how to set up an SSO demo environment, from scratch within two hours, that will allow you to demo Auth Service's functionality. You'll gain hands-on configuration experience with Auth Service, Keycloak, and a Mock Mission Application.

**Steps:**

1. This document assumes you have already gone through and are familiar with the generic quick start guide.
1. Given 2 VMs (each with 8 CPU cores / 32 GB ram) that are each set up for ssh, turn the 2 VMs into 2 single node k3d clusters.
Why 2 VMs? 2 reasons:
1. It works around k3d only supporting 1 LB, but Keycloak needs its LB with TCP_PASSTHROUGH.
1. This mimics the way the Big Bang team recommends Keycloak be deployed in production, giving it its dedicated cluster (Note: from a technical standpoint nothing is stopping it from being hosted on the same cluster).
1. Use Big Bang demo workflow to turn 1 k3d cluster into a Keycloak Cluster.
1. Use Big Bang demo workflow to turn 1 k3d cluster into a Workload Cluster.
1. In the Keycloak Cluster:
   * Deploy Keycloak
   * Create a Human User and Service Account for the authdemo service.
1. In the Workload Cluster:
   * Deploy a mock mission application
   * Protect the mock mission application, by deploying and configuring auth service to interface with Keycloak and require users to log in to Keycloak and be in the correct authorization group before being able to access the mock mission application.

### Differences between this and the generic quick start

* Topics explained in previous quick start guides won't have notes or they will be less detailed.
* The previous quick start supported deploying k3d to either localhost or remote VM, this quick start only supports deployment to remote VMs.
* The previous quick start supported multiple Linux distributions, this one requires Ubuntu 20.04, and it must be configured for passwordless sudo (this guide has more automation of prerequisites, so we needed a standard to automate against.)
* The automation also assumes Admin's Laptop has a Unix Shell. (Mac, Linux, or Windows Subsystem for Linux)
* This quick start assumes you have kubectl installed on your Administrator Workstation

### Additional Auth Service and Keycloak documentation can be found in these locations

* [Authservice](https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice)
* [Authservice Architecture](../../../charter/packages/authservice/Architecture.md)
* [Keycloak](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak)
* [Keycloak Architecture](../../../charter/packages/keycloak/Architecture.md)

## Step 1: Provision 2 Virtual Machines

* 2 Virtual Machines each with 32GB RAM, 8-Core CPU (t3a.2xlarge for AWS users), and 100GB of disk space should be sufficient.

## Step 2: Setup SSH to both VMs

1. Setup SSH to both VMs

    ```shell
    # [admin@Unix_Laptop:~]
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    temp="""##########################
    Host keycloak-cluster
      Hostname x.x.x.x  #IP Address of VM1 (future k3d cluster)
      IdentityFile ~/.ssh/bb-onboarding-attendees.ssh.privatekey
      User ubuntu
      StrictHostKeyChecking no
    Host workload-cluster
      Hostname x.x.x.x  #IP Address of VM2 (future k3d cluster)
      IdentityFile ~/.ssh/bb-onboarding-attendees.ssh.privatekey
      User ubuntu
      StrictHostKeyChecking no
    #########################"""
    echo "$temp" | tee -a ~/.ssh/config  #tee -a, appends to preexisting config file
    ```

1. Verify SSH works for both VMs

    ```shell
    # [admin@Laptop:~]
    ssh keycloak-cluster

    # [ubuntu@Ubuntu_VM:~]
    exit

    # [admin@Laptop:~]
    ssh workload-cluster

    # [ubuntu@Ubuntu_VM:~]
    exit

    # [admin@Laptop:~]
    ```

## Step 3: Prep work - Install dependencies and configure both VMs

1. Set some Variables and push them to each VM
   * We'll pass some environment variables into the VMs that will help with automation
   * We'll also update the PS1 var so we can tell the 2 machines apart when ssh'd into.
   * All of the commands in the following section are run from the Admin Laptop
   * Note: The REGISTRY1_USERNAME and REGISTRY1_PASSWORD in the code block below, can't be blindly copy pasted.

    ```shell
    # [admin@Laptop:~]
   
    # Commented out directly below, is how to use a pinned version of BigBang:
    # BIG_BANG_VERSION="1.30.1" 
    # (Note: 1.30.1 was the last version this guide was tested against)
    # 
    # The following will load the latest tagger version of BigBang into an environment variable
    BIG_BANG_VERSION=$(curl -s https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/base/gitrepository.yaml | grep 'tag:' | awk '{print $2}')
    echo "This script will install Big Bang version: $BIG_BANG_VERSION"
    REGISTRY1_USERNAME="REPLACE_ME"
    REGISTRY1_PASSWORD="REPLACE_ME"
    ```

   * Note: The following code block can be copy pasted into the terminal as is

    ```shell
    # [admin@Laptop:~]
    echo $REGISTRY1_PASSWORD | docker login https://registry1.dso.mil --username=$REGISTRY1_USERNAME --password-stdin | grep "Succeeded" ; echo $? | grep 0 && echo "This validation check shows your registry1 credentials are valid, please continue." || for i in {1..10}; do echo "Validation check shows error, fix your registry1 credentials before moving on."; done
    
    export KEYCLOAK_IP=$(cat ~/.ssh/config | grep keycloak-cluster -A 1 | grep Hostname | awk '{print $2}')
    echo "\n\n\n$KEYCLOAK_IP is the IP of the k3d node that will host Keycloak on Big Bang"
    
    export WORKLOAD_IP=$(cat ~/.ssh/config | grep workload-cluster -A 1 | grep Hostname | awk '{print $2}')
    echo "$WORKLOAD_IP is the IP of the k3d node that will host Workloads on Big Bang"
    echo "Please manually verify that the IPs of your keycloak and workload k3d VMs look correct before moving on."
    ```

   * Copy paste the following code block into your workstation's unix terminal.
     (This is using cat command to generate files. Specifically scripts templatized using environment variables.)

    ```shell
    # [admin@Laptop:~]
    mkdir -p ~/qs   
   
    cat << EOFkeycloak-k3d-prepwork-commandsEOF > ~/qs/keycloak-k3d-prepwork-commands.txt
    # Idempotent logic:
    sudo sed -i "/.*BIG_BANG_VERSION.*/d"      ~/.bashrc
    sudo sed -i "/.*REGISTRY1_USERNAME.*/d"    ~/.bashrc
    sudo sed -i "/.*REGISTRY1_PASSWORD.*/d"    ~/.bashrc
    lines_in_file=()
    lines_in_file+=( 'export PS1="\[\033[01;32m\]\u@keycloak-cluster\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' )
    lines_in_file+=( 'export CLUSTER_NAME="keycloak-cluster"' )
    lines_in_file+=( 'export BIG_BANG_VERSION="$BIG_BANG_VERSION"' )
    lines_in_file+=( 'export K3D_IP="$KEYCLOAK_IP"' )
    lines_in_file+=( 'export REGISTRY1_USERNAME="$REGISTRY1_USERNAME"' )
    lines_in_file+=( 'export REGISTRY1_PASSWORD="$REGISTRY1_PASSWORD"' )
    
    for line in "\${lines_in_file[@]}"; do
      grep -qF "\${line}" ~/.bashrc
      if [ \$? -ne 0 ]; then echo "\${line}" >> ~/.bashrc ; fi
    done
    EOFkeycloak-k3d-prepwork-commandsEOF
    
    
    cat << EOFworkload-k3d-prepwork-commandsEOF > ~/qs/workload-k3d-prepwork-commands.txt
    # Idempotent logic:
    sudo sed -i "/.*BIG_BANG_VERSION.*/d"      ~/.bashrc
    sudo sed -i "/.*REGISTRY1_USERNAME.*/d"    ~/.bashrc
    sudo sed -i "/.*REGISTRY1_PASSWORD.*/d"    ~/.bashrc
    lines_in_file=()
    lines_in_file+=( 'export PS1="\[\033[01;32m\]\u@workload-cluster\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' )
    lines_in_file+=( 'export CLUSTER_NAME="workload-cluster"' )
    lines_in_file+=( 'export BIG_BANG_VERSION="$BIG_BANG_VERSION"' )
    lines_in_file+=( 'export K3D_IP="$WORKLOAD_IP"' )
    lines_in_file+=( 'export REGISTRY1_USERNAME="$REGISTRY1_USERNAME"' )
    lines_in_file+=( 'export REGISTRY1_PASSWORD="$REGISTRY1_PASSWORD"' )
    
    for line in "\${lines_in_file[@]}"; do
      grep -qF "\${line}" ~/.bashrc
      if [ \$? -ne 0 ]; then echo "\${line}" >> ~/.bashrc ; fi
    done
    EOFworkload-k3d-prepwork-commandsEOF
    ```

   * Run the following against your Laptop / Workstation's Unix terminal.

    ```shell
    # [admin@Laptop:~]
    # We will do a sanity check to make sure the above commands correctly generated text files
    cat ~/qs/keycloak-k3d-prepwork-commands.txt
    cat ~/qs/workload-k3d-prepwork-commands.txt
    # Notice that the exported REGISTRY1_USERNAME var should have a value substituted in.

    # Run the above commands against the remote shell in parallel and wait for finish
    # [admin@Laptop:~]
    ssh keycloak-cluster < ~/qs/keycloak-k3d-prepwork-commands.txt &
    ssh workload-cluster < ~/qs/workload-k3d-prepwork-commands.txt &
    wait
    ```

    ```text
    Explanation: (We are basically doing the equivalent of Ansible, without 
    having to install Ansible and its dependencies.)
    ssh keycloak-cluster < ~/qs/keycloak-k3d-prepwork-commands.txt
    ^-- runs script against remote VM 
    & at the end of the command means to let it run in the background
    using it allows us to run the script against both machines in parallel.
    wait command waits for background processes to finish
    ```

1. Take a look at one of the VMs to understand what happened

    ```shell
    # [admin@Laptop:~]
    # First a command to confirm ~/.bashrc was updated as expected
    ssh keycloak-cluster 'tail ~/.bashrc' 
    
    # Then ssh in to see the differences
    ssh keycloak-cluster
    ```

1. Notice the prompt makes it obvious which VM you ssh'ed into.  

    ```shell
    # [ubuntu@keycloak-cluster:~$]
    echo "Notice the prompt has access to environment variables that are useful for automation"
    env | grep -i name
    env | grep IP
    exit
    
    # [admin@Laptop:~]
    ```

1. Configure host OS prerequisites and install prerequisite software on both VMs
   * Copy paste the following to generate an automation script

    ```shell
    # [admin@Laptop:~]
    # Note ? is escaped in some places in the form of \?, this prevents substitution
    # by the local machine, which allows the remote VM to do the substituting. 
    cat << EOFshared-k3d-prepwork-commandsEOF > ~/qs/shared-k3d-prepwork-commands.txt
    # Configure OS
    sudo sysctl -w vm.max_map_count=524288
    sudo sysctl -w fs.file-max=131072
    ulimit -n 131072
    ulimit -u 8192
    sudo sysctl --load
    sudo modprobe xt_REDIRECT
    sudo modprobe xt_owner
    sudo modprobe xt_statistic
    printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
    sudo swapoff -a
    
    # Install git
    sudo apt install git -y
    
    # Install docker (note we use escape some vars we want the remote linux to substitute)
    sudo apt update -y && sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y && sudo apt install docker-ce docker-ce-cli containerd.io -y && sudo usermod --append --groups docker \$USER
    
    # Install k3d
    wget -q -O - https://github.com/k3d-io/k3d/releases/download/v5.4.1/k3d-linux-amd64 > k3d
    echo 50f64747989dc1fcde5db5cb82f8ac132a174b607ca7dfdb13da2f0e509fda11 k3d | sha256sum -c | grep OK
    if [ \$? == 0 ]; then chmod +x k3d && sudo mv k3d /usr/local/bin/k3d ; fi
    
    # Install kubectl
    wget -q -O - https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl > kubectl
    echo 715da05c56aa4f8df09cb1f9d96a2aa2c33a1232f6fd195e3ffce6e98a50a879 kubectl | sha256sum -c | grep OK
    if [ \$? == 0 ]; then chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl; fi
    sudo ln -s /usr/local/bin/kubectl /usr/local/bin/k || true
    
    # Install kustomize
    wget -q -O - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.4/kustomize_v4.5.4_linux_amd64.tar.gz > kustomize.tar.gz
    echo 1159c5c17c964257123b10e7d8864e9fe7f9a580d4124a388e746e4003added3 kustomize.tar.gz | sha256sum -c | grep OK
    if [ \$? == 0 ]; then tar -xvf kustomize.tar.gz && chmod +x kustomize && sudo mv kustomize /usr/local/bin/kustomize && rm kustomize.tar.gz ; fi    
    
    # Install helm
    wget -q -O - https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz > helm.tar.gz
    echo d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd helm.tar.gz | sha256sum -c | grep OK
    if [ \$? == 0 ]; then tar -xvf helm.tar.gz && chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 && rm helm.tar.gz ; fi
    EOFshared-k3d-prepwork-commandsEOF
    ```

   * Copy paste the following to run the above prerequisite automation script against both VMs

    ```shell
    # [admin@Laptop:~]
    # Run the above prereq script against both VMs
    ssh keycloak-cluster < ~/qs/shared-k3d-prepwork-commands.txt &
    ssh workload-cluster < ~/qs/shared-k3d-prepwork-commands.txt &
    wait 
    ```

   * Copy paste the following to run validation checks against both VMs

    ```shell
    # [admin@Laptop:~]
    # Verify install was successful
    cat << EOFshared-k3d-prepwork-verification-commandsEOF > ~/qs/shared-k3d-prepwork-verification-commands.txt
    docker ps >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: docker installed" || echo "ERROR: issue with docker install"
    k3d version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: k3d installed" || echo "ERROR: issue with k3d install"
    kubectl version --client >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: kubectl installed" || echo "ERROR: issue with kubectl install"
    kustomize version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: kustomize installed" || echo "ERROR: issue with kustomize install"
    helm version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: helm installed" || echo "ERROR: issue with helm install" 
    EOFshared-k3d-prepwork-verification-commandsEOF
    
    ssh keycloak-cluster < ~/qs/shared-k3d-prepwork-verification-commands.txt 
    ssh workload-cluster < ~/qs/shared-k3d-prepwork-verification-commands.txt
    ```

## Step 4: Create k3d cluster on both VMs and make sure you have access to both

```text
Note: There's no need to copy paste commands from this text box,
      it's intended to explain some of the shell below.

If you were to copy paste the following into your laptop/workstation's terminal.
ssh keycloak-cluster 'env | grep K3D_IP'
You'd receive blank text, this means that env vars defined in the remote VM's ~/.bashrc 
are not populated when using non interactive shell copy paste automation method.

That's why the script that runs on the remote machine has lines like this one:
export K3D_IP=\$(cat ~/.bashrc  | grep K3D_IP | cut -d \" -f 2)
(It's a workaround that allows the env var values to be used in a non interactive shell)
```

* Create a k3d cluster on both VMs

```shell
# [admin@Laptop:~]
cat << EOFshared-k3d-install-commandsEOF > ~/qs/shared-k3d-install-commands.txt
export K3D_IP=\$(cat ~/.bashrc  | grep K3D_IP | cut -d \" -f 2)
export CLUSTER_NAME=\$(cat ~/.bashrc  | grep CLUSTER_NAME | cut -d \" -f 2)

IMAGE_CACHE=\${HOME}/.k3d-container-image-cache
mkdir -p \${IMAGE_CACHE}
k3d cluster create \$CLUSTER_NAME \
    --k3s-arg "--tls-san=\$K3D_IP@server:0" \
    --volume /etc/machine-id:/etc/machine-id \
    --volume \${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
    --k3s-arg "--disable=traefik@server:0" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
sed -i "s/0.0.0.0/\$K3D_IP/" ~/.kube/config
# Explanation:
# sed = stream editor 
# -i s/.../.../   (i = inline), (s = substitution, basically cli find and replace)
# / / / are delimiters the separate what to find and what to replace.
# \$K3D_IP, is a variable with $ escaped, so the var will be processed by the remote VM.
# This was done to allow kubectl access from a remote machine.
EOFshared-k3d-install-commandsEOF

ssh keycloak-cluster < ~/qs/shared-k3d-install-commands.txt &
ssh workload-cluster < ~/qs/shared-k3d-install-commands.txt &
wait
```

* Copy pasting these verification commands, will make sure you have access to both clusters.

```shell
# [admin@Laptop:~]
mkdir -p ~/.kube
scp keycloak-cluster:~/.kube/config ~/.kube/keycloak-cluster
scp workload-cluster:~/.kube/config ~/.kube/workload-cluster

export KUBECONFIG=$HOME/.kube/keycloak-cluster
kubectl get node
export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl get node
```

## Step 5: Clone Big Bang and Install Flux on both Clusters

* Note after copy pasting the following block of automation, it might look stuck on "networkpolicy.networking.k8s.io/allow-webhooks created", the install_flux.sh script has logic near the end that waits for a healthy deployment, so just wait about 4 minutes. After which `kubectl get po -n=flux-system` should show a healthy deployment and you should be able to interactively use your terminal again.

```shell
# [admin@Laptop:~]
cat << EOFshared-flux-install-commandsEOF > ~/qs/shared-flux-install-commands.txt
export REGISTRY1_USERNAME=\$(cat ~/.bashrc  | grep REGISTRY1_USERNAME | cut -d \" -f 2)
export REGISTRY1_PASSWORD=\$(cat ~/.bashrc  | grep REGISTRY1_PASSWORD | cut -d \" -f 2)
export BIG_BANG_VERSION=\$(cat ~/.bashrc  | grep BIG_BANG_VERSION | cut -d \" -f 2)

cd ~
git clone https://repo1.dso.mil/platform-one/big-bang/bigbang.git
cd ~/bigbang
git checkout tags/\$BIG_BANG_VERSION
\$HOME/bigbang/scripts/install_flux.sh -u \$REGISTRY1_USERNAME -p \$REGISTRY1_PASSWORD
EOFshared-flux-install-commandsEOF

ssh keycloak-cluster < ~/qs/shared-flux-install-commands.txt &
ssh workload-cluster < ~/qs/shared-flux-install-commands.txt &
wait
```

* Note: It's possible for the above flux install commands to give a false error message, along the lines of "error: timed out waiting for the condition on deployments/helm-controller", if the deployment takes longer than 5 minutes, the wait for healthy logic will time out. If you follow these steps using cloud service provider infrastructure, you're unlikely to see the error. If you follow these steps on a home network lab with slower download speed you might see the error message, its ignorable, and you can use the following copy pasteable command block to verify health of the flux pods.

```shell
# [admin@Laptop:~]
export KUBECONFIG=$HOME/.kube/keycloak-cluster
kubectl get po -n=flux-system
export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl get po -n=flux-system
```

## Step 6: Install Big Bang on Workload Cluster

```shell
# [admin@Laptop:~]
cat << EOFdeploy-workloadsEOF > ~/qs/deploy-workloads.txt
export REGISTRY1_USERNAME=\$(cat ~/.bashrc  | grep REGISTRY1_USERNAME | cut -d \" -f 2)
export REGISTRY1_PASSWORD=\$(cat ~/.bashrc  | grep REGISTRY1_PASSWORD | cut -d \" -f 2)

cat << EOF > ~/ib_creds.yaml
registryCredentials:
  registry: registry1.dso.mil
  username: "\$REGISTRY1_USERNAME"
  password: "\$REGISTRY1_PASSWORD"
EOF

cat << EOF > ~/demo_values.yaml
logging:
  values:
    kibana:
      count: 1
      resources:
        requests:
          cpu: 1m
          memory: 1Mi
        limits:
          cpu: null  # nonexistent cpu limit results in faster spin up
          memory: null
    elasticsearch:
      master:
        count: 1
        resources:
          requests:
            cpu: 1m
            memory: 1Mi
          limits:
            cpu: null
            memory: null
      data:
        count: 1
        resources:
          requests:
            cpu: 1m
            memory: 1Mi
          limits: 
            cpu: null
            memory: null

clusterAuditor:
  values:
    resources:
      requests:
        cpu: 1m
        memory: 1Mi
      limits:
        cpu: null
        memory: null

gatekeeper:
  enabled: true
  values:
    replicas: 1
    controllerManager:
      resources:
        requests:
          cpu: 1m
          memory: 1Mi
        limits:
          cpu: null
          memory: null
    audit:
      resources:
        requests:
          cpu: 1m
          memory: 1Mi
        limits:
          cpu: null
          memory: null
    violations:
      allowedCapabilities:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to not drop capabilities
          - istio-system/lb-port-.*
      allowedDockerRegistries:
        enforcementAction: dryrun
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to pull from public repos
          - istio-system/lb-port-.*
      allowedSecCompProfiles:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to have an undefined defined seccomp
          - istio-system/lb-port-.*
      allowedUsers:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to run as any user/group
          - istio-system/lb-port-.*
      containerRatio:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to have undefined limits/requests
          - istio-system/lb-port-.*
      hostNetworking:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to mount host ports
          - istio-system/lb-port-.*
      noBigContainers:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to have undefined limits/requests
          - istio-system/lb-port-.*
      noPrivilegedEscalation:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to have undefined security context
          - istio-system/lb-port-.*
      readOnlyRoot:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to mount filesystems read/write
          - istio-system/lb-port-.*
      requiredLabels:
        parameters:
          excludedResources:
          # Allows k3d load balancer pods to not have required labels
          - istio-system/svclb-.*
      requiredProbes:
        parameters:
          excludedResources:
          # Allows k3d load balancer containers to not have readiness/liveness probes
          - istio-system/lb-port-.*

istio:
  values:
    values:
      global:
        proxy:
          resources:
            requests:
              cpu: 0m
              memory: 0Mi
            limits:
              cpu: 0m
              memory: 0Mi

twistlock:
  enabled: false
EOF

helm upgrade --install bigbang \$HOME/bigbang/chart \
  --values https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --values \$HOME/ib_creds.yaml \
  --values \$HOME/demo_values.yaml \
  --namespace=bigbang --create-namespace
EOFdeploy-workloadsEOF

ssh workload-cluster < ~/qs/deploy-workloads.txt
```

* The following command can be used to check the status of the deployment. You can optionally re-run `kubectl get hr -A` multiple times until you see READY: True, but there's no need to wait for it to finish before moving on.

```shell
sleep 5
export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl get hr -A
```

## Step 7: Install Keycloak on Keycloak Cluster

```shell
# [admin@Laptop:~]
cat << EOFdeploy-keycloakEOF > ~/qs/deploy-keycloak.txt
export REGISTRY1_USERNAME=\$(cat ~/.bashrc  | grep REGISTRY1_USERNAME | cut -d \" -f 2)
export REGISTRY1_PASSWORD=\$(cat ~/.bashrc  | grep REGISTRY1_PASSWORD | cut -d \" -f 2)

cat << EOF > ~/ib_creds.yaml
registryCredentials:
  registry: registry1.dso.mil
  username: "\$REGISTRY1_USERNAME"
  password: "\$REGISTRY1_PASSWORD"
EOF

cat << EOF > ~/keycloak_qs_demo_values.yaml
eckoperator:
  enabled: false
logging:
  enabled: false
fluentbit:
  enabled: false
monitoring:
  enabled: false
clusterAuditor:
  enabled: false
gatekeeper:
  enabled: false
kiali:
  enabled: false
jaeger:
  enabled: false
istio:
  ingressGateways:
    public-ingressgateway:
      type: "NodePort"
  values:
    values: 
      global: 
        proxy: 
          resources:
            requests:
              cpu: 0m 
              memory: 0Mi
            limits:
              cpu: 0m
              memory: 0Mi
twistlock:
  enabled: false
EOF

helm upgrade --install bigbang \$HOME/bigbang/chart \
  --values \$HOME/bigbang/docs/example_configs/keycloak-dev-values.yaml \
  --values \$HOME/ib_creds.yaml \
  --values \$HOME/keycloak_qs_demo_values.yaml \
  --values https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --namespace=bigbang --create-namespace
EOFdeploy-keycloakEOF

ssh keycloak-cluster < ~/qs/deploy-keycloak.txt 
```

## Step 8: Edit your workstation's Hosts file to access the web pages hosted on the Big Bang Clusters

### Linux/Mac Users

```shell
# [admin@Laptop:~]
export KEYCLOAK_IP=$(cat ~/.ssh/config | grep keycloak-cluster -A 1 | grep Hostname | awk '{print $2}')
export WORKLOAD_IP=$(cat ~/.ssh/config | grep workload-cluster -A 1 | grep Hostname | awk '{print $2}')

echo "$KEYCLOAK_IP keycloak.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP authdemo.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP alertmanager.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP grafana.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP prometheus.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP argocd.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP kiali.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP tracing.bigbang.dev" | sudo tee -a /etc/hosts
echo "$WORKLOAD_IP kibana.bigbang.dev" | sudo tee -a /etc/hosts

cat /etc/hosts
```

### Windows Users

* Edit similarly using method mentioned in the generic quickstart

## Step 9: Make sure the clusters have had enough time to finish their deployments

* Note:  
  After copy pasting the following, you may need to wait up to 10 minutes. If you're too  
  fast you may see a temporary error about pod keycloak-0 not found. It's recommended to  
  copy paste this block of verification commands a 2nd time after 10 minutes have passed.  

* Note when you run `kubectl get svc -n=istio-system`, against each cluster, verify that EXTERNAL-IP isn't stuck in pending.

```shell
# [admin@Laptop:~]
export KUBECONFIG=$HOME/.kube/keycloak-cluster
kubectl get pods -A
kubectl wait --for=condition=ready --timeout=10m pod/keycloak-0 -n=keycloak 
# ^-- takes about 5min
kubectl get hr -A
kubectl get svc -n=istio-system 

export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl get hr -A
kubectl wait --for=condition=ready --timeout=15m hr/jaeger -n=bigbang 
# ^-- takes about 10-15mins
kubectl get hr -A
kubectl get svc -n=istio-system
```

## Step 10: Verify that you can access websites hosted in both clusters

* In a Web Browser visit the following 2 webpages
  * <https://keycloak.bigbang.dev>
  * <https://grafana.bigbang.dev>

## Step 11: Deploy a mock mission application to the workload cluster

```shell
# [admin@Laptop:~]
cat << EOFdeploy-mock-mission-appEOF > ~/qs/deploy-mock-mission-app.txt

#Creating demo namespace
k create ns mock-mission-app 

#Adding namespace to the service mesh
k label ns mock-mission-app istio-injection=enabled 

# Adding dockercred to namespace so istio side car image pull will work.
kubectl get secret private-registry -n=istio-system -o yaml | sed 's/namespace: .*/namespace: mock-mission-app/' | kubectl apply -f -

# Deploying mock mission application
kubectl apply -k github.com/stefanprodan/podinfo//kustomize -n=mock-mission-app

# Exposing via Istio Ingress Gateway
temp="""
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: mission
spec:
  gateways:
  - istio-system/public
  hosts:
  - authdemo.bigbang.dev
  http:
  - route:
    - destination:
         host: podinfo
         port:
            number: 9898
"""
echo "\$temp" | kubectl apply -f - -n=mock-mission-app
EOFdeploy-mock-mission-appEOF

ssh workload-cluster < ~/qs/deploy-mock-mission-app.txt

export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl wait --for=condition=available deployment/podinfo --timeout=3m -n=mock-mission-app
```

## Step 12: Visit the newly added webpage

* In a browser navigate to <https://authdemo.bigbang.dev>
* Note: authdemo currently isn't protected by the authservice AuthN/AuthZ proxy, the next steps configure that protection.

## Step 13: Create a Human User Account in Keycloak

1. Visit <https://keycloak.bigbang.dev>
1. Follow the self-registration link or visit it directly <https://keycloak.bigbang.dev/register>
1. Create a demo account, the email you specify doesn't have to exist for demo purposes, make sure you write down the demo username and password.
1. Create an MFA device.
1. It'll say "You need to verify your email address to activate your account" (You can ignore that and close the page.)
1. Visit <https://keycloak.bigbang.dev/auth/admin>
1. Log in as a keycloak admin, using the default creds of admin:password
  (Note: The admin's initial default credentials can be specified in code, by updating helm values.)
1. In the GUI:
   1. Navigate to: Manage/Users > [View all users] > [Edit] (your demo user)
   1. Under "Required User Actions": Delete [Verify Email]
   1. Under "Email Verified": Toggle Off to On
   1. Click Save

## Step 14: Create an Application Identity / Service Account / Non-Person Entity in Keycloak for the authdemo webpage

1. Visit <https://keycloak.bigbang.dev/auth/admin>
1. log in as a keycloak admin, using the default creds of admin:password
1. In the GUI:
   1. Navigate to: Manage/Groups > Impact Level 2 Authorized (double click)  
      Notice the group UUID in the URL: 00eb8904-5b88-4c68-ad67-cec0d2e07aa6
1. In the GUI:
   1. Navigate to: Configure/Clients > [Create]
   1. Set:
      Client ID = "demo-env_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_authdemo"  
      Client Protocol = openid-connect  
      Root URL = (blank)
   1. Save
1. In the GUI:
   1. Navigate to: Configure/Clients > [Edit] demo-env_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_authdemo
   1. Under "Access Type": Change Public to Confidential
   1. Under "Valid Redirect URIs": Add "https://authdemo.bigbang.dev/login/generic_oauth"  
      Note: /login/generic_oauth comes from auth service
   1. Save
   1. Scroll up to the top of the page and you'll see a newly added [Credentials] tab, click it.
   1. Copy the secret for the authdemo Client Application Identity, (it's labeled secret) you'll paste it into the next step

## Step 15: Deploy auth service to the workload cluster and use it to protect the mock mission app

```shell
# [admin@Laptop:~]

export AUTHDEMO_APP_ID_CLIENT_SECRET="pasted_value"
# It should look similar to the following dynamically generated demo value
# export AUTHDEMO_APP_ID_CLIENT_SECRET="fsCUSkwy2kaaSlgN4r4LPYOAvHCqzUk5" 

echo $AUTHDEMO_APP_ID_CLIENT_SECRET | grep "pasted_value" ; echo $? | grep 1 && echo "This validation check shows you remembered to update the pasted value." || ( for i in {1..10}; do echo "Validation check shows error, update the variable by pasting in the dynamically generated secret before moving on." ; done ; sleep 3 )

# Note: 
# JWKS: JSON Web Key Set is a public key used to verify JWT's issued by the IDP.
# Every Instance of Keycloak will have a unique JWKS, auth service needs to verify JWTs issued by Keycloak
# You find it by curling https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/openid-connect/certs
# then to prep for usage escape double quotes and wrapping the value in single quotes. 
export KEYCLOAK_IDP_JWKS=$(curl https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/openid-connect/certs | sed 's@"@\\"@g')

# Note: 
# Authservice needs the CA-cert.pem that Keycloak's HTTPS cert was signed by, *.bigbang.dev is signed by Let's Encrypt Free CA
export KEYCLOAK_CERTS_CA=$(curl https://letsencrypt.org/certs/isrgrootx1.pem)
```

* You can copy paste the following command block as is

```shell
# [admin@Laptop:~]
cat << EOFdeploy-auth-service-demoEOF > ~/qs/deploy-auth-service-demo.txt

# Note: Big Bang is configured such that if a pod is a part of the service mesh
# and labeled protect: keycloak, then AuthService will be injected in the data path
cat << EOF > ~/pods-in-deployment-label-patch.yaml
spec:
  template:
    metadata:
      labels:
        protect: keycloak
EOF

kubectl patch deployment podinfo --type merge --patch "\$(cat ~/pods-in-deployment-label-patch.yaml)" -n=mock-mission-app



cat << EOF > ~/auth_service_demo_values.yaml
sso:
  oidc:
    host: keycloak.bigbang.dev
    realm: baby-yoda
  token_url: "https://{{ .Values.sso.oidc.host }}/auth/realms/{{ .Values.sso.oidc.realm }}/protocol/openid-connect/token"
  auth_url: "https://{{ .Values.sso.oidc.host }}/auth/realms/{{ .Values.sso.oidc.realm }}/protocol/openid-connect/auth"
  jwks: '$KEYCLOAK_IDP_JWKS'
  certificate_authority: |
$(echo "$KEYCLOAK_CERTS_CA" | sed 's/^/    /')
# sed 's/^/    /', indents 4 spaces

addons:
  authservice: 
    enabled: true
    values:
      chains:
        authdemo:
          match:
            header: ":authority"
            prefix: "authdemo"
          callback_uri: https://authdemo.bigbang.dev/login/generic_oauth
          client_id: "demo-env_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_authdemo"
          client_secret: "$AUTHDEMO_APP_ID_CLIENT_SECRET"
EOF

helm upgrade --install bigbang \$HOME/bigbang/chart \
  --values https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --values \$HOME/ib_creds.yaml \
  --values \$HOME/demo_values.yaml \
  --values \$HOME/auth_service_demo_values.yaml \
  --namespace=bigbang --create-namespace
EOFdeploy-auth-service-demoEOF

ssh workload-cluster < ~/qs/deploy-auth-service-demo.txt

export KUBECONFIG=$HOME/.kube/workload-cluster
ssh workload-cluster 'helm get values bigbang -n=bigbang' # You can eyeball this to verify values were plugged in as expected
```

## Step 16: Revisit authdemo.bigbang.dev

* Go to <https://authdemo.bigbang.dev>
* Before we were taken straight to the mock mission app webpage
* Now* (or 30-120 seconds after copy pasting the above block of commands into the terminal), when you create a new tab and try to visit this URL it immediately redirects to a KeyCloak Log in Prompt and if you log in with your demo user, you'll a message like this:

> RBAC: access denied  
> Your account has not been granted access to this application group yet.  

## Step 17: Update the group membership of the user

1. Go to <https://keycloak.bigbang.dev/auth/admin>
1. Login with admin:password
1. In the GUI:
   1. Navigate to: Manage/Users > [View all users] > [Edit] (your Demo user)
   1. Click the Groups tab at the top
   1. Click Impact Level 2 Authorized
   1. Click [Join]

> Note:  
> If you try to repeat step 16 at this stage, you'll see either an infinite loading screen or message like this:  
> `Access to authdemo.bigbang.dev was denied`  
> `You don't have authorization to view this page.`  
> `HTTP ERROR 403`  
> The reason for this is that we configured our workstation's hostfile /etc/hosts to avoid needing to configure DNS. But the 2 k3d clusters are unable to resolve the DNS Names.  
> AuthService pods on the Workload Cluster need to be able to resolve the DNS name of keycloak.bigbang.dev  
> Keycloak pod on the Keycloak Cluster needs to be able to resolve the DNS name of authdemo.bigbang.dev

## Step 18: Update Inner Cluster DNS on the Workload Cluster

* The following commands will show there's an issue with DNS

```shell
# [admin@Laptop:~]

# The following tests DNS resolution from the perspective of a pod running in the cluster
export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl run -it test --image=busybox:stable 
```

```shell
# [pod@workload-cluster:~]
# ^-- this is your context, but your interface will look more like this:
# If you don't see a command prompt, try pressing enter.
# / #
exit
```

```shell
# [admin@Laptop:~]
kubectl exec -it test -- ping keycloak.bigbang.dev -c 1 | head -n 1
# Notice it mentions resolution as 127.0.0.1, this comes from public internet DNS, 
# The next steps will override the DNS resolution to suit the needs of this guide.
```

* The following copy pasteable block of commands will load new entries in coredns / inner cluster dns of both clusters.

```shell
# [admin@Laptop:~]
# We will override it by updating coredns, which works at the Inner Cluster Network level and has higher precedence.
export KEYCLOAK_IP=$(cat ~/.ssh/config | grep keycloak-cluster -A 1 | grep Hostname | awk '{print $2}')
export WORKLOAD_IP=$(cat ~/.ssh/config | grep workload-cluster -A 1 | grep Hostname | awk '{print $2}')
cat << EOF > ~/qs/k3d-dns-patch.yaml
data:
  NodeHosts: |
    172.21.0.2 k3d-workload-cluster-server-0
    172.21.0.1 host.k3d.internal
    $KEYCLOAK_IP keycloak.bigbang.dev
    $WORKLOAD_IP authdemo.bigbang.dev
EOF

export KUBECONFIG=$HOME/.kube/keycloak-cluster
kubectl patch configmap/coredns -n=kube-system --type merge --patch "$(cat ~/qs/k3d-dns-patch.yaml)"
kubectl delete pods -l=k8s-app=kube-dns -n=kube-system

export KUBECONFIG=$HOME/.kube/workload-cluster
kubectl patch configmap/coredns -n=kube-system --type merge --patch "$(cat ~/qs/k3d-dns-patch.yaml)"
kubectl delete pods -l=k8s-app=kube-dns -n=kube-system

# Retest DNS resolution from the perspective of a pod running in the cluster
kubectl exec -it test -- ping keycloak.bigbang.dev -c 1 | head -n 1
kubectl exec -it test -- ping authdemo.bigbang.dev -c 1 | head -n 1
# Now the k3d clusters can resolve the DNS to IP mappings, similar to our workstations /etc/hosts file
```

## Step 19: Revisit authdemo.bigbang.dev

1. Visit <https://authdemo.bigbang.dev>
1. You'll get redirected to keycloak.bigbang.dev
1. Log in to keycloak, and afterwords you'll get redirected to authdemo.bigbang.dev
