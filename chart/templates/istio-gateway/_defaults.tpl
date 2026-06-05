{{- define "bigbang.defaults.istio-gateway" -}}
gateways:
  public:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          credentialName: public-cert
          mode: SIMPLE

    upstream:
      imagePullPolicy: {{ .Values.imagePullPolicy }}

      {{- include "secretsImagePullSecretsWithName" . | nindent 6 }}

      labels:
        istio: ingressgateway

  passthrough:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH

    upstream:
      imagePullPolicy: {{ .Values.imagePullPolicy }}

      {{- include "secretsImagePullSecretsWithName" . | nindent 6 }}

      labels:
        istio: ingressgateway
{{- end }}