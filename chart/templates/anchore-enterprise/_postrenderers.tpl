{{- define "anchore-enterprise.addAppProtocol" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/0/appProtocol
            value: "http"
        target:
          kind: Service
          name: "anchore-enterprise-anchore-enterprise-.*"
{{- end }}
