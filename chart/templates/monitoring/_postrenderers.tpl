{{- define "monitoring.operatorServiceMonitorPostRenderer" }}
- kustomize:
    patches:
      - target:
          kind: ServiceMonitor
          labelSelector: "app.kubernetes.io/name=kube-prometheus-stack-prometheus-operator,app.kubernetes.io/component=prometheus-operator"
          namespace: {{ .Values.namespace | default "monitoring" }}
        patch: |-
          - op: replace
            path: /spec/endpoints/0/scheme
            value: https
          - op: replace
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
{{- end }}