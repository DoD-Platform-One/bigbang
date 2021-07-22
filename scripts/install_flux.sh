#!/usr/bin/env bash

set -e

#
# global defaults
#

REGISTRY_URL=registry1.dso.mil
FLUX_KUSTOMIZATION=base/flux
FLUX_SECRET=private-registry
WAIT_TIMEOUT=120


#
# helper functions
#

# script help message
function help {
  cat << EOF
usage: $(basename "$0") <arguments>
-h|--help              - print this help message and exit
-u|--registry-username - (required) registry username to use for flux installation
-p|--registry-password - (required) registry password to use for flux installation
-w|--wait-timeout      - (optional, default: 120) how long to wait; in seconds, for each key flux resource component
EOF
}

#
# cli parsing
#

PARAMS=""
while (( "$#" )); do
  case "$1" in
    # registry username required argument
    -u|--registry-username)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        REGISTRY_USERNAME=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        help; exit 1
      fi
      ;;
    # registry password required argument
    -p|--registry-password)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        REGISTRY_PASSWORD=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        help; exit 1
      fi
      ;;
    # registry email required argument
    -e|--registry-email)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        REGISTRY_EMAIL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        help; exit 1
      fi
      ;;
    # wait timeout optional argument
    -w|--wait-timeout)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        WAIT_TIMEOUT=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        help; exit 1
      fi
      ;;
    # help flag
    -h|--help)
      help; exit 0
      ;;
    # unsupported flags
    -*|--*=)
      echo "Error: Unsupported flag $1" >&2
      help; exit 1
      ;;
    # preserve positional arguments
    *)
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# check required arguments
if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ]; then
  help; exit 1
fi

# debug print cli args
echo "REGISTRY_URL: $REGISTRY_URL"
echo "REGISTRY_USERNAME: $REGISTRY_USERNAME"


#
# install flux
#

kubectl create namespace flux-system || true


echo "Creating secret $FLUX_SECRET in namespace flux-system"
kubectl create secret docker-registry "$FLUX_SECRET" -n flux-system \
  --docker-server="$REGISTRY_URL" \
  --docker-username="$REGISTRY_USERNAME" \
  --docker-password="$REGISTRY_PASSWORD" \
  --docker-email="$REGISTRY_EMAIL" \
  --dry-run=client -o yaml | kubectl apply -n flux-system -f -

echo "Installing flux from kustomization"
kustomize build "$FLUX_KUSTOMIZATION" | kubectl apply -f -

#
# verify flux
#
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/helm-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/source-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/kustomize-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/notification-controller"
