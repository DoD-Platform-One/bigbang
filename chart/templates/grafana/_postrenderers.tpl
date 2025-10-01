{{- define "grafana.serviceMonitorPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/endpoints/0/enableHttp2
            value: false
        target:
          kind: ServiceMonitor
          name: monitoring-grafana
{{- end }}