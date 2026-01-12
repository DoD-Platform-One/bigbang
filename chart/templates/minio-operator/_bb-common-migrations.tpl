{{- define "bigbang.minio-operator.bb-common-migrations" }}
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
