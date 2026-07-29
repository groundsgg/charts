#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "grounds-service probe contract failed: $1" >&2
  exit 1
}

assert_yq() {
  local file="$1"
  local expression="$2"
  local description="$3"
  yq -e "$expression" "$file" >/dev/null || fail "$description"
}

helm template default "${repo_root}/charts/grounds-service" \
  >"${output_dir}/default.yaml"
helm template configured "${repo_root}/charts/grounds-service" \
  -f "${repo_root}/tests/grounds-service/probes-values.yaml" \
  >"${output_dir}/configured.yaml"

container_query='select(.kind == "Deployment") | .spec.template.spec.containers[0]'

assert_yq \
  "${output_dir}/default.yaml" \
  "${container_query} | has(\"startupProbe\") | not" \
  "default deployment rendered a startup probe"
assert_yq \
  "${output_dir}/default.yaml" \
  "${container_query} | has(\"readinessProbe\") | not" \
  "default deployment rendered a readiness probe"
assert_yq \
  "${output_dir}/default.yaml" \
  "${container_query} | has(\"livenessProbe\") | not" \
  "default deployment rendered a liveness probe"

assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .startupProbe.httpGet.path == \"/q/health/started\"" \
  "configured startup probe path is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .startupProbe.httpGet.port == \"http\"" \
  "configured startup probe port is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .startupProbe.periodSeconds == 2" \
  "configured startup probe period is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .startupProbe.failureThreshold == 60" \
  "configured startup probe failure threshold is missing"

assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .readinessProbe.httpGet.path == \"/q/health/ready\"" \
  "configured readiness probe path is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .readinessProbe.httpGet.port == \"http\"" \
  "configured readiness probe port is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .readinessProbe.periodSeconds == 5" \
  "configured readiness probe period is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .readinessProbe.timeoutSeconds == 2" \
  "configured readiness probe timeout is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .readinessProbe.failureThreshold == 3" \
  "configured readiness probe failure threshold is missing"

assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .livenessProbe.httpGet.path == \"/q/health/live\"" \
  "configured liveness probe path is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .livenessProbe.httpGet.port == \"http\"" \
  "configured liveness probe port is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .livenessProbe.periodSeconds == 10" \
  "configured liveness probe period is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .livenessProbe.timeoutSeconds == 2" \
  "configured liveness probe timeout is missing"
assert_yq \
  "${output_dir}/configured.yaml" \
  "${container_query} | .livenessProbe.failureThreshold == 3" \
  "configured liveness probe failure threshold is missing"

echo "grounds-service probe contract passed"
