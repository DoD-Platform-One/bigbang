{{- define "externalSecrets.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/0/appProtocol
            value: https
        target:
          kind: Service
          name: external-secrets-webhook
{{- end }}