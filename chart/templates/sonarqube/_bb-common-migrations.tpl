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