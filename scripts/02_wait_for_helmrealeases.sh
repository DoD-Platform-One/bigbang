
#!/bin/bash
set -e
# Wait for components to be ready
for package in $(kubectl get helmrelease -n bigbang | awk '{print $1}' | grep -v NAME);
do kubectl wait --for=condition=Ready --timeout 600s helmrelease -n bigbang $package;
done
kubectl wait --for=condition=Ready --timeout 30s kustomizations.kustomize.toolkit.fluxcd.io -n bigbang secrets
