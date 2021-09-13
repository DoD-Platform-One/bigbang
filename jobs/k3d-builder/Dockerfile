FROM registry.access.redhat.com/ubi8/ubi:8.4

# This dockerfile will download all the needed tools to run a docker in docker k3d cluster

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

RUN echo $'[google-chrome]\n\
name=google-chrome\n\
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub\n'\
>> /etc/yum.repos.d/google.repo

RUN curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

RUN yum -y install npm git xorg-x11-server-Xvfb gtk2-devel gtk3-devel libnotify-devel GConf2 nss libXScrnSaver alsa-lib docker-ce-cli unzip jq google-chrome-stable

# Install Conftest
ENV CONFTEST_VERSION='0.23.0'
ADD https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz
RUN tar xzf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz -C /usr/local/bin/  && chmod +x /usr/local/bin/conftest && rm -rf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz

# Install Helm
ENV HELM_VERSION='3.6.3'
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN tar xzf /helm-v${HELM_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ --strip-components 1 && chmod +x /usr/local/bin/helm && rm -rf /helm-v${HELM_VERSION}-linux-amd64.tar.gz

# Install Conftest for helm plugin
RUN helm plugin install https://github.com/instrumenta/helm-conftest

# Install ArgoCD CLI
ENV ARGO_VERSION='2.1.2'
ADD https://github.com/argoproj/argo-cd/releases/download/v${ARGO_VERSION}/argocd-linux-amd64 /usr/local/bin/argocd
RUN chmod +x /usr/local/bin/argocd

# Install fluxcd
ENV FLUX_VERSION='0.17.0'
ADD https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz /flux_${FLUX_VERSION}_linux_amd64.tar.gz
RUN tar xzf /flux_${FLUX_VERSION}_linux_amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/flux && rm -rf /flux_${FLUX_VERSION}_linux_amd64.tar.gz

# Install Istio
ENV ISTIO_VERSION='1.11.2'
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
ENV K3D_VERSION='4.3.0'
ADD https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64 /usr/local/bin/k3d
RUN chmod +x /usr/local/bin/k3d

# Install kubectl
ENV KUBECTL_VERSION='1.20.5'
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Cypress install
RUN npm install cypress && \
    ln -s /node_modules/cypress/bin/cypress /usr/local/bin/cypress && \
    cypress verify

# Install tree for directory structure
RUN yum -y install http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/tree-1.7.0-15.el8.x86_64.rpm

# Install yq for dependency handling
ENV YQ_VERSION='4.12.2'
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

# Install popeye for package testing
ENV POPEYE_VERSION='0.9.7'
ADD https://github.com/derailed/popeye/releases/download/v${POPEYE_VERSION}/popeye_Linux_x86_64.tar.gz /popeye_Linux_x86_64.tar.gz
RUN tar xzf /popeye_Linux_x86_64.tar.gz popeye && mv popeye /usr/local/bin/ && chmod +x /usr/local/bin/popeye && rm -rf /popeye_Linux_x86_64.tar.gz

# Install Clusterlint for package testing
ENV CLUSTERLINT_VERSION='0.2.6'
ADD https://github.com/digitalocean/clusterlint/releases/download/v${CLUSTERLINT_VERSION}/clusterlint-${CLUSTERLINT_VERSION}-linux-amd64.tar.gz /clusterlint-${CLUSTERLINT_VERSION}-linux-amd64.tar.gz
RUN tar xzvf /clusterlint-${CLUSTERLINT_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/clusterlint && rm -rf /clusterlint-${CLUSTERLINT_VERSION}-linux-amd64.tar.gz

# Install Polaris for configuration testing
ENV POLARIS_VERSION='4.1.0'
ADD https://github.com/FairwindsOps/polaris/releases/download/${POLARIS_VERSION}/polaris_linux_amd64.tar.gz /polaris_${POLARIS_VERSION}_linux_amd64.tar.gz
RUN tar xzf /polaris_${POLARIS_VERSION}_linux_amd64.tar.gz polaris && mv polaris /usr/local/bin/ && chmod +x /usr/local/bin/polaris && rm -rf /polaris_${POLARIS_VERSION}_linux_amd64.tar.gz

# Install kube-linter for package linting
ENV KUBE_LINTER_VERSION='0.2.3'
ADD https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-linux.tar.gz /kube-linter-linux.tar.gz
RUN tar xzvf /kube-linter-linux.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/kube-linter && rm -rf /kube-linter-linux.tar.gz

# Remove needed repos
RUN rm -rf /etc/yum.repos.d/docker-ce.repo && \
    rm -rf /etc/yum.repos.d/CentOS.repo && \
    rm -rf /etc/yum.repos.d/google.repo && \
    yum clean all
