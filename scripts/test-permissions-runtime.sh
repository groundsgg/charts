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

service_default_output="${output_dir}/grounds-service-default.yaml"
render test grounds-service "$service_default_output"
assert_not_contains "$service_default_output" "name: service-permissions-runtime"
assert_not_contains "$service_default_output" "tokenreviews"
assert_not_contains "$service_default_output" "subjectaccessreviews"

velocity_output="${output_dir}/velocity.yaml"
render velocity grounds-velocity "$velocity_output" \
  -f "${repo_root}/tests/permissions/velocity-values.yaml"
assert_contains "$velocity_output" "kind: ServiceAccount"
assert_contains "$velocity_output" "name: velocity"
assert_contains "$velocity_output" "serviceAccountName: velocity"
assert_contains "$velocity_output" "automountServiceAccountToken: true"
assert_contains "$velocity_output" "kind: RoleBinding"
assert_contains "$velocity_output" "name: agones-sdk"
assert_contains "$velocity_output" "name: PERMISSIONS_SERVICE_URL"
assert_contains "$velocity_output" "http://service-permissions-runtime.default.svc.cluster.local:8080"
assert_contains "$velocity_output" "name: PERMISSIONS_TOKEN_FILE"
assert_contains "$velocity_output" "/var/run/secrets/grounds/permissions-token"
assert_contains "$velocity_output" "audience: service-permissions"
assert_contains "$velocity_output" "path: permissions-token"
assert_contains "$velocity_output" "/v1/permissions/runtime/players/*"
assert_contains "$velocity_output" "/v1/permissions/runtime/catalog/manifests/plugin-chat"
assert_contains "$velocity_output" "/v1/permissions/runtime/catalog/manifests/plugin-permissions"

velocity_separate_tokens_output="${output_dir}/velocity-separate-tokens.yaml"
render velocity grounds-velocity "$velocity_separate_tokens_output" \
  -f "${repo_root}/tests/permissions/velocity-values.yaml" \
  --set groundsToken.enabled=true \
  --set groundsToken.mountPath=/var/run/secrets/grounds \
  --set permissions.token.mountPath=/var/run/secrets/permissions/token
assert_contains "$velocity_separate_tokens_output" "mountPath: /var/run/secrets/grounds"
assert_contains "$velocity_separate_tokens_output" "mountPath: /var/run/secrets/permissions"
assert_contains "$velocity_separate_tokens_output" "value: \"/var/run/secrets/permissions/token\""

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
assert_contains "$gamemode_fleet_output" "automountServiceAccountToken: true"
assert_contains "$gamemode_fleet_output" "kind: RoleBinding"
assert_contains "$gamemode_fleet_output" "name: agones-sdk"
assert_contains "$gamemode_fleet_output" "/v1/permissions/runtime/catalog/manifests/plugin-permissions"

service_output="${output_dir}/service.yaml"
render service-permissions grounds-service "$service_output" \
  -f "${repo_root}/tests/permissions/service-values.yaml"
service_count="$(grep -c '^kind: Service$' "$service_output")"
[[ "$service_count" == "2" ]] || fail "expected two Services, rendered ${service_count}"
deployment_count="$(grep -c '^kind: Deployment$' "$service_output")"
[[ "$deployment_count" == "1" ]] || fail "expected one Deployment, rendered ${deployment_count}"
assert_contains "$service_output" "name: service-permissions-runtime"
assert_contains "$service_output" "containerPort: 8080"
assert_contains "$service_output" "serviceAccountName: service-permissions"
assert_contains "$service_output" "automountServiceAccountToken: false"
assert_contains "$service_output" "mountPath: /var/run/secrets/kubernetes.io/serviceaccount"
assert_contains "$service_output" "name: kube-root-ca.crt"
assert_contains "$service_output" "path: namespace"
assert_contains "$service_output" "resources:"
assert_contains "$service_output" "- tokenreviews"
assert_contains "$service_output" "- subjectaccessreviews"
assert_contains "$service_output" "verbs:"
assert_contains "$service_output" "- create"
assert_not_contains "$service_output" "audience:"
assert_not_contains "$service_output" "- '*'"
assert_not_contains "$service_output" "kind: HTTPRoute"

service_external_rbac_output="${output_dir}/service-external-rbac.yaml"
render service-permissions grounds-service "$service_external_rbac_output" \
  -f "${repo_root}/tests/permissions/service-external-rbac-values.yaml"
assert_contains "$service_external_rbac_output" "serviceAccountName: service-permissions"
assert_contains "$service_external_rbac_output" "mountPath: /var/run/secrets/kubernetes.io/serviceaccount"
assert_not_contains "$service_external_rbac_output" "kind: ClusterRole"
assert_not_contains "$service_external_rbac_output" "kind: ClusterRoleBinding"
assert_not_contains "$service_external_rbac_output" "- tokenreviews"
assert_not_contains "$service_external_rbac_output" "- subjectaccessreviews"

if rg -n 'PERMISSIONS_GRPC_TARGET|service-permissions:9000' \
  "${repo_root}/charts/grounds-velocity" \
  "${repo_root}/charts/grounds-gamemode" \
  "${repo_root}/charts/grounds-service"; then
  fail "legacy permissions gRPC configuration remains"
fi

echo "permissions runtime chart contract passed"
