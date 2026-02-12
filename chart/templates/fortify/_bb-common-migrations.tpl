{{- define "bigbang.fortify.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
routes:
  inbound:
    fortify:
      enabled: {{ dig "istio" "fortify" "enabled" true .Values.addons.fortify.values }}
      {{- $fortifyGateways := dig "istio" "fortify" "gateways" list .Values.addons.fortify.values }}
      {{- if $fortifyGateways }}
      gateways:
      {{- range $fortifyGateways }}
      - {{ . }}
      {{- end }}
      {{- end }}
      {{- $fortifyHosts := dig "istio" "fortify" "hosts" list .Values.addons.fortify.values }}
      {{- if $fortifyHosts }}
      hosts:
      {{- range $fortifyHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- end }}
{{- end }}
