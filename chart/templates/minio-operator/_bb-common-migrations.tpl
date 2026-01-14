{{- define "bigbang.minio-operator.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- if empty (dig "egress" "definitions" "kubeAPI" nil .Values.networkPolicies) }}
networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
          - ipBlock:
              cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
{{- end }}
{{- end }}
