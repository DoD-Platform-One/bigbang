{{- define "bigbang.minio.bb-common-migrations" }}
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
  api:
    enabled: {{ dig "istio" "api" "enabled" true .Values.addons.minio.values }}
    gateways: 
    - {{ include "getGatewayName" (dict "gateway" (.Values.addons.minio.ingress.gateway | default "public") "root" .)}}
    {{- $apiHosts := dig "istio" "api" "hosts" list .Values.addons.minio.values }}
    {{- if $apiHosts }}
    hosts:
    {{- range $apiHosts }}
    - {{ . | quote }}
    {{- end }}
    {{- else }}
    hosts:
    - minio-api.{{ .Values.domain }}
    {{- end }}
  console:
    enabled: {{ dig "istio" "console" "enabled" true .Values.addons.minio.values }}
    gateways:
    - {{ include "getGatewayName" (dict "gateway" (.Values.addons.minio.ingress.gateway | default "public") "root" .)}}
    {{- $consoleHosts := dig "istio" "console" "hosts" list .Values.addons.minio.values }}
    {{- if $consoleHosts }}
    hosts:
    {{- range $consoleHosts }}
    - {{ . | quote }}
    {{- end }}
    {{- else }}
    hosts:
    - minio.{{ .Values.domain }}
    {{- end }}
{{- end }}
