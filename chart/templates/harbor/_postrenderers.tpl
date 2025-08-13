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