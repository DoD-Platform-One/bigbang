# Development Environment

[[_TOC_]]

BigBang developers use [k3d](https://k3d.io/), a lightweight wrapper to run [k3s](https://github.com/rancher/k3s) (Rancher Lab’s minimal Kubernetes distribution) in Docker. K3d is a virtualized kubernetes cluster that is quick to start and tear down for fast development iteration. K3d is sufficient for 95% of BigBang development work. In limited cases developers will use real infrastructure k8s deployments with Rancher, Konvoy, EKS, etc. Only k3d is covered in this document.

It is not recommend to run k3d with Big Bang on your local workstation. Instead use a remote k3d cluster running on an EC2 instance to shift the compute and network bandwidth to the cloud. Big Bang can be quite resource intensive and it requires a huge download bandwidth for the images. If you do insist on running k3d locally you should disable certain packages before deploying. You can do this in the values.yaml file by setting the package deploy to false. One of the packages that is most resource-intensive is the logging package. And you should create a local image registry cache to minimize the amount of image downloading.

There is a script that automates the creation and teardown of a remote k3d development environment. First, read the [script instructions](aws-k3d-script.md), understand what it does, and install required dependencies. Then, run the script [docs/assets/developer/scripts/k3d-dev.sh](../assets/scripts/developer/k3d-dev.sh) from your workstation. The console output at the end of the script will give you the information necessary to access and use the dev environment. Also, there is a video tutorial in Platform One IL2 Confluence. Search for "T3" and click the link to the page. Scroll down the page to the 57th video on 22-February-2022.

## Prerequisites

### Required Access

- AWS GovCloud "Big Bang dev" account - talk to your team government lead for access
- [BigBang repository](https://repo1.dso.mil/big-bang/bigbang)
- [Iron Bank registry](https://registry1.dso.mil/)

### Local Utilities

- [Helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [jq](https://stedolan.github.io/jq/download/)
- optional: [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
