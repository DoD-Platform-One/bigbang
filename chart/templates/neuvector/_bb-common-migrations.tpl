{{- define "bigbang.neuvector.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
{{- if empty .Values.networkPolicies.egress.definitions.kubeAPI }}
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
{{- end }}
{{- end }}
