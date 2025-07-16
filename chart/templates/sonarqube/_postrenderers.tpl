{{- define "sonarqube.istioPrometheusPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/-
            value:
              name: monitoring-web
              port: 8000
              protocol: TCP
              targetPort: monitoring-web
          - op: add
            path: /spec/ports/-
            value:
              name: monitoring-ce
              port: 8001
              protocol: TCP
              targetPort: monitoring-ce
        target:
          kind: Service
          name: sonarqube-sonarqube
{{- end }}