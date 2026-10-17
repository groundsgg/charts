#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/charts/grounds-velocity"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() { echo "grounds-velocity Floodgate contract failed: $1" >&2; exit 1; }
assert_yq() {
  yq -e "$2" "$1" >/dev/null || fail "$3"
}

helm template java "${chart}" >"${output_dir}/java.yaml"
helm template bedrock "${chart}" --set floodgateKey.enabled=true --set floodgateConfig.enabled=true >"${output_dir}/bedrock.yaml"

if yq -e 'select(.kind == "ConfigMap" and .metadata.name == "java-floodgate-config")' "${output_dir}/java.yaml" >/dev/null 2>&1; then
  fail "Java release unexpectedly rendered Floodgate config"
fi

# Check the rendered Deployment and ConfigMap, not Helm source templates.
yq -r 'select(.kind == "ConfigMap" and .metadata.name == "bedrock-floodgate-config") | .data["config.yml"]' "${output_dir}/bedrock.yaml" >"${output_dir}/config.yml"
assert_yq "${output_dir}/config.yml" \
  '."username-prefix" == "." and ."replace-spaces" == true and ."key-file-name" == "key.pem" and ."send-floodgate-data" == false and ."player-link".enabled == false and ."player-link"."require-link" == false and ."player-link"."enable-own-linking" == false and ."player-link"."enable-global-linking" == false' \
  "rendered config does not disable every Floodgate gameplay linking path"

assert_yq "${output_dir}/bedrock.yaml" \
  'select(.kind == "Deployment") | .spec.template.spec.containers[0].env | map(select(.name == "FLOODGATE_CONFIG_FILE" and .value == "/config/floodgate/config.yml")) | length == 1' \
  "deployment does not point startup at the managed config"
assert_yq "${output_dir}/bedrock.yaml" \
  'select(.kind == "Deployment") | .spec.template.spec.containers[0].volumeMounts | map(select(.name == "floodgate-config" and .mountPath == "/config/floodgate" and .readOnly == true)) | length == 1' \
  "managed Floodgate config is not mounted read-only"
assert_yq "${output_dir}/bedrock.yaml" \
  'select(.kind == "Deployment") | .spec.template.metadata.annotations | has("checksum/floodgate-config")' \
  "pod template does not restart when managed Floodgate config changes"

echo "grounds-velocity Floodgate config contract passed"
