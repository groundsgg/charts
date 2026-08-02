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
{{- include "grounds-gamemode.validateTokenPaths" . -}}
{{- $groundsToken := .Values.groundsToken | default dict -}}
{{- $groundsTokenEnabled := $groundsToken.enabled | default false -}}
{{- if eq (include "grounds-gamemode.engine" .) "minestom" -}}
{{- if .Values.agones.matchmaking.enabled }}
- name: GROUNDS_MATCHMAKING
  value: "1"
- name: GROUNDS_MATCH_HOST_PORT
  value: {{ .Values.agones.matchmaking.grpcPort | quote }}
{{- end }}
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
{{- with .Values.global.continent }}
- name: CONTINENT
  value: {{ . | quote }}
{{- end }}
{{- include "grounds-gamemode.regionEntryEnv" . }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- if $groundsTokenEnabled }}
- name: GROUNDS_TOKEN_FILE
  value: {{ clean (printf "%s/token" ($groundsToken.mountPath | default "")) | quote }}
{{- end }}
{{- if .Values.permissions.enabled }}
- name: PERMISSIONS_SERVICE_URL
  value: {{ required "permissions.serviceUrl is required when permissions are enabled" .Values.permissions.serviceUrl | quote }}
- name: PERMISSIONS_TOKEN_FILE
  value: {{ clean .Values.permissions.token.mountPath | quote }}
{{- end }}
{{- end -}}

{{/*
Reject configurations where differently scoped projected tokens would be
written to the same file. Comparing cleaned paths also catches trailing-slash
variants of the same path.
*/}}
{{- define "grounds-gamemode.validateTokenPaths" -}}
{{- $groundsToken := .Values.groundsToken | default dict -}}
{{- $groundsTokenEnabled := $groundsToken.enabled | default false -}}
{{- if and $groundsTokenEnabled .Values.permissions.enabled -}}
{{- $groundsTokenFile := clean (printf "%s/token" ($groundsToken.mountPath | default "")) -}}
{{- $permissionsTokenFile := clean .Values.permissions.token.mountPath -}}
{{- if eq $groundsTokenFile $permissionsTokenFile -}}
{{- fail "GROUNDS_TOKEN_FILE and PERMISSIONS_TOKEN_FILE must resolve to distinct file paths" -}}
{{- end -}}
{{- end -}}
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

{{- define "grounds-gamemode.serviceAccountName" -}}
{{- .Values.serviceAccount.name | default .Release.Name -}}
{{- end -}}

{{/*
Whether this release needs a dedicated ServiceAccount. Scoped projected tokens
must never fall back to the namespace's default account implicitly.
*/}}
{{- define "grounds-gamemode.serviceAccountRequired" -}}
{{- $groundsToken := .Values.groundsToken | default dict -}}
{{- $groundsTokenEnabled := $groundsToken.enabled | default false -}}
{{- if or .Values.serviceAccount.create .Values.permissions.enabled $groundsTokenEnabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "grounds-gamemode.permissionsRbacName" -}}
{{- $hash := printf "%s/%s" .Release.Namespace .Release.Name | sha256sum | trunc 8 -}}
{{- $base := printf "grounds-permissions-%s" .Release.Name -}}
{{- $prefix := $base | trunc (int (sub 63 (add (len $hash) 1))) | trimSuffix "-" -}}
{{- printf "%s-%s" $prefix $hash -}}
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
{{- if .Values.agones.matchmaking.enabled -}}
{{- /*
  A matchmade Fleet's name IS the mode id: service-match allocates from a Fleet
  named after the mode (fleetNameFor = modeId, region-agnostic), so a region
  suffix here would render `duel-nl-ams1` while the allocator asks for `duel`
  and every allocation misses. Each region runs its own service-match against
  its own single-region cluster, so the suffix is redundant anyway — dropped.
*/ -}}
{{ $.Release.Name }}
{{- else -}}
{{- with .Values.global.region -}}
{{ $.Release.Name }}-{{ . }}
{{- else -}}
{{ $.Release.Name }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Where this region's own entry point answers, for a lobby that has to tell other
regions how to reach it.

Taken out of `global.regions` rather than rebuilt from the parts: that string is
the catalogue ArgoCD already passes every component, and it is the only place
that carries the *port*. The port is not 25565 — UKS publishes the proxy on a
node port — and a name rebuilt here would silently default to the wrong one.

Emits nothing unless the continent has an entry in the catalogue, which keeps a
single-region or local install rendering a shorter env rather than a broken one.
*/}}
{{- define "grounds-gamemode.regionEntryEnv" -}}
{{- $g := .Values.global -}}
{{- if and $g.continent $g.regions -}}
{{- $prefix := printf "%s=" $g.continent -}}
{{- $entry := "" -}}
{{- range (splitList "," $g.regions) -}}
{{- $candidate := trim . -}}
{{- if and (eq $entry "") (hasPrefix $prefix $candidate) -}}
{{- $entry = trimPrefix $prefix $candidate -}}
{{- end -}}
{{- end -}}
{{- if $entry -}}
{{- $parts := splitList ":" $entry -}}
{{- $port := "" -}}
{{- $host := $entry -}}
{{- if gt (len $parts) 1 -}}
{{- $port = last $parts -}}
{{- $host = join ":" (initial $parts) -}}
{{- end }}
- name: GROUNDS_LOBBY_REGION_HOST
  value: {{ $host | quote }}
{{- if $port }}
- name: GROUNDS_LOBBY_REGION_PORT
  value: {{ $port | quote }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
