{{- define "grounds-service.kubernetesReviewName" -}}
{{- $hash := printf "%s/%s" .Release.Namespace .Release.Name | sha256sum | trunc 8 -}}
{{- $base := printf "%s-kubernetes-review" .Release.Name -}}
{{- $prefix := $base | trunc (int (sub 63 (add (len $hash) 1))) | trimSuffix "-" -}}
{{- printf "%s-%s" $prefix $hash -}}
{{- end -}}
