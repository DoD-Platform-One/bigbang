FROM golang:1.13 AS builder

# Download build dependencies
RUN apt-get update && apt-get install -y \
    git libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev liblvm2-dev musl-dev \
    && apt-get clean

# Clone the latest release of p8kr and built the binrary statically
RUN git clone https://repo1.dso.mil/platform-one/hagrid/sync.git synker && \
    cd synker && \
    make binary-local-static DISABLE_CGO=1

#
FROM registry.access.redhat.com/ubi8/ubi:8.3

COPY --from=registry:2 /bin/registry /usr/local/bin/registry
COPY --from=builder /go/synker/synker /usr/local/bin/synker

RUN yum install -y unzip git jq

# Install yq
RUN curl -sfL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Install aws cli
RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && \
    unzip -qq -d /tmp /tmp/awscliv2.zip && \
    /tmp/aws/install && \
    rm -rf /tmp/aws*

RUN yum clean all && \
    rm -r /var/cache/dnf

