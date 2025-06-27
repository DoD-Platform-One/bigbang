{{- define "keycloak.mtlsServiceMonitorPostrenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
        target:
          kind: ServiceMonitor
          name: .* # all ServiceMonitors
{{- end }}
{{- define "keycloak.istioHAPostRenderers" -}}
- kustomize:
    patches:
    - patch: |
        - op: add
          path: /spec/ports/-
          value:
            name: jgroups
            port: 7800
            protocol: TCP
            targetPort: 7800
        - op: add
          path: /spec/ports/-
          value:
            name: jgroups-fd
            port: 57800
            protocol: TCP
            targetPort: 57800
      target:
        kind: Service
        name: keycloak.*headless
{{- end -}}
