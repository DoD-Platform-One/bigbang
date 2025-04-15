# Migrating from Istio Operator to Helm based Istio
  
### Timeline:
- The new Istio Helm packages [istio-core](https://repo1.dso.mil/big-bang/product/packages/istio-core) and [istio-gateway](https://repo1.dso.mil/big-bang/product/packages/istio-gateway) are *Beta* in [Big Bang 2.51](https://repo1.dso.mil/big-bang/bigbang/-/releases)
-  These packages will be generally available and stable for production use in 2.52 (or 2.53)
-  The [istio-operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator) and [istio-controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane) packages will no longer be present in Big Bang 3.0
- Therefore, migrate from Istio Operator to Istio Helm in BB 2.52 (or 2.53) before upgrading BB to 3.0  
    
### Considerations:

- The helm packages update Istio from 1.23 to 1.25
- The Istio Operator is *End of Life* and does not support versions of Istio after 1.23
- Istio 1.23 is only supported [through April 2025](https://istio.io/latest/docs/releases/supported-releases/#:~:text=1.25%2C%201.26%2C%201.27-,1.23,-Yes)
  
## Migration Process  
  
Istio can be migrated from the old operator packages to the new helm-based packages in-place with a few steps.
### Step 1 : Swap `istio` for `istioCore`
Disable the old istio package and enable the new istioCore package:
```yaml
istioOperator:
  enabled: true
istio:
  enabled: false
  
istioCore:
  enabled: true
istioGateway:
  enabled: false
```
Give the cluster a few minutes for all helm releases to become `ready`.

### Step 2 : Disable `istioOperator` and enable `istioGateway`  
  
Removal of the operator and the enablement of the new gateway package reinstantiates cluster gateways.  
  
When migrating gateway configurations, see [the examples here](../../../chart/values.yaml#L206-301) as a reference to format values and configure postRenderers.  
    
```yaml
istioOperator:
  enabled: false
istio:
  enabled: false
  
istioCore:
  enabled: true
istioGateway:
  enabled: true
```
  
After all helm releases become `ready` once again, verify gateway(s) recieves an external IP:
```bash
kubectl get svc -n istio-gateway
NAME                  TYPE         CLUSTER-IP    EXTERNAL-IP  PORT(S)                                    
public-ingressgateway LoadBalancer 10.43.110.109 172.16.88.88 15021:31155/TCP,80:31302/TCP,443:31046/TCP 
```
The migration process is now complete.  
  
## Troubleshooting  
  
Below are a few tips for troubleshooting if the migration did not go as smoothly as expected.  
  
### Services are unreachable
  
```
upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: TLS_error:|268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED:TLS_error_end
```
To resolve this issue, cycle all Istio injected pods allowing their reconnection.  
  
The below bash script iterates across all `istio-injected` namespaces and recycles all pods:
```bash
# in istio-injected namespaces, recycle pods
for namespace in `kubectl get ns -o custom-columns=:.metadata.name --no-headers -l istio-injection=enabled`
do
    echo -e "\n♻️ recycling pods in namespace: $namespace"
    for pod in `kubectl get pods -o custom-columns=:.metadata.name --no-headers -n $namespace`
    do 
        kubectl delete pod $pod -n $namespace
    done
done
```
  
Pods should return to `ready` within a few minutes.
### Reconcile Helm Releases
  
If may be necessary to synchronize helm releases managed by Flux when they become *out of sync*.  
  
The `flux` CLI must be [installed](https://fluxcd.io/flux/installation/) to use this bash script that iterates across all helm releases initiating a [reconciliation](https://fluxcd.io/flux/cmd/flux_reconcile_helmrelease):
```bash
# reconcile all of big bang's helm releases w/ flux
for hr in `kubectl get hr --no-headers -n bigbang | awk '{ print $1 }'`
do
    echo -e '\n☸️ reconciling hr:' $hr
    flux reconcile hr $hr -n bigbang --with-source
done
```
  
All services in the cluster should once again be reachable.  

### Other Resources
  
- [Diagnostic Tools for Istio](https://istio.io/latest/docs/ops/diagnostic-tools)
- [Troubleshooting tips](https://github.com/istio/istio/wiki/Troubleshooting-Istio)
