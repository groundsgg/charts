{{/*
Security context for non-root user (nestjs user: uid 1001, gid 1001)
*/}}
{{- define "common.securityContext" -}}
runAsNonRoot: true
runAsUser: 1001
runAsGroup: 1001
fsGroup: 1001
{{- if .Values.podSecurityContext }}
{{ toYaml .Values.podSecurityContext }}
{{- end }}
{{- end }}

{{/*
Container security context
*/}}
{{- define "common.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: false
capabilities:
  drop:
    - ALL
{{- if .Values.containerSecurityContext }}
{{ toYaml .Values.containerSecurityContext }}
{{- end }}
{{- end }}

