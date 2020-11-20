FROM docker:19.03

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
RUN set -eux; \
        apk add --no-cache \
                btrfs-progs \
                e2fsprogs \
                e2fsprogs-extra \
                iptables \
                openssl \
                shadow-uidmap \
                xfsprogs \
                xz \
                pigz \
                git curl bash npm \
        ; \
        if zfs="$(apk info --no-cache --quiet zfs)" && [ -n "$zfs" ]; then \
                apk add --no-cache zfs; \
        fi

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN set -eux; \
        addgroup -S dockremap; \
        adduser -S -G dockremap dockremap; \
        echo 'dockremap:165536:65536' >> /etc/subuid; \
        echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
        wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
        chmod +x /usr/local/bin/dind

# Install K3d
ENV K3D_VERSION='3.1.5'
ADD https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64 /usr/local/bin/k3d
RUN chmod +x /usr/local/bin/k3d

# Install kubectl
ENV KUBECTL_VERSION='1.19.3'
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install Conftest
ENV CONFTEST_VERSION='0.21.0'
ADD https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz
RUN tar xzf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz -C /usr/local/bin/  && chmod +x /usr/local/bin/conftest && rm -rf /conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz

# Install Helm
ENV HELM_VERSION='3.4.0'
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN tar xzf /helm-v${HELM_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ --strip-components 1 && chmod +x /usr/local/bin/helm && rm -rf /helm-v${HELM_VERSION}-linux-amd64.tar.gz

# Install Conftest for helm plugin
RUN helm plugin install https://github.com/instrumenta/helm-conftest

# Install ArgoCD CLI
ENV ARGO_VERSION='1.7.8'
ADD https://github.com/argoproj/argo-cd/releases/download/v${ARGO_VERSION}/argocd-linux-amd64 /usr/local/bin/argocd
RUN chmod +x /usr/local/bin/argocd

# Install fluxcd
ENV FLUX_VERSION='0.2.5'
ADD https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz /flux_${FLUX_VERSION}_linux_amd64.tar.gz
RUN tar xzf /flux_${FLUX_VERSION}_linux_amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/flux && rm -rf /flux_${FLUX_VERSION}_linux_amd64.tar.gz

# Install Istio
ENV ISTIO_VERSION='1.6.13'
ADD https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz
RUN tar xzf /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/istioctl && rm -rf /istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz

# Install mkcert
ENV MKCERT_VERSION='1.4.1'
ADD https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64 /usr/local/bin/mkcert
RUN chmod +x /usr/local/bin/mkcert

COPY cy-run.sh /usr/local/bin/

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
