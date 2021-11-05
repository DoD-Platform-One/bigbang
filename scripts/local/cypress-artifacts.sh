PACKAGE_NAMESPACE=$1

if [ ! ${PACKAGE_NAMESPACE} ]; then
  echo "ERROR: Must supply namespace. Usage: ./cypress-artifacts.sh NAMESPACE"
  exit 1
fi

if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots &>/dev/null; then
    kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots -o jsonpath='{.data.cypress-screenshots\.tar\.gz\.b64}' > cypress-screenshots.tar.gz.b64
    cat cypress-screenshots.tar.gz.b64 | base64 -d > cypress-screenshots.tar.gz
    mkdir -p cypress-artifacts
    tar -zxf cypress-screenshots.tar.gz --strip-components=2 -C cypress-artifacts
    rm -rf cypress-screenshots.tar.gz cypress-screenshots.tar.gz.b64
fi
if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos &>/dev/null; then
    kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos -o jsonpath='{.data.cypress-videos\.tar\.gz\.b64}' > cypress-videos.tar.gz.b64
    cat cypress-videos.tar.gz.b64 | base64 -d > cypress-videos.tar.gz
    mkdir -p cypress-artifacts
    tar -zxf cypress-videos.tar.gz --strip-components=2 -C cypress-artifacts
    rm -rf cypress-videos.tar.gz cypress-videos.tar.gz.b64
fi
