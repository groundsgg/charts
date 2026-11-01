#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT
helm template bedrock "${repo_root}/charts/grounds-geyser" >"${output_dir}/rendered.yaml"
yq -r 'select(.kind == "ConfigMap") | .data["config.yml"]' "${output_dir}/rendered.yaml" >"${output_dir}/config.yaml"
yq -e '.bedrock.transport == "nethernet"' "${output_dir}/config.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.containers[0].ports | length == 1' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.containers[0].ports[0].containerPort == 19132' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.enableServiceLinks == false' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.containers[0].env | map(select(.name == "GROUNDS_GEYSER_ADVERTISE_ADDRESS" and .valueFrom.fieldRef.fieldPath == "status.hostIP")) | length == 1' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.containers[0].readinessProbe.httpGet.path == "/v1/join"' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.containers[0].readinessProbe.httpGet.port == 19132' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.updateStrategy.rollingUpdate.maxSurge == 0' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.updateStrategy.rollingUpdate.maxUnavailable == 1' "${output_dir}/rendered.yaml" >/dev/null
yq -e 'select(.kind == "DaemonSet") | .spec.template.spec.volumes | map(select(.name == "signaling-identity" and .secret.secretName == "geyser-signaling-identity")) | length == 1' "${output_dir}/rendered.yaml" >/dev/null
echo 'Geyser NetherNet signaling and per-node routing contracts passed'
