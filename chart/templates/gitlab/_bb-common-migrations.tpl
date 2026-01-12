{{- define "bigbang.gitlab.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}
routes:
  inbound:
    gitlab:
      enabled: {{ dig "istio" "gitlab" "enabled" true .Values.addons.gitlab.values }}
      gateways:
      - {{ include "getGatewayName" (dict "gateway" (.Values.addons.gitlab.ingress.gateway | default "public") "root" .)}}
      {{- $gitlabHosts := dig "istio" "gitlab" "hosts" list .Values.addons.gitlab.values }}
      {{- if $gitlabHosts }}
      hosts:
      {{- range $gitlabHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - gitlab.{{ .Values.domain }}
      {{- end }}
    registry:
      enabled: {{ dig "istio" "registry" "enabled" true .Values.addons.gitlab.values }}
      gateways:
      - {{ include "getGatewayName" (dict "gateway" (.Values.addons.gitlab.ingress.gateway | default "public") "root" .)}}
      {{- $registryHosts := dig "istio" "registry" "hosts" list .Values.addons.gitlab.values }}
      {{- if $registryHosts }}
      hosts:
      {{- range $registryHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      hosts:
      - registry.{{ .Values.domain }}
      {{- end }}
    pages:
      enabled: {{ dig "istio" "pages" "enabled" false .Values.addons.gitlab.values }}
      {{- $pagesGateways := dig "istio" "pages" "gateways" list .Values.addons.gitlab.values }}
      {{- if $pagesGateways }}
      gateways:
      {{- range $pagesGateways }}
      - {{ . }}
      {{- end }}
      {{- end }}
      {{- $pagesHosts := dig "istio" "pages" "hosts" list .Values.addons.gitlab.values }}
      {{- if $pagesHosts }}
      hosts:
      {{- range $pagesHosts }}
      - {{ . | quote }}
      {{- end }}
      {{- end }}
  outbound:
    sso:
      enabled: {{ or .Values.addons.gitlab.sso.enabled (dig "sso" "enabled" false .Values.addons.gitlab.values) }}
      hosts:
      - {{ coalesce (dig "sso" "host" nil .Values.addons.gitlab.values) (include "sso.host" .) }}

{{- $minioEnabled := dig "global" "minio" "enabled" true .Values.addons.gitlab.values }}
{{- $postgresEnabled := dig "upstream" "postgresql" "install" true .Values.addons.gitlab.values }}
{{- $iamProfileUsed := dig "use_iam_profile" false .Values.addons.gitlab.values }}
networkPolicies:
  egress:
    {{- if empty (dig "egress" "definitions" "kubeAPI" nil .Values.networkPolicies) }}
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
    {{- end }}
    from:
      gitaly:
        to:
          cidr:
            0.0.0.0/0:443: {{ dig "networkPolicies" "gitalyEgress" "enabled" false .Values.addons.gitlab.values }}
      migrations:
        to:
          cidr:
            169.254.169.254/32: {{ $iamProfileUsed }}
          definition:
            storage-subnets: {{ not $minioEnabled }}
            database-subnets: {{ not $postgresEnabled }}
      registry:
        to:
          cidr:
            169.254.169.254/32: {{ $iamProfileUsed }}
          definition:
            storage-subnets: {{ not $minioEnabled }}
            database-subnets: {{ not $postgresEnabled }}
      webservice:
        to:
          cidr:
            169.254.169.254/32: {{ $iamProfileUsed }}
          definition:
            storage-subnets: {{ not $minioEnabled }}
            database-subnets: {{ not $postgresEnabled }}
      toolbox:
        to:
          cidr:
            169.254.169.254/32: {{ $iamProfileUsed }}
          definition:
            storage-subnets: {{ not $minioEnabled }}
            database-subnets: {{ not $postgresEnabled }}
      sidekiq:
        to:
          cidr:
            169.254.169.254/32: {{ $iamProfileUsed }}
          definition:
            storage-subnets: {{ not $minioEnabled }}
            database-subnets: {{ not $postgresEnabled }}
{{- end }}
