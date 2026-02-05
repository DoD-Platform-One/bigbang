{{- define "bigbang.twistlock.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- if or (empty .Values.networkPolicies.egress.definitions.kubeAPI) (empty .Values.networkPolicies.ingress.definitions.nodeCidrs) }}
networkPolicies:
  {{- if empty .Values.networkPolicies.egress.definitions.kubeAPI }}
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
  {{- end }}
  {{- if empty .Values.networkPolicies.ingress.definitions.nodeCidrs }}
  ingress:
    definitions:
      nodeCidrs:
        from:
        {{- if .Values.networkPolicies.nodeCidr }}
        - ipBlock:
            cidr: {{ .Values.networkPolicies.nodeCidr }}
        {{- else }}
        - ipBlock:
            cidr: 10.0.0.0/8
        - ipBlock:
            cidr: 172.16.0.0/12
        - ipBlock:
            cidr: 192.168.0.0/16
        - ipBlock:
            cidr: 100.64.0.0/10
        {{- end }}
  {{- end }}
{{- end }}

routes:
  inbound:
    console:
      enabled: {{ dig "istio" "console" "enabled" true .Values.twistlock.values }}
      {{- $hosts := dig "istio" "console" "hosts" list .Values.twistlock.values }}
      hosts:
      {{- if $hosts }}
      {{- $hosts | toYaml | nindent 8 }}
      {{- else }}
      - twistlock.{{ .Values.domain }}
      {{- end }}
      gateways:
      {{- $gateways := dig "istio" "console" "gateways" list .Values.twistlock.values }}
      {{- if $gateways }}
      {{- $gateways | toYaml | nindent 8 }}
      {{- else }}
      - {{ include "getGatewayName" (dict "gateway" .Values.twistlock.ingress.gateway "root" .) }}
      {{- end }}
{{- end }}
