{{- define "bigbang.sonarqube.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

{{- $plugins := dig "upstream" "plugins" "install" (list) .Values.addons.sonarqube.values }}
{{- $pluginsExist := not (empty $plugins) }}
{{- $egressHttpsEnabled := dig "networkPolicies" "allowEgress" "enabled" true .Values.addons.sonarqube.values }}

routes:
  outbound:
    sonarqube-marketplace:
      enabled: {{ or $pluginsExist $egressHttpsEnabled }}
      hosts:
      - github.com
      - release-assets.githubusercontent.com
      - downloads.sonarsource.com

networkPolicies:
  egress:
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
    from:
      sonarqube:
        podSelector:
          matchLabels:
            app: sonarqube
        to:
          definition:
            sonarsource-marketplace: {{ or $egressHttpsEnabled $pluginsExist }}
            code-repository: {{ $egressHttpsEnabled }}
{{- end }}
