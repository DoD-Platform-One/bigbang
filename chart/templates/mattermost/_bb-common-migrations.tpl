{{- define "bigbang.mattermost.bb-common-migrations" }}
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
    chat:
      enabled: {{ dig "istio" "chat" "enabled" true .Values.addons.mattermost.values }}
      {{- $hosts := dig "istio" "chat" "hosts" list .Values.addons.mattermost.values }}
      hosts:
      {{- if $hosts }}
      {{- $hosts | toYaml | nindent 8 }}
      {{- else }}
      - chat.{{ .Values.domain }}
      {{- end }}
      gateways:
      {{- $gateways := dig "istio" "chat" "gateways" list .Values.addons.mattermost.values }}
      {{- if $gateways }}
      {{- $gateways | toYaml | nindent 8 }}
      {{- else }}
      - {{ include "getGatewayName" (dict "gateway" .Values.addons.mattermost.ingress.gateway "root" .) }}
      {{- end }}
{{- end }}
