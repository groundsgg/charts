#!/usr/bin/env bash
set -euo pipefail

# The plugin-agones static-server contract is intentionally centralized in one
# ConfigMap. These checks pin down both the exact env value Velocity consumes
# and the validation errors that keep a bad environment values file from
# silently reaching proxies at their next startup.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/charts/grounds-static-servers"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "grounds-static-servers contract failed: $1" >&2
  exit 1
}

assert_yq() {
  local file="$1"
  local expression="$2"
  local description="$3"
  yq -e "$expression" "$file" >/dev/null || fail "$description"
}

assert_render_fails() {
  local values_file="$1"
  local expected="$2"
  local output="${output_dir}/failure.txt"

  if helm template invalid "${chart}" -f "${values_file}" >"${output}" 2>&1; then
    fail "expected render to fail: ${expected}"
  fi
  grep -F -- "$expected" "${output}" >/dev/null || fail "missing error: ${expected}"
}

assert_default_render_fails() {
  local expected="$1"
  local output="${output_dir}/default-failure.txt"

  if helm template default "${chart}" >"${output}" 2>&1; then
    fail "expected no-values render to fail: ${expected}"
  fi
  grep -F -- "$expected" "${output}" >/dev/null || fail "missing no-values error: ${expected}"
}

assert_default_render_fails "servers must contain at least one static server"

cat >"${output_dir}/valid-values.yaml" <<'EOF'
global:
  commonAnnotations:
    grounds.gg/owner: static-servers
servers:
  zebra: zebra.example.internal:25566
  alpha: alpha.example.internal:25565
  ipv4: 10.42.1.7:25567
EOF

helm template test "${chart}" -f "${output_dir}/valid-values.yaml" >"${output_dir}/valid.yaml"

config_map='select(.kind == "ConfigMap" and .metadata.name == "velocity-static-servers-v1")'
assert_yq "${output_dir}/valid.yaml" \
  "${config_map} | .data.GROUNDS_STATIC_SERVERS == \"alpha=alpha.example.internal:25565,ipv4=10.42.1.7:25567,zebra=zebra.example.internal:25566\"" \
  "ConfigMap does not expose deterministically sorted plugin-agones servers"
assert_yq "${output_dir}/valid.yaml" \
  "[${config_map}] | length == 1" \
  "chart did not render exactly one ConfigMap"
assert_yq "${output_dir}/valid.yaml" \
  "${config_map} | .immutable == true" \
  "default ConfigMap is not immutable"
assert_yq "${output_dir}/valid.yaml" \
  "${config_map} | .metadata.name == \"velocity-static-servers-v1\" and .immutable == true" \
  "default ConfigMap name is not the immutable versioned contract"
assert_yq "${output_dir}/valid.yaml" \
  "${config_map} | .metadata.annotations[\"helm.sh/resource-policy\"] == \"keep\"" \
  "ConfigMap is not retained while proxies overlap during a versioned upgrade"
assert_yq "${output_dir}/valid.yaml" \
  "${config_map} | .metadata.annotations[\"grounds.gg/owner\"] == \"static-servers\"" \
  "ConfigMap does not preserve global annotations"

cat >"${output_dir}/empty-servers.yaml" <<'EOF'
servers: {}
EOF
assert_render_fails "${output_dir}/empty-servers.yaml" "servers must contain at least one static server"

cat >"${output_dir}/bad-endpoint.yaml" <<'EOF'
servers:
  lobby: lobby.example.internal:65536
EOF
assert_render_fails "${output_dir}/bad-endpoint.yaml" "port must be between 1 and 65535"

cat >"${output_dir}/empty-endpoint.yaml" <<'EOF'
servers:
  lobby: ""
EOF
assert_render_fails "${output_dir}/empty-endpoint.yaml" "endpoint must be a DNS or IPv4 host and port"

cat >"${output_dir}/empty-name.yaml" <<'EOF'
servers:
  "": lobby.example.internal:25565
EOF
assert_render_fails "${output_dir}/empty-name.yaml" "static server name must not be empty"

cat >"${output_dir}/unsafe-name.yaml" <<'EOF'
servers:
  "lobby,other": lobby.example.internal:25565
EOF
assert_render_fails "${output_dir}/unsafe-name.yaml" "name must use only letters, numbers, underscores, or hyphens"

cat >"${output_dir}/unsafe-endpoint.yaml" <<'EOF'
servers:
  lobby: "lobby.example.internal:25565,other.example.internal:25566"
EOF
assert_render_fails "${output_dir}/unsafe-endpoint.yaml" "endpoint must be a DNS or IPv4 host and port"

cat >"${output_dir}/empty-dns-label.yaml" <<'EOF'
servers:
  lobby: a..b:25565
EOF
assert_render_fails "${output_dir}/empty-dns-label.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/invalid-dns-label-boundary.yaml" <<'EOF'
servers:
  lobby: a.-b:25565
EOF
assert_render_fails "${output_dir}/invalid-dns-label-boundary.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/oversized-dns-label.yaml" <<'EOF'
servers:
  lobby: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.internal:25565
EOF
assert_render_fails "${output_dir}/oversized-dns-label.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/oversized-dns-host.yaml" <<'EOF'
servers:
  lobby: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:25565
EOF
assert_render_fails "${output_dir}/oversized-dns-host.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/invalid-ipv4-octet.yaml" <<'EOF'
servers:
  lobby: 256.10.20.30:25565
EOF
assert_render_fails "${output_dir}/invalid-ipv4-octet.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/oversized-ipv4-octet.yaml" <<'EOF'
servers:
  lobby: 999999999999999999999.10.20.30:25565
EOF
assert_render_fails "${output_dir}/oversized-ipv4-octet.yaml" "endpoint must be a valid DNS or IPv4 host and port"

cat >"${output_dir}/case-duplicate.yaml" <<'EOF'
servers:
  Lobby: lobby-a.example.internal:25565
  lobby: lobby-b.example.internal:25565
EOF
assert_render_fails "${output_dir}/case-duplicate.yaml" "duplicate static server name (case-insensitive): lobby"

echo "grounds-static-servers chart contract passed"
