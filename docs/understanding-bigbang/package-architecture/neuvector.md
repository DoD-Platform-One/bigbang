# NeuVector

## Overview

[NeuVector](https://neuvector.com/) is an open-source, full lifecycle container security platform. This includes vulnerability scanning (both in pipelines and in live production clusters), network visibility, compliance tracking and much more. [NeuVector core helm chart](https://github.com/neuvector/neuvector-helm/tree/master/charts/core)

[NeuVector Architecture](https://open-docs.neuvector.com/basics/overview#architecture)

## Big Bang Touchpoints

### UI

The Neuvector UI runs on the manager, a simple pod that provides the primary way of accessing and managing NeuVector. The UI is accessible via a web application on the cluster at the DNS name "neuvector" (e.g. neuvector.bigbang.dev/). UI access is exposed through the Istio Virtual Service. For more information, see [Using the NeuVector UI](https://open-docs.neuvector.com/navigation/navigation).

### Dependency Packages

When deploying BigBang, neuvector depends on monitoring, gatekeeper/kyverno, and istio being installed prior.

```yaml
  {{- if or .Values.gatekeeper.enabled .Values.istio.enabled .Values.kyvernoPolicies.enabled .Values.monitoring.enabled }}
  dependsOn:
    {{- if .Values.gatekeeper.enabled }}
    - name: gatekeeper
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.istio.enabled }}
    - name: istio
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.kyvernoPolicies.enabled }}
    - name: kyverno-policies
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.monitoring.enabled }}
    - name: monitoring
      namespace: {{ .Release.Namespace }}
    {{- end }}
  {{- end }}
```

## High Availability

NeuVector provides High Availability for the controller and scanner deployments with `3` replicas and a default `podAntiAffinity` in order to attempt installation of replicas to separate nodes if possible. These can be modified by providing new values to `controller.replicas` and `scanner.replicas` accordingly. 

```yaml
neuvector:
  values:
    controller:
      replicas: 3

    scanner:
      replicas: 3
```

The enforcer pods are part of a daemonset that will be based upon the number of cluster nodes - with default tolerations for standard control-plane taints. Addition tolerations can be set for nodes by appending to the existing set:

**Note:** The controller, manager, and cve.scanner deployments can also have their tolerations updated by mirroring this process. 

```yaml
neuvector:
  values:
    enforcer: # controller, manager, cve.scanner also have tolerations
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
        - effect: NoSchedule
          key: node-role.kubernetes.io/control-plane
        - effect: NoSchedule
          key: custom-example-taint
```

The manager deployment houses the Security Center Admin Console and is explicitly set to `1` replica and cannot be scaled. 
