# This container is used in Bigbang's CI
# Please Keep this file updated when pushes are made
#
# @Version bb-ci:2.0.1

FROM golang:1.13 AS builder

# Download build dependencies
RUN apt-get update && apt-get install -y \
    git libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev liblvm2-dev musl-dev \
    && apt-get clean

# Clone the latest release of p8kr and built the binrary statically
RUN git clone https://repo1.dso.mil/platform-one/hagrid/sync.git synker && \
    cd synker && \
    make binary-local-static DISABLE_CGO=1

FROM registry.access.redhat.com/ubi8/ubi:8.4

# This dockerfile will download all the needed tools to run a docker in docker k3d cluster

# Add registry and synker
COPY --from=registry:2 /bin/registry /usr/local/bin/registry
COPY --from=builder /go/synker/synker /usr/local/bin/synker

RUN yum -y update && yum clean all

RUN echo $'[centos-appstream]\n\
name=CentOS-AppStream\n\
baseurl=http://mirror.centos.org/centos/8/AppStream/x86_64/os\n\
enabled=1\n\
gpgcheck=0\n\
[BaseOS]\n\
name=CentOS-BaseOS\n\
baseurl=http://mirror.centos.org/centos/8/BaseOS/x86_64/os\n\
enabled=1\n\
gpgcheck=0\n'\
>> /etc/yum.repos.d/CentOS.repo

ADD https://download.docker.com/linux/centos/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

RUN yum -y install git docker-ce-cli unzip jq bind-utils findutils python3

RUN pip3 install boto3 && pip3 install requests

# Install Conftest
ENV CONFTEST_VERSION='0.28.2'
ADD https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz
RUN tar xzf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz conftest && mv conftest /usr/local/bin/  && chmod +x /usr/local/bin/conftest && rm -rf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz

# Install Helm
ENV HELM_VERSION='3.7.1'
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN tar xzf /helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64/helm && mv linux-amd64/helm /usr/local/bin/ && chmod +x /usr/local/bin/helm && rm -rf /helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64*

# Install Conftest for helm plugin
RUN helm plugin install https://github.com/instrumenta/helm-conftest

# Install ArgoCD CLI
ENV ARGO_VERSION='2.1.6'
ADD https://github.com/argoproj/argo-cd/releases/download/v${ARGO_VERSION}/argocd-linux-amd64 /usr/local/bin/argocd
RUN chmod +x /usr/local/bin/argocd

# Install fluxcd
ENV FLUX_VERSION='0.20.0'
ADD https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz /flux_${FLUX_VERSION}_linux_amd64.tar.gz
RUN tar xzf /flux_${FLUX_VERSION}_linux_amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/flux && rm -rf /flux_${FLUX_VERSION}_linux_amd64.tar.gz

# Install Istio
ENV ISTIO_VERSION='1.11.4'
ADD https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz
RUN tar xzf /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/istioctl && rm -rf /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz

# Install mkcert
ENV MKCERT_VERSION='1.4.3'
ADD https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64 /usr/local/bin/mkcert
RUN chmod +x /usr/local/bin/mkcert

# Install SOPS
ENV SOPS_VERSION='3.7.1'
ADD https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops

# Install SopsSecretGenerator
ENV SSG_VERSION='1.4.0'
ADD https://github.com/goabout/kustomize-sopssecretgenerator/releases/download/v${SSG_VERSION}/SopsSecretGenerator_${SSG_VERSION}_linux_amd64 /usr/local/bin/SopsSecretGenerator
RUN chmod +x /usr/local/bin/SopsSecretGenerator

# Install K3d
ENV K3D_VERSION='5.0.3'
ADD https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64 /usr/local/bin/k3d
RUN chmod +x /usr/local/bin/k3d

# Install kubectl
ENV KUBECTL_VERSION='1.21.0'
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install tree for directory structure
RUN yum -y install http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/tree-1.7.0-15.el8.x86_64.rpm

# Install yq for dependency handling
ENV YQ_VERSION='4.13.5'
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

# Install Pluto for API Deprecation Checking
ENV PLUTO_VERSION='5.1.0'
ADD https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_amd64.tar.gz /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz
RUN tar xzf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz pluto && mv pluto /usr/local/bin/ && chmod +x /usr/local/bin/pluto && rm -rf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz

# Install Kube no trouble for API Deprecation Checking in cluster
ENV KUBENT_VERSION='0.5.1'
ADD https://github.com/doitintl/kube-no-trouble/releases/download/${KUBENT_VERSION}/kubent-${KUBENT_VERSION}-linux-amd64.tar.gz /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz
RUN tar xzf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz kubent && mv kubent /usr/local/bin/ && chmod +x /usr/local/bin/kubent && rm -rf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz

# Install Release-CLI
# https://gitlab.com/gitlab-org/release-cli/-/blob/master/docs/examples/download-release-cli-from-generic-packages/index.md
ENV RELEASE_CLI='release-cli-linux-amd64'
ADD https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/$RELEASE_CLI /usr/local/bin/release-cli
RUN chmod +x /usr/local/bin/release-cli

# Install crane
ENV CRANE_VERSION='v0.6.0'
ADD https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz /crane.tar.gz
RUN tar -zxf /crane.tar.gz crane && mv crane /usr/local/bin/crane && chmod +x /usr/local/bin/crane && rm -rf /crane.tar.gz

# Install Kustomize
ENV KUSTOMIZE_VERSION='v4.4.0'
ADD https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz
RUN tar xzf /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz kustomize && mv kustomize /usr/local/bin/ && chmod +x /usr/local/bin/kustomize && rm -rf /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz

# Install aws cli
RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && \
    unzip -qq -d /tmp /tmp/awscliv2.zip && \
    /tmp/aws/install && \
    rm -rf /tmp/aws*

# Remove needed repos
RUN rm -rf /etc/yum.repos.d/docker-ce.repo && \
    rm -rf /etc/yum.repos.d/CentOS.repo && \
    yum clean all && \
    rm -r /var/cache/dnf
