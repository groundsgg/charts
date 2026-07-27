#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "permissions runtime chart contract failed: $1" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "missing '${expected}' in ${file}"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$file"; then
    fail "unexpected '${unexpected}' in ${file}"
  fi
}

render() {
  local release="$1"
  local chart="$2"
  local output="$3"
  shift 3
  helm template "$release" "${repo_root}/charts/${chart}" --namespace default "$@" > "$output"
}

for chart in grounds-velocity grounds-gamemode; do
  default_output="${output_dir}/${chart}-default.yaml"
  render test "$chart" "$default_output"
  assert_not_contains "$default_output" "PERMISSIONS_SERVICE_URL"
  assert_not_contains "$default_output" "PERMISSIONS_TOKEN_FILE"
  assert_not_contains "$default_output" "grounds-permissions-"
  assert_not_contains "$default_output" "audience: service-permissions"
done

velocity_output="${output_dir}/velocity.yaml"
render velocity grounds-velocity "$velocity_output" \
  -f "${repo_root}/tests/permissions/velocity-values.yaml"
assert_contains "$velocity_output" "kind: ServiceAccount"
assert_contains "$velocity_output" "name: velocity"
assert_contains "$velocity_output" "serviceAccountName: velocity"
assert_contains "$velocity_output" "automountServiceAccountToken: false"
assert_contains "$velocity_output" "name: PERMISSIONS_SERVICE_URL"
assert_contains "$velocity_output" "http://service-permissions-runtime.default.svc.cluster.local:8080"
assert_contains "$velocity_output" "name: PERMISSIONS_TOKEN_FILE"
assert_contains "$velocity_output" "/var/run/secrets/grounds/permissions-token"
assert_contains "$velocity_output" "audience: service-permissions"
assert_contains "$velocity_output" "path: permissions-token"
assert_contains "$velocity_output" "/v1/permissions/runtime/players/*"
assert_contains "$velocity_output" "/v1/permissions/runtime/catalog/manifests/plugin-chat"
assert_contains "$velocity_output" "/v1/permissions/runtime/catalog/manifests/plugin-permissions"

gamemode_deployment_output="${output_dir}/gamemode-deployment.yaml"
render minestom-lobby grounds-gamemode "$gamemode_deployment_output" \
  -f "${repo_root}/tests/permissions/gamemode-deployment-values.yaml"
assert_contains "$gamemode_deployment_output" "kind: ServiceAccount"
assert_contains "$gamemode_deployment_output" "name: minestom-lobby"
assert_contains "$gamemode_deployment_output" "serviceAccountName: minestom-lobby"
assert_contains "$gamemode_deployment_output" "automountServiceAccountToken: false"
assert_contains "$gamemode_deployment_output" "name: PERMISSIONS_SERVICE_URL"
assert_contains "$gamemode_deployment_output" "name: PERMISSIONS_TOKEN_FILE"
assert_contains "$gamemode_deployment_output" "/v1/permissions/runtime/players/*"
assert_not_contains "$gamemode_deployment_output" "name: agones-sdk"

gamemode_fleet_output="${output_dir}/gamemode-fleet.yaml"
render paper-game grounds-gamemode "$gamemode_fleet_output" \
  -f "${repo_root}/tests/permissions/gamemode-fleet-values.yaml"
assert_contains "$gamemode_fleet_output" "kind: Fleet"
assert_contains "$gamemode_fleet_output" "serviceAccountName: paper-game"
assert_contains "$gamemode_fleet_output" "automountServiceAccountToken: false"
assert_contains "$gamemode_fleet_output" "kind: RoleBinding"
assert_contains "$gamemode_fleet_output" "name: agones-sdk"
assert_contains "$gamemode_fleet_output" "/v1/permissions/runtime/catalog/manifests/plugin-permissions"

if rg -n 'PERMISSIONS_GRPC_TARGET|service-permissions:9000' \
  "${repo_root}/charts/grounds-velocity" \
  "${repo_root}/charts/grounds-gamemode" \
  "${repo_root}/charts/grounds-service"; then
  fail "legacy permissions gRPC configuration remains"
fi

echo "permissions runtime chart contract passed"
