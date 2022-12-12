# Neuvector

## Overview

[NeuVector](https://neuvector.com/) is an open-source, full lifecycle container security platform. This includes vulnerability scanning (both in pipelines and in live production clusters), network visibility, compliance tracking and much more. [NeuVector core helm chart](https://github.com/neuvector/neuvector-helm/tree/master/charts/core)

[NeuVector Architecture](https://open-docs.neuvector.com/basics/overview#architecture)

## Big Bang Touchpoints

### UI

The Neuvector UI runs on the manager, a simple pod that providesis the primary way of accessing and managing Neuvector. The UI is accessible via a web application on the cluster at the DNS name "neuvector" (e.g. neuvector.bigbang.dev/). UI access is exposed through the Istio Virtual Service. For more information, see [Using the Neuvector UI](https://open-docs.neuvector.com/navigation/navigation).

### Dependency Packages

When deploying BigBang, neuvector depends on monitoring, gatekeeper/kyverno, and istio being installed prior.

```yaml
  {{- if or .Values.gatekeeper.enabled .Values.istio.enabled .Values.kyvernopolicies.enabled .Values.monitoring.enabled }}
  dependsOn:
    {{- if .Values.gatekeeper.enabled }}
    - name: gatekeeper
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.istio.enabled }}
    - name: istio
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.kyvernopolicies.enabled }}
    - name: kyvernopolicies
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if .Values.monitoring.enabled }}
    - name: monitoring
      namespace: {{ .Release.Namespace }}
    {{- end }}
  {{- end }}
```


