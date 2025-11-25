#!/usr/bin/env bash

ZARF_VERSION=v0.26.1
BIGBANG_VERSION=2.0.0

# Choices: warn, info, debug, trace
# Currently set only for zarf package deploy
ZARF_LOG_LEVEL=${ZARF_LOG_LEVEL:=info}

# Prerequisites: REGISTRY1_USERNAME and REGISTRY1_PASSWORD must be exported locally.
# Configurable: ZARF_TEST_REPO, ZARF_TEST_REPO_BRANCH, ZARF_TEST_REPO_DIRECTORY all define where to pick up the zarf.yaml file.
# Example with configuration: ZARF_TEST_REPO=https://repo1.dso.mil/some-repo.git ZARF_TEST_REPO_BRANCH=development docs/assets/scripts/airgap-zarf/zarf-dev.sh

AWSUSERNAME=${AWSUSERNAME:=`aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/'`}
echo "Username: $AWSUSERNAME"
KeyName=${AWSUSERNAME}-dev
PublicIP=`aws ec2 describe-instances --output text \
              --query "Reservations[].Instances[].PublicIpAddress" \
              --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=instance-state-name,Values=running"`
echo "Public IP: ${PublicIP}"

ZARF_TEST_REPO=${ZARF_TEST_REPO:=https://github.com/defenseunicorns/zarf}
ZARF_TEST_REPO_BRANCH=${ZARF_TEST_REPO_BRANCH:=$ZARF_VERSION}
ZARF_TEST_REPO_DIRECTORY=${ZARF_TEST_REPO_DIRECTORY:=zarf/examples/big-bang}

function run() {
  ssh -i ~/.ssh/${KeyName}.pem -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@${PublicIP} $1
}

# install zarf
echo "Installing Zarf ${ZARF_VERSION}"...
run "curl -LO https://github.com/defenseunicorns/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64"
run "sudo mv /home/ubuntu/zarf_${ZARF_VERSION}_Linux_amd64 /usr/local/bin/zarf"
run "sudo chmod +x /usr/local/bin/zarf"

# get zarf init package
echo "Retrieving zarf init package..."
run "wget -q https://github.com/defenseunicorns/zarf/releases/download/${ZARF_VERSION}/zarf-init-amd64-${ZARF_VERSION}.tar.zst"

# zarf init, package and deploy
run "set +o history && echo ${REGISTRY1_PASSWORD} | zarf tools registry login registry1.dso.mil --username ${REGISTRY1_USERNAME} --password-stdin || set -o history"
run "zarf init --components=git-server --confirm --log-level=${ZARF_LOG_LEVEL}"
run "git clone --depth 1 --single-branch --branch ${ZARF_TEST_REPO_BRANCH} ${ZARF_TEST_REPO}"
run "cd ${ZARF_TEST_REPO_DIRECTORY} && zarf package create --confirm --max-package-size=0"
run "cd ${ZARF_TEST_REPO_DIRECTORY} && zarf package deploy zarf-package-big-bang-example-amd64-${BIGBANG_VERSION}.tar.zst --confirm --components=gitea-virtual-service --log-level=${ZARF_LOG_LEVEL}"
