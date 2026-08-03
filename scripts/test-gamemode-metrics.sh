#!/usr/bin/env bash
set -euo pipefail

# The scrape contract, which needs three things to agree before a single series
# leaves the pod: the annotations the satellite's metrics agent discovers on, a
# *declared* containerPort equal to `prometheus.io/port` (the agent keeps only
# the target whose port matches, so an undeclared port is never scraped and
# never says why), and GROUNDS_METRICS_* so the Minestom runtime binds at all.
#
# Any one of them silently produces a pod that looks instrumented and reports
# nothing, which is exactly what this guards.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/charts/grounds-gamemode"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "grounds-gamemode metrics contract failed: $1" >&2
  exit 1
}

assert_yq() {
  local file="$1"
  local expression="$2"
  local description="$3"
  yq -e "$expression" "$file" >/dev/null || fail "$description"
}

helm template off "${chart}" --set agones.enabled=true --set engine=minestom \
  >"${output_dir}/off.yaml"
# `engine` explicitly, because it defaults to paper for every kind but `lobby`
# and the GROUNDS_METRICS_* switch is Minestom's.
helm template fleet "${chart}" \
  --set agones.enabled=true --set metrics.enabled=true --set engine=minestom \
  >"${output_dir}/fleet.yaml"
helm template deployment "${chart}" \
  --set metrics.enabled=true --set engine=minestom \
  >"${output_dir}/deployment.yaml"
helm template paper "${chart}" --set metrics.enabled=true --set engine=paper \
  >"${output_dir}/paper.yaml"

fleet_pod='select(.kind == "Fleet") | .spec.template.spec.template'
fleet_container="${fleet_pod} | .spec.containers[0]"
deployment_pod='select(.kind == "Deployment") | .spec.template'
deployment_container="${deployment_pod} | .spec.containers[0]"

# Off by default, and off means nothing at all — an annotation without an
# endpoint behind it is a scrape target that fails every interval.
assert_yq "${output_dir}/off.yaml" \
  "${fleet_pod} | .metadata.annotations // {} | has(\"prometheus.io/scrape\") | not" \
  "a fleet with metrics disabled still advertises itself for scraping"
assert_yq "${output_dir}/off.yaml" \
  "${fleet_container} | [.ports[].name] | contains([\"metrics\"]) | not" \
  "a fleet with metrics disabled still declares a metrics port"
assert_yq "${output_dir}/off.yaml" \
  "${fleet_container} | [.env[].name] | contains([\"GROUNDS_METRICS_ENABLED\"]) | not" \
  "a fleet with metrics disabled still switches the runtime endpoint on"

for file in fleet deployment; do
  pod_query="${fleet_pod}"
  container_query="${fleet_container}"
  if [ "${file}" = "deployment" ]; then
    pod_query="${deployment_pod}"
    container_query="${deployment_container}"
  fi

  assert_yq "${output_dir}/${file}.yaml" \
    "${pod_query} | .metadata.annotations[\"prometheus.io/scrape\"] == \"true\"" \
    "${file}: prometheus.io/scrape is not set on the pod"
  assert_yq "${output_dir}/${file}.yaml" \
    "${pod_query} | .metadata.annotations[\"prometheus.io/port\"] == \"9000\"" \
    "${file}: prometheus.io/port is missing or wrong"
  assert_yq "${output_dir}/${file}.yaml" \
    "${pod_query} | .metadata.annotations[\"prometheus.io/path\"] == \"/metrics\"" \
    "${file}: prometheus.io/path is missing or wrong"

  # The load-bearing one: the annotation's port must be a declared containerPort.
  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.ports[] | select(.name == \"metrics\") | .containerPort] | .[0] == 9000" \
    "${file}: the metrics port is not declared as a containerPort, so nothing scrapes it"

  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.env[] | select(.name == \"GROUNDS_METRICS_ENABLED\") | .value] | .[0] == \"true\"" \
    "${file}: the runtime is not told to bind the endpoint"
  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.env[] | select(.name == \"GROUNDS_METRICS_PORT\") | .value] | .[0] == \"9000\"" \
    "${file}: GROUNDS_METRICS_PORT disagrees with the annotation"
done

# Paper has no endpoint of its own: it gets the wiring, not the Minestom switch.
assert_yq "${output_dir}/paper.yaml" \
  "${deployment_pod} | .metadata.annotations[\"prometheus.io/scrape\"] == \"true\"" \
  "paper: the scrape annotation is missing"
assert_yq "${output_dir}/paper.yaml" \
  "${deployment_container} | [.env[].name] | contains([\"GROUNDS_METRICS_ENABLED\"]) | not" \
  "paper: a Minestom-only environment variable leaked into a Paper server"

# One socket cannot serve both, and left to the runtime it fails at bind time
# with a message that names neither setting.
if helm template collision "${chart}" \
  --set agones.enabled=true --set metrics.enabled=true --set metrics.port=25565 \
  >/dev/null 2>&1; then
  fail "metrics.port equal to containerPort rendered instead of failing"
fi

echo "grounds-gamemode metrics contract passed"
