{{/*
Which server binary this release runs, and therefore which forwarding env-vars
it reads. Explicit `.Values.engine` wins; otherwise it is inferred from `kind`
so existing releases keep exactly the behaviour they had (lobby was the only
Minestom kind).

The inference is the reason this exists: `kind` used to decide both the engine
AND the role, so a Minestom *game* had no correct value — `game` handed it
Paper's variable, and `lobby` gave it the right variables but labelled it a
lobby, which is what Velocity routes players to directly.
*/}}
{{- define "grounds-gamemode.engine" -}}
{{- if .Values.engine -}}
{{- .Values.engine -}}
{{- else if eq .Values.kind "lobby" -}}
minestom
{{- else -}}
paper
{{- end -}}
{{- end -}}

{{/*
Returns the env block for the game-server container, picking the right
Velocity forwarding env-vars for the engine.
*/}}
{{- define "grounds-gamemode.env" -}}
{{- if eq (include "grounds-gamemode.engine" .) "minestom" -}}
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
{{- with .Values.global.region }}
- name: REGION
  value: {{ . | quote }}
{{- end }}
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

{{/*
The Fleet's name, region-qualified when the cluster declares one.

Every region runs a release called `lobby`, so an unqualified Fleet produces
GameServers called `lobby-<hash>` everywhere — and those names are what a player
sees in /server and an operator sees in /agones. The suffix is what makes
"which lobby" answerable without also knowing which cluster you were looking at.

Note this is the *name*, not the source of truth for a player's region: that
travels in their session. A name is for reading, not for parsing.
*/}}
{{- define "grounds-gamemode.fleetName" -}}
{{- with .Values.global.region -}}
{{ $.Release.Name }}-{{ . }}
{{- else -}}
{{ $.Release.Name }}
{{- end -}}
{{- end -}}
