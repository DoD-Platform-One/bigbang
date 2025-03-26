{{- define "alloy.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/0/scheme
            value: https
        target:
          kind: ServiceMonitor
          name: ".*alloy-alloy.*"
{{- end }}