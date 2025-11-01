{{/*
Image pull policy
*/}}
{{- define "common.imagePullPolicy" -}}
{{- if .Values.image.pullPolicy }}
{{- .Values.image.pullPolicy }}
{{- else if eq (toString .Values.image.tag) "latest" }}
{{- "Always" }}
{{- else }}
{{- "IfNotPresent" }}
{{- end }}
{{- end }}

{{/*
Image reference helper
*/}}
{{- define "common.image" -}}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (default "latest" .Values.image.tag) }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default "latest" .Values.image.tag) }}
{{- end }}
{{- end }}

