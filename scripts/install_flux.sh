#!/usr/bin/env bash

set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

#
# global defaults
#
FLUX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
FLUX_KUSTOMIZATION="${FLUX_SCRIPT_DIR}/../base/flux"
REGISTRY_URL=registry1.dso.mil
FLUX_SECRET=private-registry
WAIT_TIMEOUT=300

#
# helper functions
#

# script help message
function help {
  cat <<EOF
usage: $(basename "$0") <arguments>
-h|--help                - print this help message and exit
-r|--registry-url        - (optional, default: registry1.dso.mil) registry url to use for flux installation
-s|--use-existing-secret - (optional) use existing private-registry secret 
-u|--registry-username   - (required) registry username to use for flux installation
-p|--registry-password   - (required) registry password to use for flux installation
-w|--wait-timeout        - (optional, default: 120) how long to wait; in seconds, for each key flux resource component
EOF
}

# script check for existing pull secret
function check_secrets {
  if kubectl get secrets/"$FLUX_SECRET" -n flux-system >/dev/null 2>&1; then
    #the secret exists
    FLUX_SECRET_EXISTS=0
  else
    #the secret does not exist
    FLUX_SECRET_EXISTS=1
  fi
}

#
# cli parsing
#

PARAMS=""
while (("$#")); do
  case "$1" in
  # registry username required argument
  -u | --registry-username)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      REGISTRY_USERNAME=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # registry password required argument
  -p | --registry-password)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      REGISTRY_PASSWORD=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # registry email required argument
  -e | --registry-email)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      REGISTRY_EMAIL=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # registry url optional argument
  -r | --registry-url)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      REGISTRY_URL=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # wait timeout optional argument
  -w | --wait-timeout)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      WAIT_TIMEOUT=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # help flag
  -h | --help)
    help
    exit 0
    ;;
  # Check if private-registry secret exists
  -s | --use-existing-secret)
    check_secrets
    shift
    ;;
  # unsupported flags
  -* | --*=)
    echo "Error: Unsupported flag $1" >&2
    help
    exit 1
    ;;
  # preserve positional arguments
  *)
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done

# check if secret exists
if [ -z "$FLUX_SECRET_EXISTS" ] || [ "$FLUX_SECRET_EXISTS" -eq 1 ]; then

  # check required arguments
  if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_PASSWORD" ]; then
    help
    exit 1
  fi

  # debug print cli args
  echo "REGISTRY_URL: $REGISTRY_URL"
  echo "REGISTRY_USERNAME: $REGISTRY_USERNAME"

  kubectl create namespace flux-system || true

  echo "Creating secret $FLUX_SECRET in namespace flux-system"
  kubectl create secret docker-registry "$FLUX_SECRET" -n flux-system \
    --docker-server="$REGISTRY_URL" \
    --docker-username="$REGISTRY_USERNAME" \
    --docker-password="$REGISTRY_PASSWORD" \
    --docker-email="$REGISTRY_EMAIL" \
    --dry-run=client -o yaml | kubectl apply -n flux-system -f -
fi

#
# install flux
#
echo "Installing flux from kustomization"
KUBECTL_VERSION=$(kubectl version --client --short | awk -F "v" '{print $NF}')
KUBECTL_MIN_VERSION="1.21.0"

if [ "$(printf '%s\n' "$KUBECTL_MIN_VERSION" "$KUBECTL_VERSION" | sort -V | head -n1)" = "$KUBECTL_MIN_VERSION" ]; then
  kubectl kustomize "$FLUX_KUSTOMIZATION" | sed "s/registry1.dso.mil/${REGISTRY_URL}/g" | kubectl apply -f -
else
  if [ command -v kustomize ] >/dev/null 2>&1; then
    echo "Kustomize not found"
    exit 1
  else
    kustomize build "$FLUX_KUSTOMIZATION" | sed "s/registry1.dso.mil/${REGISTRY_URL}/g" | kubectl apply -f -
  fi
fi

#
# verify flux
#
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/helm-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/source-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/kustomize-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n "flux-system" "deployment/notification-controller"
