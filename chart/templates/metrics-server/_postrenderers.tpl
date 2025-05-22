{{- define "metricsServer.automountServiceAccountTokenPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /automountServiceAccountToken
            value: true
        target:
          kind: ServiceAccount
          name: metrics-server
      - patch: |
          - op: add
            path: /spec/template/spec/automountServiceAccountToken
            value: true
        target:
          kind: Deployment
          name: metrics-server
{{- end }}
