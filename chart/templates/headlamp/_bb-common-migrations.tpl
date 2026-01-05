{{- define "bigbang.headlamp.bb-common-migrations" }}
networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}

routes:
  inbound:
    headlamp:
      enabled: {{ dig "istio" "headlamp" "enabled" true .Values.addons.headlamp.values }}
      {{- $hosts := dig "istio" "headlamp" "hosts" list .Values.addons.headlamp.values }}
      hosts:
      {{- if $hosts }}
      {{- $hosts | toYaml | nindent 8 }}
      {{- else }}
      - headlamp.{{ .Values.domain }}
      {{- end }}
      gateways:
      {{- $gateways := dig "istio" "headlamp" "gateways" list .Values.addons.headlamp.values }}
      {{- if $gateways }}
      {{- $gateways | toYaml | nindent 8 }}
      {{- else }}
      - {{ include "getGatewayName" (dict "gateway" .Values.addons.headlamp.ingress.gateway "root" .) }}
      {{- end }}
{{- end }}
