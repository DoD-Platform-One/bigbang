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
NAMESPACE=flux-system

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
-p|--registry-password   - (optional, prompted if no existing secret) registry password to use for flux installation
-w|--wait-timeout        - (optional, default: 120) how long to wait; in seconds, for each key flux resource component
-n|--flux-namespace      - (optional, default: flux-system) the namespace to use when deploying flux resources
EOF
}

# check for existing pull secret
function check_secrets {
  if kubectl get secrets/"$FLUX_SECRET" -n $NAMESPACE >/dev/null 2>&1; then
    #the secret exists
    FLUX_SECRET_EXISTS=0
  else
    #the secret does not exist
    FLUX_SECRET_EXISTS=1
  fi
}

# securely prompt for the Registry1 password
function get_password {
  until [[ $REGISTRY_PASSWORD ]]; do
    read -s -p "Please enter your Registry1 password: " REGISTRY_PASSWORD
  done
}

# prompt for the Registry1 username
function get_username {
  until [[ $REGISTRY_USERNAME ]]; do
    read -p "Please enter your Registry1 username: " REGISTRY_USERNAME
  done
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
      get_username
      shift
    fi
    ;;
  # registry password required argument
  -p | --registry-password)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      REGISTRY_PASSWORD=$2
      shift 2
    else
      get_password
      shift
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
  # namespace for the flux installation optional argument
  -n | --flux-namespace)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      NAMESPACE=$2
      shift 2
    else
      shift
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

# if secret doesn't exist, create it
if [ -z "$FLUX_SECRET_EXISTS" ] || [ "$FLUX_SECRET_EXISTS" -eq 1 ]; then

  # check required arguments
  if [ -z "$REGISTRY_USERNAME" ]; then
    get_username
  fi
  if [ -z "$REGISTRY_PASSWORD" ]; then
    get_password
  fi

  # debug print cli args
  echo "REGISTRY_URL: $REGISTRY_URL"
  echo "REGISTRY_USERNAME: $REGISTRY_USERNAME"

  echo "Creating $NAMESPACE namespace so that the docker-registry secret can be added first."
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

  echo "Creating secret $FLUX_SECRET in namespace $NAMESPACE"
  kubectl create secret docker-registry "$FLUX_SECRET" -n $NAMESPACE \
    --docker-server="$REGISTRY_URL" \
    --docker-username="$REGISTRY_USERNAME" \
    --docker-password="$REGISTRY_PASSWORD" \
    --docker-email="$REGISTRY_EMAIL" \
    --dry-run=client -o yaml | kubectl apply -n $NAMESPACE -f -
fi

#
# install flux
#
echo "Installing flux from kustomization"
KUBECTL_VERSION=$(kubectl version --client --output=yaml | awk '/gitVersion:/ {print $2}' | cut -c2-)
KUBECTL_MIN_VERSION="1.26.0"

if [ "$(printf '%s\n' "$KUBECTL_MIN_VERSION" "$KUBECTL_VERSION" | sort -V | head -n1)" = "$KUBECTL_MIN_VERSION" ]; then
  kubectl kustomize "$FLUX_KUSTOMIZATION" |
    sed "s/name: flux-system/name: ${NAMESPACE}/g" |
    sed "s/namespace: flux-system/namespace: ${NAMESPACE}/g" |
    sed "s/registry1.dso.mil/${REGISTRY_URL}/g" |
    kubectl apply -f -
else
  if [ command -v kustomize ] >/dev/null 2>&1; then
    echo "Kustomize not found"
    exit 1
  else
    kustomize build "$FLUX_KUSTOMIZATION" |
      sed "s/name: flux-system/name: ${NAMESPACE}/g" |
      sed "s/namespace: flux-system/namespace: ${NAMESPACE}/g" |
      sed "s/registry1.dso.mil/${REGISTRY_URL}/g" |
      kubectl apply -f -
  fi
fi

#
# verify flux
#
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/helm-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/source-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/kustomize-controller"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/notification-controller"
