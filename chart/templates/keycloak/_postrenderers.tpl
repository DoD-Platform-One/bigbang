{{- define "keycloak.postrenderers.istio-servicemonitor" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/0/scheme
            value: https
        target:
          kind: ServiceMonitor
          name: .*
{{- end }}
