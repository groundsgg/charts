
{{/*
The hostnames mc-router should route to this proxy.

Built here rather than written out per cluster. Every name is derivable from
what the region already knows about itself, and a hand-maintained list is how
`/region` silently broke: the continent entry point resolved and reached the
node, then mc-router dropped the handshake because nobody had added the name.

Four names, and they answer different questions:
  <env>.<publicDomain>            what a player types
  <env>.geo.<domain>              the same, latency-steered (the SRV target)
  <continent>.geo.<domain>        "this continent, not the nearest one" — where
                                  /region sends a player, written by the region
                                  itself
  <release>.<region>.<env>.<domain>   one specific proxy, for multi-proxy testing

Each is emitted only when its inputs are set, so a single-region or local
install renders a shorter list rather than a broken one.
*/}}
{{- define "grounds-velocity.mcRouterNames" -}}
{{- $g := .Values.global -}}
{{- $names := list -}}
{{- if and $g.environment $g.publicDomain -}}
{{- $names = append $names (printf "%s.%s" $g.environment $g.publicDomain) -}}
{{- end -}}
{{- if and $g.environment $g.domain -}}
{{- $names = append $names (printf "%s.geo.%s" $g.environment $g.domain) -}}
{{- end -}}
{{- if and $g.continent $g.domain -}}
{{- $names = append $names (printf "%s.geo.%s" $g.continent $g.domain) -}}
{{- end -}}
{{- if and $g.region $g.environment $g.domain -}}
{{- $names = append $names (printf "%s.%s.%s.%s" .Release.Name $g.region $g.environment $g.domain) -}}
{{- end -}}
{{- join "," $names -}}
{{- end -}}

{{- define "grounds-velocity.serviceAccountName" -}}
{{- .Values.serviceAccount.name | default .Release.Name -}}
{{- end -}}

{{- define "grounds-velocity.permissionsRbacName" -}}
{{- $hash := printf "%s/%s" .Release.Namespace .Release.Name | sha256sum | trunc 8 -}}
{{- $base := printf "grounds-permissions-%s" .Release.Name -}}
{{- $prefix := $base | trunc (int (sub 63 (add (len $hash) 1))) | trimSuffix "-" -}}
{{- printf "%s-%s" $prefix $hash -}}
{{- end -}}
