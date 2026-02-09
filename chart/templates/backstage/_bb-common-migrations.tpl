{{- define "bigbang.backstage.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
        {{- if not (eq .Values.networkPolicies.controlPlaneCidr .Values.networkPolicies.vpcCidr) }}
        {{- if not (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
        - ipBlock:
            cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
        {{- end }}

routes:
  inbound:
    backstage:
      enabled: {{ dig "istio" "backstage" "enabled" true .Values.addons.backstage.values }}
      {{- $hosts := dig "istio" "backstage" "hosts" list .Values.addons.backstage.values }}
      hosts:
      {{- if $hosts }}
      {{- $hosts | toYaml | nindent 8 }}
      {{- else }}
      - backstage.{{ .Values.domain }}
      {{- end }}
      gateways:
      {{- $gateways := dig "istio" "backstage" "gateways" list .Values.addons.backstage.values }}
      {{- if $gateways }}
      {{- $gateways | toYaml | nindent 8 }}
      {{- else }}
      - {{ include "getGatewayName" (dict "gateway" .Values.addons.backstage.ingress.gateway "root" .) }}
      {{- end }}
{{- end }}
