{{- define "harbor.fixRegistryPostRender" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/ports/0
            value:
              name: registry
              port: 5000
        target:
          kind: Service
          name: harbor-registry
{{- end }}
{{- define "harbor.ServiceMonitorPostRenderer" }}
- kustomize:
    patches:
      - target:
          kind: ServiceMonitor
          name: harbor
          namespace: harbor
        patch: |-
          - op: add
            path: /spec/endpoints/0/scheme
            value: https
          - op: add
            path: /spec/endpoints/0/tlsConfig
            value:     
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
{{- end }}