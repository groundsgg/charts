{{/*
Returns the env block for the game-server container, picking the right
velocity-secret env-var name based on `.Values.kind`.
*/}}
{{- define "grounds-gamemode.env" -}}
{{- $secretEnvName := "" -}}
{{- if eq .Values.kind "lobby" -}}
{{- $secretEnvName = "GROUNDS_LOBBY_VELOCITY_SECRET" -}}
{{- else -}}
{{- $secretEnvName = "PAPER_VELOCITY_SECRET" -}}
{{- end -}}
- name: {{ $secretEnvName }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.forwardingSecret.name }}
      key: {{ .Values.forwardingSecret.key }}
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
