# Appendix D - Big Bang Prerequisites

BigBang is built to work on all the major kubernetes distributions.  However, since distributions differ and may come
configured out the box with settings incompatible with BigBang, this document serves as a checklist of pre-requisites
for any distribution that may need it.

## All Clusters

The following apply as prerequisites for all clusters

* A default `StorageClass` capable of resolving `ReadWriteOnce` `PersistentVolumeClaims` must exist

## OpenShift
1) When deploying BigBang, set the OpenShift flag to true.
```
# inside a values.yaml being passed to the command installing bigbang
openshift: true

# OR inline with helm command
helm install bigbang chart --set openshift=true
```
2) Patch the istio-cni daemonset to allow containers to run privileged (AFTER istio-cni daemonset exists).  
Note: it was unsuccessfully attempted to apply this setting via modifications to the helm chart. Online patching succeeded. 
```
kubectl get daemonset istio-cni-node -n kube-system -o json | jq '.spec.template.spec.containers[] += {"securityContext":{"privileged":true}}' | kubectl replace -f -
```
3) Modify the OpenShift cluster(s) with the following scripts based on https://istio.io/v1.7/docs/setup/platform-setup/openshift/
```
# Istio Openshift configurations Post Install 
oc -n istio-system expose svc/istio-ingressgateway --port=http2
oc adm policy add-scc-to-user privileged -z istio-cni -n kube-system
oc adm policy add-scc-to-group privileged system:serviceaccounts:logging
oc adm policy add-scc-to-group anyuid system:serviceaccounts:logging
oc adm policy add-scc-to-group privileged system:serviceaccounts:monitoring
oc adm policy add-scc-to-group anyuid system:serviceaccounts:monitoring

cat <<\EOF >> NetworkAttachmentDefinition.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF
oc -n logging create -f NetworkAttachmentDefinition.yaml
oc -n monitoring create -f NetworkAttachmentDefinition.yaml
```