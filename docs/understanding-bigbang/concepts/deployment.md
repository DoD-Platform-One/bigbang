# Big Bang Deployment

[[_TOC_]]

## GitOps

Big Bang follows a [GitOps](https://www.weave.works/blog/what-is-gitops-really) approach to deployment.  All configuration changes will be pulled and reconciled with what is stored in the Git repository.  The only exception to this is the initial manifests (e.g. `dev.yaml`) which points to the Git repository and path.

## Installation

1. Before pushing changes to Git, validate all configuration is syntactically correct.

   ```shell
   # If everything is successful, YAML should be output
   kustomize build ./dev
   ```

1. If you have not already done so, push configuration changes to Git

   ```shell
   git push
   ```

1. Validate the Kubernetes context is correct

   ```shell
   # This should match the environment you intend to deploy
   kubectl config current-context
   ```

1. Deploy the Big Bang manifest to the cluster

   ```shell
   kubectl apply -f dev.yaml
   ```

1. [Monitor the deployment](#monitor)

## Upgrade

All changes to the Big Bang cluster should be made through Git.  After changes are pushed, Big Bang will automatically reconcile the difference with the cluster.

> It may take Big Bang up to 10 minutes to recognize your changes and start to deploy them.  This is based on the `interval` value set for polling.  You can force Big Bang to immediately check for changes by running the [sync.sh](../scripts/sync.sh) script.

Changes to values can be tested in each environment using the named folders to override values and/or point to specific repo branches or tags.  After testing, the changes can be placed into the `./base` folder if the change is shared between all environments.

## Monitor

The following commands will help you monitor the progress of the Big Bang deployment.  Review the [flowchart](./overview.md#Diagram), if needed, to understand the progression.  Use the [Troubleshooting Guide](./troubleshooting.md) if you have failures.

1. Verify Flux is running

   ```shell
   kubectl get deploy -n flux-system

   # All resources should be in the 'Ready' state
    NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
    source-controller         1/1     1            1           106s
    kustomize-controller      1/1     1            1           106s
    notification-controller   1/1     1            1           105s
    helm-controller           1/1     1            1           106s
   ```

1. Verify the environment was pulled from the Git repo

   ```shell
   kubectl get gitrepository -A

   # `environment-repo`: STATUS should be True
    NAMESPACE   NAME               URL                                                                     READY   STATUS                                                                      AGE
    bigbang     environment-repo   https://repo1.dso.mil/platform-one/big-bang/customers/template.git      True    Fetched revision: main/185e252f4452d897531ab0314adc7a189562be31       2m7s
   ```

1. Verify the environment Kustomization properly worked

   ```shell
   kubectl get kustomizations -A

   # `environment`: READY should be True
    NAMESPACE   NAME          READY   STATUS                                                                    AGE
    bigbang     environment   True    Applied revision: main/185e252f4452d897531ab0314adc7a189562be31     6m41s
   ```

1. Verify the ConfigMaps were deployed

   ```shell
   kubectl get configmap -l kustomize.toolkit.fluxcd.io/namespace -A

   # 'common' and 'environment' should exist
    NAMESPACE   NAME                          DATA   AGE
    bigbang     common-cch6942dk9             1      19m
    bigbang     environment-d2tgb27f56        1      19m
   ```

1. Verify the Secrets were deployed

   ```shell
   kubectl get secrets -l kustomize.toolkit.fluxcd.io/namespace -A

   # 'common-bb' and 'environment-bb' should exist
    NAMESPACE   NAME                        TYPE     DATA   AGE
    bigbang     common-bb-kc5t8dbdfh        Opaque   1      18m
    bigbang     environment-bb-mhddkt46bd   Opaque   1      18m
   ```

1. Verify the Big Bang Helm Chart was pulled

   ```shell
   kubectl get gitrepositories -A

   # 'bigbang' READY should be True
    NAME            URL                                                        READY   STATUS                                                                      AGE
    bigbang         https://repo1.dso.mil/platform-one/big-bang/bigbang.git   True    Fetched revision: master/8a4a1ddd0c9edf316f5362680cf2921baf0c3451   25m
   ```

1. Verify the Big Bang Helm Chart was deployed

   ```shell
   kubectl get hr -A

   # 'bigbang' READY should be True
    NAMESPACE   NAME             READY   STATUS                             AGE
    bigbang     bigbang    True    Release reconciliation succeeded   28m
   ```

1. Verify Big Bang package Helm charts are pulled

   ```shell
   kubectl get gitrepository -A

   # The Git repository holding the Helm charts for each package can be seen in the URL column.
   # The STATUS column shows the branch and tag of the revision being used.
    NAMESPACE     NAME              URL                                                                             READY   STATUS                                                                      AGE
    bigbang       bigbang           https://repo1.dso.mil/platform-one/big-bang/bigbang.git                        True    Fetched revision: master/3a44686520152e576a8c2c6f264876efff497c4b           8m25s
    bigbang       logging           https://repo1.dso.mil/platform-one/big-bang/apps/core/logging.git               True    Fetched revision: release-v0.2.x/9cfe1e14c12098464ee89eb877614f781cd78fb7   8m23s
    bigbang       certmanager       https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/cert-manager.git       True    Fetched revision: release-v1.0.x/1247135baf145dcfad4a4a02ef679c48fb76d9fb   8m23s
    bigbang       istio             https://repo1.dso.mil/platform-one/big-bang/apps/core/servicemesh.git           True    Fetched revision: chart-release/2b02a51b7950ce21bac26403fa25d09e7e3f86c3    8m23s
    bigbang       twistlock         https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock.git   True    Fetched revision: chart-release/faf038197291915713e0f213a4e35991e72f73f6    8m23s
    bigbang       gatekeeper        https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git                True    Fetched revision: chart-release/1a5f32c8e7f672c3b5937b604e5f38eaa08ce246    8m23s
    bigbang       monitoring        https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring.git            True    Fetched revision: release-v0.2.x/ca60bedcc106b95beb0bf9ccdc6e0e759e6fd6bf   8m23s
    bigbang       cluster-auditor   https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor.git       True    Fetched revision: chart-release/598c35670db0cbdb3a48063b2d558965afe73185    8m23s
   ```

1. Verify the packages get deployed

   ```shell
   # Use watch since it take a long time to deploy
   watch kubectl get hr,deployments,po -A

   # Flux will not attempt to deploy a package until its dependencies are ready
   # All Helm Release resources and Pods
    Every 2.0s: kubectl get hr,deployments,po -A                                                                            localhost: Mon Nov  9 10:14:56 2020

    NAMESPACE     NAME                                                          READY    STATUS                                                 AGE
    bigbang       helmrelease.helm.toolkit.fluxcd.io/bigbang                    True     Release reconciliation succeeded                       64s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/gatekeeper                 True     Release reconciliation succeeded                       62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/eck-operator               False    dependency 'bigbang/gatekeeper' is not ready           62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/istio-operator             Unknown  Reconciliation in progress                             62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/istio                      False    dependency 'bigbang/istio-operator' is not ready       62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/efk                        False    dependency 'bigbang/eck-operator' is not ready         62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/logging-operator           False    dependency 'bigbang/gatekeeper' is not ready           62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/twistlock                  False    dependency 'bigbang/gatekeeper' is not ready           62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/cluster-auditor-policies   False    dependency 'bigbang/gatekeeper' is not ready           62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/cluster-auditor            False    dependency 'bigbang/gatekeeper' is not ready           62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/certmanager                True     Release reconciliation succeeded                       62s
    bigbang       helmrelease.helm.toolkit.fluxcd.io/monitoring                 False    dependency 'bigbang/gatekeeper' is not ready           62s

    NAMESPACE           NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
    kube-system         deployment.apps/local-path-provisioner          1/1     1            1           4m48s
    kube-system         deployment.apps/coredns                         1/1     1            1           4m48s
    flux-system         deployment.apps/helm-controller                 1/1     1            1           4m6s
    flux-system         deployment.apps/notification-controller         1/1     1            1           4m6s
    flux-system         deployment.apps/source-controller               1/1     1            1           4m7s
    flux-system         deployment.apps/kustomize-controller            1/1     1            1           4m7s
    gatekeeper-system   deployment.apps/gatekeeper-controller-manager   1/1     1            1           2m8s
    gatekeeper-system   deployment.apps/gatekeeper-audit                1/1     1            1           2m8s
    istio-operator      deployment.apps/istio-operator                  0/1     1            0           8s

    NAMESPACE           NAME                                                 READY   STATUS              RESTARTS   AGE
    kube-system         pod/local-path-provisioner-6d59f47c7-s6rln           1/1     Running             0          4m36s
    kube-system         pod/coredns-7944c66d8d-flk4p                         1/1     Running             0          4m36s
    flux-system         pod/helm-controller-578cdbcd8b-tjzs7                 1/1     Running             0          4m6s
    flux-system         pod/notification-controller-7c59d85f77-92ckv         1/1     Running             0          4m6s
    flux-system         pod/source-controller-7d6f889df9-f888j               1/1     Running             0          4m7s
    flux-system         pod/kustomize-controller-5cfb78859c-n85xn            1/1     Running             0          4m6s
    gatekeeper-system   pod/gatekeeper-controller-manager-5b9cf6c85d-cqd8t   1/1     Running             0          2m8s
    gatekeeper-system   pod/gatekeeper-audit-7db49c54d5-pwzwh                1/1     Running             0          2m8s
    istio-operator      pod/istio-operator-79f966cfc-rjhhc                   0/1     ContainerCreating   0          8s
   ```

1. Wait until all Helm Releases, Deployments, and Pods are Ready.  Be patient, this can take 15-30 minutes.

> The Git repositories are monitored periodically (default is 10m) for changes.  If a change is detected, the configuration will be reconciled using Flux.  The monitoring techniques above can be used to monitor the reconciliation.
