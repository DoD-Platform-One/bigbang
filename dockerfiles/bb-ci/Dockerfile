# This container is used in Bigbang's CI
# Please Keep this file updated when pushes are made
#
# @Version bb-ci:2.9.12
#
# docker build -t registry1.dso.mil/bigbang-ci/bb-ci:${VERSION} .
# docker push registry1.dso.mil/bigbang-ci/bb-ci:${VERSION}
# Update library/templates.yaml -> .util-image -> image with the latest image

FROM golang:1.13 AS builder
LABEL version="2.11.0"

# Download build dependencies
RUN apt-get update && apt-get install -y \
    git libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev liblvm2-dev musl-dev \
    && apt-get clean

# Clone the latest release of p8kr and built the binrary statically
RUN git clone https://repo1.dso.mil/platform-one/hagrid/sync.git synker && \
    cd synker && \
    make binary-local-static DISABLE_CGO=1

FROM golang:1.19 AS oscal-build

# Clone BigBang OSCAL Aggregator
# renovate: depName=defenseunicorns/bigbang-oscal-component-generator
ENV BB_OSCAL_VERSION='v0.1.0-alpha'
RUN git clone -b ${BB_OSCAL_VERSION} https://github.com/defenseunicorns/bigbang-oscal-component-generator.git \
    && cd bigbang-oscal-component-generator \
    && make build

FROM registry.access.redhat.com/ubi8/ubi:8.4

# This dockerfile will download all the needed tools to run a docker in docker k3d cluster

# Add registry and synker
COPY --from=registry:2 /bin/registry /usr/local/bin/registry
COPY --from=builder /go/synker/synker /usr/local/bin/synker
COPY --from=oscal-build /go/bigbang-oscal-component-generator/bin/bb-oscal /usr/local/bin/bb-oscal

RUN yum -y update && yum clean all

RUN echo $'[centos-appstream]\n\
name=CentOS-AppStream\n\
baseurl=http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os\n\
gpgcheck=0\n\
[BaseOS]\n\
name=CentOS-BaseOS\n\
baseurl=http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os\n\
enabled=1\n\
gpgcheck=0\n'\
>> /etc/yum.repos.d/CentOS.repo

ADD https://download.docker.com/linux/centos/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

RUN yum -y install git docker-ce-cli unzip jq bind-utils findutils python39 python39-pip diffutils patch

RUN pip3 install boto3==1.21.14 requests==2.27.1 urllib3==1.26.5 jsonschema==4.0.0

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.5.1 python3 -
RUN ln -s /root/.local/bin/poetry /usr/bin/poetry
RUN poetry config virtualenvs.in-project true

# Install NodeJS
RUN dnf module install nodejs:16 -y
# Install Playwright browsers (version from bb-docs-compiler package.json)
RUN yum -y install gtk3 alsa-lib libX11-xcb nss libgbm
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN mkdir /ms-playwright
RUN npx playwright@1.24.2 install
RUN chmod -R 777 /ms-playwright

# Install Kyverno
# renovate: depName=kyverno/kyverno
ENV KYVERNO_VERSION=v1.9.2
ADD https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz /kyverno_KYVERNO_VERSION_linux_x86_64.tar.gz
RUN tar xzf /kyverno_KYVERNO_VERSION_linux_x86_64.tar.gz \
    && mv kyverno /usr/local/bin/ \
    && chmod +x /usr/local/bin/kyverno \
    && rm -rf /kyverno_KYVERNO_VERSION_linux_x86_64.tar.gz

# Install Helm
# renovate: depName=helm/helm
ENV HELM_VERSION=3.12.0
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN tar xzf /helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64/helm && mv linux-amd64/helm /usr/local/bin/ && chmod +x /usr/local/bin/helm && rm -rf /helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64*

# Install fluxcd
# renovate: depName=fluxcd/flux2
ENV FLUX_VERSION=2.0.1
ADD https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz /flux_${FLUX_VERSION}_linux_amd64.tar.gz
RUN tar xzf /flux_${FLUX_VERSION}_linux_amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/flux && rm -rf /flux_${FLUX_VERSION}_linux_amd64.tar.gz

# Install K3d
# renovate: depName=rancher/k3d
ENV K3D_VERSION=5.5.1
ADD https://github.com/k3d-io/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64 /usr/local/bin/k3d
RUN chmod +x /usr/local/bin/k3d

# Install kubectl
# renovate: depName=kubernetes/kubectl
ENV KUBECTL_VERSION=1.27.2
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install yq for dependency handling
# renovate: depName=mikefarah/yq
ENV YQ_VERSION=4.34.1
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

# Install Pluto for API Deprecation Checking
# renovate: depName=FairwindsOps/pluto
ENV PLUTO_VERSION=5.16.4
ADD https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_amd64.tar.gz /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz
RUN tar xzf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz pluto && mv pluto /usr/local/bin/ && chmod +x /usr/local/bin/pluto && rm -rf /pluto_${PLUTO_VERSION}_linux_amd64.tar.gz

# Install Kube no trouble for API Deprecation Checking in cluster
# renovate: depName=doitintl/kube-no-trouble
ENV KUBENT_VERSION=0.7.0
ADD https://github.com/doitintl/kube-no-trouble/releases/download/${KUBENT_VERSION}/kubent-${KUBENT_VERSION}-linux-amd64.tar.gz /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz
RUN tar xzf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz kubent && mv kubent /usr/local/bin/ && chmod +x /usr/local/bin/kubent && rm -rf /kubent-${KUBENT_VERSION}-linux-amd64.tar.gz

# Install Release-CLI
# https://gitlab.com/gitlab-org/release-cli/-/blob/master/docs/examples/download-release-cli-from-generic-packages/index.md
ENV RELEASE_CLI='release-cli-linux-amd64'
ADD https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/$RELEASE_CLI /usr/local/bin/release-cli
RUN chmod +x /usr/local/bin/release-cli

# Install crane
# renovate: depName=google/go-containerregistry
ENV CRANE_VERSION=v0.15.2
ADD https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz /crane.tar.gz
RUN tar -zxf /crane.tar.gz crane && mv crane /usr/local/bin/crane && chmod +x /usr/local/bin/crane && rm -rf /crane.tar.gz


# Install Kustomize
# renovate: depName=kubernetes-sigs/kustomize
ENV KUSTOMIZE_VERSION=v4.5.2
ADD https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz
RUN tar xzf /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz kustomize && mv kustomize /usr/local/bin/ && chmod +x /usr/local/bin/kustomize && rm -rf /kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz

# Install Zarf
# renovate: depName=defenseunicorns/zarf
ENV ZARF_VERSION=v0.27.0
ADD https://github.com/defenseunicorns/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64 /usr/local/bin/zarf
RUN chmod +x /usr/local/bin/zarf

# Install aws cli
RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && \
    unzip -qq -d /tmp /tmp/awscliv2.zip && \
    /tmp/aws/install && \
    rm -rf /tmp/aws*
    
# Install CNI    
RUN mkdir -p /opt/cni/bin && \
    curl -s -L https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz  | tar xvz -C /opt/cni/bin 

# Remove needed repos
RUN rm -rf /etc/yum.repos.d/docker-ce.repo && \
    rm -rf /etc/yum.repos.d/CentOS.repo && \
    yum clean all && \
    rm -r /var/cache/dnf
