{{- define "bigbang.kyverno-reporter.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        {{- if or (eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0") (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
          - ipBlock:
              cidr: "0.0.0.0/0"
              except:
              - 169.254.169.254/32
        {{- else }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
    from:
      kyverno-reporter:
        podSelector:
          matchLabels:
            app.kubernetes.io/instance: kyverno-reporter-kyverno-reporter
        to:
          definition:
            kubeAPI: true
{{- end }}