{{- define "gitlab.serviceMonitorPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/fallbackScrapeProtocol
            value: PrometheusText1.0.0
        target:
          kind: ServiceMonitor
          name: gitlab-gitlab-exporter
{{- end }}
