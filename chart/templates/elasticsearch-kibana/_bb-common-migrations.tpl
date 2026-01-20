{{- define "bigbang.elasticsearchKibana.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- if empty .Values.networkPolicies.egress.definitions.kubeAPI }}
networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
{{- end }}

routes:
  inbound:
    kibana:
      enabled: {{ dig "istio" "kibana" "enabled" true .Values.elasticsearchKibana.values }}
      {{- $kibanaHosts := dig "istio" "kibana" "hosts" list .Values.elasticsearchKibana.values }}
      {{- if $kibanaHosts }}
      hosts:
      {{- range $kibanaHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - kibana.{{ .Values.domain }}
      {{- end }}
      gateways:
      - {{ include "getGatewayName" (dict "gateway" .Values.elasticsearchKibana.ingress.gateway "root" .)}}
    elasticsearch:
      enabled: {{ dig "istio" "elasticsearch" "enabled" false .Values.elasticsearchKibana.values }}
      {{- $elasticsearchHosts := dig "istio" "elasticsearch" "hosts" list .Values.elasticsearchKibana.values }}
      {{- if $elasticsearchHosts }}
      hosts:
      {{- range $elasticsearchHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - elasticsearch.{{ .Values.domain }}
      {{- end }}
      gateways:
      - {{ include "getGatewayName" (dict "gateway" .Values.elasticsearchKibana.ingress.gateway "root" .)}}
{{- end }}
