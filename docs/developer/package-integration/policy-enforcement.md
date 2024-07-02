# Policy Enforcement

Big Bang has several policies for Kubernetes resources to ensure best practices and security. For example, images must be pulled from Iron Bank, and containers must be run as non-root. These policies are currently enforced by [Kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno), which replaces OPA Gatekeeper as the primary policy management tool in Big Bang.

When integrating your package, you must adhere to the policies enforced by Kyverno, or your resources will be denied by the Kubernetes admission controller. This document will guide you on how to identify and resolve policy violations using Kyverno.

## Prerequisites

* A K8s cluster with Big Bang installed.
* Cluster admin access to the cluster with [kubectl](https://kubernetes.io/docs/tasks/tools/).

## Integration

### 1. Deploying a Policy Enforcement Tool (Kyverno)

Kyverno is deployed as the first package in the default Big Bang configuration. This set up allows Kyverno to protect the cluster from the start by enforcing policies on all resources. Your package will interact with the cluster under the governance of Kyverno's policy engine.

### 2. Identifying Violations Found on Your Application

In the following section, you will learn how to identify violations found in your package. The app [PodInfo](https://repo1.dso.mil/big-bang/apps/sandbox/podinfo) will be used for all examples. Kyverno provides detailed reports on policy violations. To check for any issues with your package, use the following commands:

To deploy an application like PodInfo and check for violations:

```bash
➜ helm install flux-podinfo chart
Error: INSTALLATION FAILED: 1 error occurred:
        * admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/flux-podinfo was blocked due to the following policies

disallow-root:
  autogen-ensure-non-root: 'validation error: Running as root is not allowed. rule
    autogen-ensure-non-root failed at path /spec/template/spec/containers/0/securityContext/'

```
There was a policy violation, and Kyverno blocked the deployment while providing feedback.

Kyverno’s output is structured to give clear information about which policies were violated and why, making it easy for users to understand the necessary changes to comply with the policy requirements.


### 3. Fixing Policy Violations

Upon identifying the policy violation(s), modify your Kubernetes manifests according to the Kyverno policies. For instance, if a policy requires that no containers run as privileged, you should ensure your deployment manifests respect this rule.


### 4. Exemptions to Policy Exceptions

While fixing the violation in the application is preferred, sometimes an exception to the policy is necessary, allowing the violation to remain.

If you require an exception to a policy, please refer to our [exception doc](https://repo1.dso.mil/big-bang/product/packages/policy/-/blob/main/docs/exceptions.md) for more information.

## Validation

After fixing the violation, we can run `helm upgrade flux-podinfo chart`. We can then check all the events in our cluster. This will show us if we've fixed our policy violation, but will also reveal non-policy related issues.

```bash
➜ helm upgrade flux-podinfo chart
Release "flux-podinfo" has been upgraded. Happy Helming!
NAME: flux-podinfo
LAST DEPLOYED: Mon Apr 08 16:20:36 2024
NAMESPACE: default
STATUS: deployed
REVISION: 3
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl -n default port-forward deploy/flux-podinfo 8080:9898
```
Lastly, run `kubectl get all -n default` to verify that your deployment was successful.

```bash
➜ kubectl get all -n default
NAME                                READY   STATUS    RESTARTS   AGE
pod/flux-podinfo-5976b5c4b9-rtr9b   1/1     Running   0          2m20s

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/flux-podinfo   ClusterIP   10.100.67.167   <none>        9898/TCP,9999/TCP   21m
service/kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP             69m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/flux-podinfo   1/1     1            1           2m20s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/flux-podinfo-5976b5c4b9   1         1         1       2m20s
```
