{{- define "fluentbit.podPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/template/spec/containers/0/name
            value: fluent-bit
        target:
          kind: DaemonSet
          name: fluentbit-fluent-bit
          namespace: fluentbit
      - patch: |
          - op: replace
            path: /spec/ports/0/name
            value: tcp-http
        target:
          kind: Service
          name: fluentbit-fluent-bit
          namespace: fluentbit
      {{- if eq (include "metricScrapingEnabled" .) "true" }}
      - patch: |
          - op: replace
            path: /spec/endpoints/0/port
            value: tcp-http
        target:
          kind: ServiceMonitor
          name: fluentbit-fluent-bit
          namespace: monitoring
      {{- end }}
{{- end }}
