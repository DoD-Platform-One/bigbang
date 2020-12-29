#!/bin/bash
set -o pipefail
set -o errexit

# Bare minimum dependency collection
yum install -y unzip
yum update -y

cd /usr/local/bin

# RKE2
curl -sL https://get.rke2.io -o rke2.sh
curl -OLs "${RKE2_URL}/${RKE2_VERSION}/{rke2.linux-amd64,rke2.linux-amd64.tar.gz,rke2-images.linux-amd64.txt,rke2-images.linux-amd64.tar.gz,sha256sum-amd64.txt}"
grep -v "e2e-*" sha256sum-amd64.txt | sha256sum -c /dev/stdin

if [ $? -ne 0 ]
  then
    echo "[ERROR] checksum of rke2 files don't match"
    exit 1
fi

rm -f sha256sum-amd64.txt

chmod 755 rke2*

# Install rke2 components (with yum so selinux components are fetched)
INSTALL_RKE2_METHOD='yum' ./rke2.sh
INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="agent" ./rke2.sh

# Move and decompress images to pre-load dir
mkdir -p /var/lib/rancher/rke2/agent/images/ && zcat rke2-images.linux-amd64.tar.gz > /var/lib/rancher/rke2/agent/images/rke2-images.linux-amd64.tar

# AWS CLI
curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && unzip -qq -d /tmp /tmp/awscliv2.zip && /tmp/aws/install --bin-dir /usr/bin
rm -rf /tmp/aws*

# WARN: This sets the default region to the current region that packer is building from
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

cat <<EOF >> /etc/environment
HISTTIMEFORMAT="%F %T "
KUBECONFIG=/etc/rancher/rke2/rke2.yaml
EOF
cat <<EOF >> /root/.bash_aliases
alias k='rke2 kubectl'
EOF

# Clean up build instance history
rm -rf \
  /etc/hostname \
  /home/ec2-user/.ssh/authorized_keys \
  /root/.ssh/authorized_keys \
  /var/lib/cloud/data \
  /var/lib/cloud/instance \
  /var/lib/cloud/instances \
  /var/lib/cloud/sem \
  /var/log/cloud-init-output.log \
  /var/log/cloud-init.log \
  /var/log/secure \
  /var/log/wtmp \
  /var/log/apt
> /etc/machine-id
> /var/log/wtmp
> /var/log/btmp
yum clean all -y
df -h; date
history -c
