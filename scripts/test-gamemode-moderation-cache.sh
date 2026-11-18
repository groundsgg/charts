#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="$repo_root/charts/grounds-gamemode"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
label='grounds.gg/moderation-policy-backend'
cache='/minestom/data/grounds-chat'
gate='moderation.backendPolicy.enabled'

render() {
  helm template game "$chart" --namespace stage "$@"
}

# The expected manifest is the complete unenrolled Fleet with only the six additions.
verify_fleet() {
  local -a values=(--set agones.enabled=true "$@")
  render "${values[@]}" >"$scratch/off.yaml"
  render "${values[@]}" --set "$gate=true" >"$scratch/on.yaml"
  yq -o=json 'select(.kind == "Fleet")' "$scratch/off.yaml" | jq -S \
    --arg label "$label" --arg cache "$cache" '
      .metadata.labels[$label] = "enabled"
      | .spec.template.metadata.labels[$label] = "enabled"
      | .spec.template.spec.template.metadata.labels[$label] = "enabled"
      | .spec.template.spec.template.spec.securityContext.fsGroup = 65532
      | .spec.template.spec.template.spec.volumes += [{"name":"moderation-policy-cache","emptyDir":{"sizeLimit":"8Mi"}}]
      | .spec.template.spec.template.spec.containers[0].volumeMounts += [{"name":"moderation-policy-cache","mountPath":$cache}]
    ' >"$scratch/expected"
  yq -o=json 'select(.kind == "Fleet")' "$scratch/on.yaml" | jq -S . >"$scratch/actual"
  diff -u "$scratch/expected" "$scratch/actual"
  # Other resources may already inherit the global label. Preserve them byte for byte after rendering.
  yq -N -o=json 'select(.kind != "Fleet")' "$scratch/off.yaml" >"$scratch/off-other"
  yq -N -o=json 'select(.kind != "Fleet")' "$scratch/on.yaml" >"$scratch/on-other"
  cmp "$scratch/off-other" "$scratch/on-other"
  # Helm emits the source YAML. Checking it also catches duplicate label keys hidden by YAML readers.
  render "${values[@]}" --set "$gate=true" --show-only templates/fleet.yaml >"$scratch/fleet.yaml"
  [[ "$(grep -Ec "^ +grounds[.]gg/moderation-policy-backend: [\"']?enabled[\"']?$" "$scratch/fleet.yaml")" -eq 3 ]]
}

reject() {
  local message="$1"
  shift
  if render "$@" >"$scratch/unexpected.yaml" 2>"$scratch/error"; then
    echo "Expected Helm to reject: $message" >&2
    exit 1
  fi
  grep -Fq "$message" "$scratch/error"
}

verify_fleet --set kind=lobby
verify_fleet --set kind=game --set engine=minestom --set voice.enabled=true \
  --set global.environment=stage --set global.region=de-nbg1 --set global.domain=grnds.io \
  --set permissions.enabled=true --set permissions.serviceUrl=http://permissions.invalid --set groundsToken.enabled=true \
  --set agones.fleet.autoscaler.enabled=true --set serviceAccount.create=true \
  --set-string 'global.commonLabels.grounds\.gg/moderation-policy-backend=enabled' \
  --set-string 'podLabels.grounds\.gg/moderation-policy-backend=enabled'
verify_fleet --set kind=game --set engine=minestom --set groundsToken.enabled=true \
  --set groundsToken.mountPath=/minestom/data/grounds-chat-tools
minestom=(--set kind=lobby --set agones.enabled=true --set "$gate=true")
reject 'requires an Agones Minestom Fleet' --set kind=lobby --set "$gate=true"
reject 'requires an Agones Minestom Fleet' --set agones.enabled=true --set engine=paper --set "$gate=true"
reject 'must be a boolean' --set agones.enabled=true --set-string "$gate=false"
reject 'conflicting enrollment label' "${minestom[@]}" --set-string 'podLabels.grounds\.gg/moderation-policy-backend=disabled'
reject 'conflicting enrollment label' "${minestom[@]}" --set-string 'global.commonLabels.grounds\.gg/moderation-policy-backend=false'
for mount in "$cache" /minestom/data "$cache/private" /; do
  reject 'overlaps the moderation cache' "${minestom[@]}" --set groundsToken.enabled=true --set-string "groundsToken.mountPath=$mount"
done
reject 'overlaps the moderation cache' "${minestom[@]}" --set permissions.enabled=true --set-string "permissions.token.mountPath=$cache/token"

render >"$scratch/default"
render --set "$gate=false" >"$scratch/explicit-off"
cmp "$scratch/default" "$scratch/explicit-off"
if grep -q 'moderation-policy-cache\|fsGroup: 65532' "$scratch/default"; then
  echo 'Unenrolled Deployment unexpectedly requests a moderation cache' >&2
  exit 1
fi
