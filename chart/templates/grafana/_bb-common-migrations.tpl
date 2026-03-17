{{- define "bigbang.grafana.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

{{- $domainName := default .Values.domain .Values.hostname }}

routes:
  inbound:
    grafana:
      gateways:
      - {{ include "getGatewayName" (dict "gateway" .Values.grafana.ingress.gateway "root" .) }}
      {{- $grafanaHosts := dig "istio" "grafana" "hosts" list .Values.grafana.values }}
      {{- if $grafanaHosts }}
      hosts:
      {{- range $grafanaHosts }}
      - {{ tpl . $ | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - grafana.{{ $domainName }}
      {{- end }}

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
{{- end }}
