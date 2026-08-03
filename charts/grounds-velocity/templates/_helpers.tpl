
{{/*
The hostnames mc-router should route to this proxy.

Built here rather than written out per cluster. Every name is derivable from
what the region already knows about itself, and a hand-maintained list is how
`/region` silently broke: the continent entry point resolved and reached the
node, then mc-router dropped the handshake because nobody had added the name.

Six names, and they answer different questions:
  <env>.<publicDomain>            what a player types
  <env>.geo.<domain>              the same, latency-steered (the SRV target)
  <continent>.geo.<domain>        "this continent, not the nearest one" — where
                                  /region sends a player, written by the region
                                  itself
  <continent>.<env>.<publicDomain>    the continent entry point on the public
                                  domain (eu.stage.grounds.gg) — core writes
                                  this record with its SRV in the Cloudflare
                                  zone; without the route here it resolves,
                                  reaches the node, and mc-router drops it
  <continent>.<env>.geo.<domain>  the same on the geo domain
                                  (eu.stage.geo.grnds.io)
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
{{- if and $g.continent $g.environment $g.publicDomain -}}
{{- $names = append $names (printf "%s.%s.%s" $g.continent $g.environment $g.publicDomain) -}}
{{- end -}}
{{- if and $g.continent $g.environment $g.domain -}}
{{- $names = append $names (printf "%s.%s.geo.%s" $g.continent $g.environment $g.domain) -}}
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

{{/*
What makes the satellite's metrics agent scrape this pod. The agent discovers by
`prometheus.io/scrape` and then keeps only the target whose declared container
port equals the annotation's — so these two go together or neither works, which
is why one helper emits the annotations and the sibling emits the port.
*/}}
{{- define "grounds-velocity.metricsAnnotations" -}}
{{- if .Values.metrics.enabled -}}
{{- include "grounds-velocity.validateMetricsPort" . -}}
prometheus.io/scrape: "true"
prometheus.io/port: {{ .Values.metrics.port | quote }}
prometheus.io/path: {{ .Values.metrics.path | quote }}
{{- end -}}
{{- end -}}

{{- define "grounds-velocity.metricsPort" -}}
{{- if .Values.metrics.enabled -}}
{{- include "grounds-velocity.validateMetricsPort" . -}}
- name: metrics
  containerPort: {{ .Values.metrics.port }}
  protocol: TCP
{{- end -}}
{{- end -}}

{{/*
One port cannot serve both. Left to the plugin this surfaces as a bind failure
saying "Address already in use", which names neither setting — and the proxy
would carry on serving Minecraft, so nothing else would look wrong either.
*/}}
{{- define "grounds-velocity.validateMetricsPort" -}}
{{- if eq (int .Values.metrics.port) (int .Values.ports.minecraft) -}}
{{- fail (printf "metrics.port (%v) must differ from ports.minecraft (%v)" .Values.metrics.port .Values.ports.minecraft) -}}
{{- end -}}
{{- end -}}
