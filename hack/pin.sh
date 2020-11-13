#!/bin/bash

# This script can be used to pull out the values that are needed to pin the current deployments git commits to prevent
# internal packages from moving:

# After deploying a healthy environment, run this script and take the output values section and merge into
# the values file for the deployemnt:

#  ./hack/pin.sh                                                                

# istio:
#   git:
#     commit: f40172dd278e4f3551e6a1e8d4c8625771fbf928
#     branch: chart-release
# clusterAuditor:
#   git:
#     commit: 4ca478df04063ec8cd91b3ae2d2472b77675495d
#     branch: chart-release
# gatekeeper:
#   git:
#     commit: 714069053e9696f5e116deb2f677f1c2d213e9b6
#     branch: chart-release
# logging:
#   git:
#     commit: 02d6e9a073d196ecdf0951941c432beea642fc73
#     branch: release-v0.2.x
# monitoring:
#   git:
#     commit: 014fb187b81eb976e76a4bb1a76bb4479aa2cea3
#     branch: release-v0.2.x
# twistlock:
#   git:
#     commit: faf038197291915713e0f213a4e35991e72f73f6
#     branch: chart-release

function get_commit() {
    kubectl get gitrepositories.source.toolkit.fluxcd.io -n bigbang $1 -o jsonpath="{ .status.artifact.revision }" | cut -f2 -d "/"
}

function get_branch() {
    kubectl get gitrepositories.source.toolkit.fluxcd.io -n bigbang $1 -o jsonpath="{ .status.artifact.revision }" | cut -f1 -d "/"
}

# create script to product the pins for 
echo """
istio:
  git:
    commit: `get_commit istio`
    branch: `get_branch istio`
clusterAuditor:
  git:
    commit: `get_commit cluster-auditor`
    branch: `get_branch cluster-auditor`
gatekeeper:
  git:
    commit: `get_commit gatekeeper`
    branch: `get_branch gatekeeper`
logging:
  git:
    commit: `get_commit logging`
    branch: `get_branch logging`
monitoring:
  git:
    commit: `get_commit monitoring`
    branch: `get_branch monitoring`
twistlock:
  git:
    commit: `get_commit twistlock`
    branch: `get_branch twistlock`
"""