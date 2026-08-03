#!/usr/bin/env bash
set -euo pipefail

# The scrape contract for the proxy, which needs three things to agree before a
# single series leaves the pod: the annotations the satellite's metrics agent
# discovers on, a *declared* containerPort equal to `prometheus.io/port` (the
# agent keeps only the target whose port matches, so an undeclared port is never
# scraped and never says why), and GROUNDS_METRICS_* so plugin-proxy binds at
# all.
#
# Any one of them missing produces a pod that looks instrumented and reports
# nothing — and unlike a game server, a proxy with a broken metrics port keeps
# serving Minecraft, so nothing else looks wrong either.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/charts/grounds-velocity"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "grounds-velocity metrics contract failed: $1" >&2
  exit 1
}

assert_yq() {
  local file="$1"
  local expression="$2"
  local description="$3"
  yq -e "$expression" "$file" >/dev/null || fail "$description"
}

helm template off "${chart}" >"${output_dir}/off.yaml"
helm template on "${chart}" --set metrics.enabled=true >"${output_dir}/on.yaml"

pod='select(.kind == "Deployment") | .spec.template'
container="${pod} | .spec.containers[0]"

# Off by default, and off means nothing at all — an annotation with no endpoint
# behind it is a scrape target that fails every interval.
assert_yq "${output_dir}/off.yaml" \
  "${pod} | .metadata.annotations // {} | has(\"prometheus.io/scrape\") | not" \
  "a proxy with metrics disabled still advertises itself for scraping"
assert_yq "${output_dir}/off.yaml" \
  "${container} | [.ports[].name] | contains([\"metrics\"]) | not" \
  "a proxy with metrics disabled still declares a metrics port"
assert_yq "${output_dir}/off.yaml" \
  "${container} | [.env[].name] | contains([\"GROUNDS_METRICS_ENABLED\"]) | not" \
  "a proxy with metrics disabled still switches the plugin endpoint on"

assert_yq "${output_dir}/on.yaml" \
  "${pod} | .metadata.annotations[\"prometheus.io/scrape\"] == \"true\"" \
  "prometheus.io/scrape is not set on the pod"
assert_yq "${output_dir}/on.yaml" \
  "${pod} | .metadata.annotations[\"prometheus.io/port\"] == \"9000\"" \
  "prometheus.io/port is missing or wrong"
assert_yq "${output_dir}/on.yaml" \
  "${pod} | .metadata.annotations[\"prometheus.io/path\"] == \"/metrics\"" \
  "prometheus.io/path is missing or wrong"

# The load-bearing one: the annotation's port must be a declared containerPort.
assert_yq "${output_dir}/on.yaml" \
  "${container} | [.ports[] | select(.name == \"metrics\") | .containerPort] | .[0] == 9000" \
  "the metrics port is not declared as a containerPort, so nothing scrapes it"

assert_yq "${output_dir}/on.yaml" \
  "${container} | [.env[] | select(.name == \"GROUNDS_METRICS_ENABLED\") | .value] | .[0] == \"true\"" \
  "the plugin is not told to bind the endpoint"
assert_yq "${output_dir}/on.yaml" \
  "${container} | [.env[] | select(.name == \"GROUNDS_METRICS_PORT\") | .value] | .[0] == \"9000\"" \
  "GROUNDS_METRICS_PORT disagrees with the annotation"

# The Minecraft port has to survive alongside it — this is the proxy's whole job.
assert_yq "${output_dir}/on.yaml" \
  "${container} | [.ports[] | select(.name == \"minecraft\") | .containerPort] | .[0] == 25565" \
  "enabling metrics disturbed the Minecraft port"

# One socket cannot serve both.
if helm template collision "${chart}" \
  --set metrics.enabled=true --set metrics.port=25565 >/dev/null 2>&1; then
  fail "metrics.port equal to ports.minecraft rendered instead of failing"
fi

echo "grounds-velocity metrics contract passed"
