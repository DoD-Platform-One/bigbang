{{- define "mimir.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: tcp
        target:
          kind: Service
          name: .*-headless$
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: grpc
        target:
          kind: Service
          name: ^.+-(?:alertmanager|compactor|distributor|ingester(-zone.*)?|overrides-exporter|querier|query-frontend|store-gateway(-zone.*))$
      - patch: |
          - op: add
            path: /spec/template/metadata/labels/app.kubernetes.io~1part-of
            value: memberlist
        target:
          kind: Deployment
          name: ^.+-query-frontend$
      - patch: |
          - op: add
            path: /spec/template/spec/containers/0/ports/-
            value:
              containerPort: 7946
              name: memberlist
              protocol: TCP
        target:
          kind: Deployment
          name: ^.+-query-frontend$
{{- if eq (include "metricsSidecarMtls" (list .Values.addons.mimir .)) "true" }}
      - patch: |
          - op: add
            path: /spec/endpoints/0/enableHttp2
            value: false
        target:
          kind: ServiceMonitor
          name: ^.+-query-frontend$
{{- end }}
{{- end }}