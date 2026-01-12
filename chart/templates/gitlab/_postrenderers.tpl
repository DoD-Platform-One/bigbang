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
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true  
          - op: replace
            path: /spec/endpoints/0/scheme
            value: https
        target:
          kind: ServiceMonitor
          name: gitlab-redis
{{- end }}
