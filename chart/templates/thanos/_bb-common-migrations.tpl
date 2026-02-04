{{- define "bigbang.thanos.bb-common-migrations" -}}
{{- $thanos := .Values.addons.thanos }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- $storeGatewayEnabled := dig "storegateway" "enabled" false $thanos }}
{{- $storeGatewayEnabled = or $storeGatewayEnabled (not (empty $thanos.objectStorage.endpoint)) }}
{{- $storeGatewayEgressCidr := dig "storegateway" "egress" "cidr" "" $thanos }}
{{- $minioEnabled := dig "minio" "enabled" false $thanos }}

routes:
  inbound:
    query-frontend:
      gateways:
      - {{ include "getGatewayName" (dict "gateway" (.Values.addons.thanos.ingress.gateway | default "public") "root" .)}}
      {{- $thanosHosts := dig "istio" "thanos" "hosts" list .Values.addons.thanos.values }}
      {{- if $thanosHosts }}
      hosts:
      {{- range $thanosHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - thanos.{{ .Values.domain }}
      {{- end }}
    minio:
      gateways:
      - {{ include "getGatewayName" (dict "gateway" (.Values.addons.thanos.ingress.gateway | default "public") "root" .)}}

networkPolicies:
  egress:
    {{- if empty (dig "egress" "definitions" "kubeAPI" nil .Values.networkPolicies) }}
    {{- if empty .Values.networkPolicies.egress.definitions.kubeAPI }}
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
    from:
      {{- if and $storeGatewayEnabled (not $minioEnabled) }}
      thanos-storegateway:
        to:
          {{- if empty $storeGatewayEgressCidr }}
          definition:
            storage-subnets: true
          {{- else }}
          cidr:
            {{ $storeGatewayEgressCidr }}: true
          {{- end }}
      {{- end }}

{{- end }}
