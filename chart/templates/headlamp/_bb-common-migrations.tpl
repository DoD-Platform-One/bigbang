{{- define "bigbang.headlamp.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- if empty .Values.networkPolicies.egress.definitions.kubeAPI }}
networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
            {{- if eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0" }}
            except:
            - 169.254.169.254/32
            {{- end }}
        {{- if not (eq .Values.networkPolicies.controlPlaneCidr .Values.networkPolicies.vpcCidr) }}
        {{- if not (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
        - ipBlock:
            cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
        {{- end }}
{{- end }}

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
