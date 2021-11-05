# Big Bang GitOps Engines

## Management of Big Bang

Big Bang will be deployed and managed with [Flux 2](https://github.com/fluxcd/flux2) and provide [Argo](https://github.com/argoproj/argo-cd/) for application developers to use for managing custom applications built on a Big Bang cluster.  Big Bang will **not** advocate for use of Flux by mission app owners.  

### Big Bang and Flux

Big Bang is composed of several Open Source and licensed products.  [Helm](https://helm.sh/), as a member of the [CNCF](https://www.cncf.io/), is the de facto standard for packaging applications for Kubernetes.  As a result, several vendors support the release of their product **as helm charts** and have built their packaging and lifecycle management to expect to be the engine for driving that management.  As a result, Big Bang has adopted Helm as its internal deployment framework for Big Bang packages and requires Helm to be treated as a first class citizen.

The Flux2 Engine has native Helm support, meaning the controller deployed as part of "Flux 2" leverages the same Helm code as the CLI.

### Limitations of Argo

#### Helm Support

Argo, has taken the ownership of rendering and managing the lifecycle of applications that does not work exactly as expected by helm. As a result, there are several vendor Helm Charts that **do not deploy successfully** with Argo because of how Argo shims Helm Hooks to Argo specific sync phases.

* GitLab initial secret creation is performed via a [subchart]([https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/charts/shared-secrets](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/charts/shared-secrets))
* Kube Prometheus Stack - [prometheusrule admission webhook]([https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#prometheusrules-admission-webhooks](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#prometheusrules-admission-webhooks)) is created via a helm `install` hook
* Confluent - A deletion hook is part of a subchart gets run at different point in the lifecycle

As new features of Helm get developed and leveraged by the community, we would need to lean on the time and availability of the Argo developers to re-implement the capabilities.

#### App of App Pattern and Secrets

Argo requires all configuration options to be embedded into the ApplicationCR.  Because of this, sensitive values that need to be passed into "inner" packages are forced to reside in the Custom Resource rather than referenced as a Secret.

## Argo Is Still A Package

As defined in the list of [Big Bang Packages](BigBangPackages.md), Big Bang comes deployed with Argo for use by Mission applications to continue to deploy and manage their applications.  Similarly, even though Big Bang uses Helm internally for management of Big Bang packages, Big Bang does not advocate for Helm for use by applications run on clusters with Big Bang.
