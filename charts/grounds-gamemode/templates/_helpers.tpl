{{/*
Returns the env block for the game-server container, picking the right
Velocity forwarding env-vars based on `.Values.kind`.
*/}}
{{- define "grounds-gamemode.env" -}}
{{- if eq .Values.kind "lobby" -}}
- name: GROUNDS_PROXY_MODE
  value: velocity
- name: GROUNDS_VELOCITY_FORWARDING_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.forwardingSecret.name }}
      key: {{ .Values.forwardingSecret.key }}
{{- else -}}
- name: PAPER_VELOCITY_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.forwardingSecret.name }}
      key: {{ .Values.forwardingSecret.key }}
{{- end -}}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Resolves the fully-qualified image reference.
*/}}
{{- define "grounds-gamemode.image" -}}
{{- $repo := .Values.image.repository -}}
{{- if .Values.image.registry -}}
{{- $repo = printf "%s/%s" .Values.image.registry .Values.image.repository -}}
{{- end -}}
{{ printf "%s:%s" $repo .Values.image.tag }}
{{- end -}}
