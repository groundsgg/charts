#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="$repo_root/charts/grounds-gamemode"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cat >"$scratch/content.yaml" <<'YAML'
extraVolumes:
  - name: npc-content
    secret:
      secretName: npc-content-immutable
  - name: scene-catalog
    configMap:
      name: scene-catalog-immutable
extraVolumeMounts:
  - name: npc-content
    mountPath: /minestom/npc
    readOnly: true
  - name: scene-catalog
    mountPath: /minestom/catalog
    readOnly: true
YAML
for agones in false true; do
  for controls in false true; do
    args=(--set "agones.enabled=$agones")
    if [[ "$controls" == true ]]; then
      args+=(--set kind=lobby --set permissions.enabled=true --set permissions.serviceUrl=http://permissions.invalid --set groundsToken.enabled=true --set voice.enabled=true --set global.environment=stage --set global.region=de-nbg1 --set global.domain=grnds.io)
      if [[ "$agones" == true ]]; then args+=(--set moderation.backendPolicy.enabled=true); fi
    fi
    helm template game "$chart" --namespace stage "${args[@]}" >"$scratch/before.yaml"
    helm template game "$chart" --namespace stage "${args[@]}" -f "$scratch/content.yaml" >"$scratch/after.yaml"
    yq -N -o=json '.' "$scratch/before.yaml" | jq -sS '
      map(if .kind == "Fleet" then
        .spec.template.spec.template.spec |= (
          .volumes += [{"name":"npc-content","secret":{"secretName":"npc-content-immutable"}},{"name":"scene-catalog","configMap":{"name":"scene-catalog-immutable"}}]
          | .containers[0].volumeMounts += [{"name":"npc-content","mountPath":"/minestom/npc","readOnly":true},{"name":"scene-catalog","mountPath":"/minestom/catalog","readOnly":true}])
      elif .kind == "Deployment" then
        .spec.template.spec |= (
          .volumes += [{"name":"npc-content","secret":{"secretName":"npc-content-immutable"}},{"name":"scene-catalog","configMap":{"name":"scene-catalog-immutable"}}]
          | .containers[0].volumeMounts += [{"name":"npc-content","mountPath":"/minestom/npc","readOnly":true},{"name":"scene-catalog","mountPath":"/minestom/catalog","readOnly":true}])
      else . end)' >"$scratch/expected.json"
    yq -N -o=json '.' "$scratch/after.yaml" | jq -sS '.' >"$scratch/actual.json"
    diff -u "$scratch/expected.json" "$scratch/actual.json"
  done
done
printf '%s\n' 'External content volumes: Fleet and Deployment preserve every other rendered field, with and without existing runtime controls.'
