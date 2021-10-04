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

RUN curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

RUN yum -y install git docker-ce-cli unzip jq

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

# Install tree for directory structure
RUN yum -y install http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/tree-1.7.0-15.el8.x86_64.rpm

# Install yq for dependency handling
ENV YQ_VERSION='4.12.2'
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

# Install Pluto for API Deprecation Checking
ENV PLUTO_VERSION='5.0.1'
ADD https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_amd64.tar.gz /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz
RUN tar xzf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz pluto && mv pluto /usr/local/bin/ && chmod +x /usr/local/bin/pluto && rm -rf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz

# Install Kube no trouble for API Deprecation Checking in cluster
ENV KUBENT_VERSION='0.5.0'
ADD https://github.com/doitintl/kube-no-trouble/releases/download/${KUBENT_VERSION}/kubent-${KUBENT_VERSION}-linux-amd64.tar.gz /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz
RUN tar xzf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz kubent && mv kubent /usr/local/bin/ && chmod +x /usr/local/bin/kubent && rm -rf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz

# Remove needed repos
RUN rm -rf /etc/yum.repos.d/docker-ce.repo && \
    rm -rf /etc/yum.repos.d/CentOS.repo && \
    yum clean all
