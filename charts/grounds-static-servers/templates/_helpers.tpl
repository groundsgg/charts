{{- define "grounds-static-servers.validate" -}}
{{- if not (kindIs "map" .Values.servers) -}}
{{- fail "servers must be a map of Velocity names to host:port endpoints" -}}
{{- end -}}
{{- $names := keys .Values.servers | sortAlpha -}}
{{- if eq (len $names) 0 -}}
{{- fail "servers must contain at least one static server" -}}
{{- end -}}
{{- $seen := list -}}
{{- range $name := $names -}}
  {{- if eq (trim $name) "" -}}
    {{- fail "static server name must not be empty" -}}
  {{- end -}}
  {{- $normalizedName := lower $name -}}
  {{- if has $normalizedName $seen -}}
    {{- fail (printf "duplicate static server name (case-insensitive): %s" $name) -}}
  {{- end -}}
  {{- $seen = append $seen $normalizedName -}}
  {{- $endpoint := index $.Values.servers $name -}}
  {{- if not (kindIs "string" $endpoint) -}}
    {{- fail (printf "static server %q endpoint must be a host:port string" $name) -}}
  {{- end -}}
  {{- if not (regexMatch "^[^[:space:]]+:[0-9]+$" $endpoint) -}}
    {{- fail (printf "static server %q endpoint must be a host:port value" $name) -}}
  {{- end -}}
  {{- $port := regexFind "[0-9]+$" $endpoint | int -}}
  {{- if or (lt $port 1) (gt $port 65535) -}}
    {{- fail (printf "static server %q port must be between 1 and 65535" $name) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
