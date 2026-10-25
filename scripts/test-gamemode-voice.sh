#!/usr/bin/env bash
set -euo pipefail

# The voice contract between a game server and the region's grounds-voice-relay.
# The relay finds a pod only through the `bind` the pod announces on NATS, so
# every piece here has to agree with something outside this chart: the subject
# with the relay's, the host with the record the satellite's Pulumi stack
# writes, the bind port with the relay's POD_PORT, and the key file with the
# Secret both sides mount. Any one wrong is a pod that looks healthy and whose
# players hear nothing.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/charts/grounds-gamemode"
output_dir="$(mktemp -d)"
trap 'rm -rf "${output_dir}"' EXIT

fail() {
  echo "grounds-gamemode voice contract failed: $1" >&2
  exit 1
}

assert_yq() {
  local file="$1"
  local expression="$2"
  local description="$3"
  yq -e "$expression" "$file" >/dev/null || fail "$description"
}

globals=(
  --set global.environment=stage
  --set global.region=de-nbg1
  --set global.domain=grnds.io
)

helm template off "${chart}" --set agones.enabled=true "${globals[@]}" \
  >"${output_dir}/off.yaml"
helm template fleet "${chart}" --set agones.enabled=true \
  --set voice.enabled=true --set voice.port=24455 "${globals[@]}" \
  >"${output_dir}/fleet.yaml"
helm template deployment "${chart}" \
  --set voice.enabled=true --set voice.port=24455 "${globals[@]}" \
  >"${output_dir}/deployment.yaml"

fleet_pod='select(.kind == "Fleet") | .spec.template.spec.template'
deployment_pod='select(.kind == "Deployment") | .spec.template'

# Off by default, and off means nothing at all.
assert_yq "${output_dir}/off.yaml" \
  "${fleet_pod} | .spec.containers[0] | [.env[].name] | any_c(test(\"^VOICE_\")) | not" \
  "a fleet with voice disabled still sets VOICE_*"
assert_yq "${output_dir}/off.yaml" \
  "${fleet_pod} | .spec.containers[0] | [.ports[].name] | contains([\"voice\"]) | not" \
  "a fleet with voice disabled still declares the voice port"
assert_yq "${output_dir}/off.yaml" \
  "${fleet_pod} | .spec.volumes // [] | [.[].name] | contains([\"voice-route-key\"]) | not" \
  "a fleet with voice disabled still mounts the route key"

for file in fleet deployment; do
  pod_query="${fleet_pod}"
  if [ "${file}" = "deployment" ]; then
    pod_query="${deployment_pod}"
  fi
  container_query="${pod_query} | .spec.containers[0]"

  env_value() {
    echo "${container_query} | [.env[] | select(.name == \"$1\") | .value] | .[0]"
  }

  assert_yq "${output_dir}/${file}.yaml" \
    "$(env_value VOICE_HOST) == \"de-nbg1.stage.geo.grnds.io:24455\"" \
    "${file}: VOICE_HOST is not the region's DNS name on the environment's public port"
  assert_yq "${output_dir}/${file}.yaml" \
    "$(env_value VOICE_ROUTE_SUBJECT) == \"voice.routes.stage.de-nbg1\"" \
    "${file}: VOICE_ROUTE_SUBJECT disagrees with the relay's ROUTE_SUBJECT"
  assert_yq "${output_dir}/${file}.yaml" \
    "$(env_value VOICE_PARTY_SUBJECT) == \"social.parties.stage\"" \
    "${file}: VOICE_PARTY_SUBJECT disagrees with service-social's SOCIAL_PARTY_SUBJECT"
  assert_yq "${output_dir}/${file}.yaml" \
    "$(env_value VOICE_BIND) == \":24460\"" \
    "${file}: VOICE_BIND is not the relay's POD_PORT"
  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.env[] | select(.name == \"POD_IP\") | .valueFrom.fieldRef.fieldPath] | .[0] == \"status.podIP\"" \
    "${file}: POD_IP does not come from the downward API"
  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.ports[] | select(.name == \"voice\" and .containerPort == 24460 and .protocol == \"UDP\")] | length == 1" \
    "${file}: the voice port is not declared as 24460/UDP"

  # The key file the runtime is pointed at has to be where the Secret lands.
  assert_yq "${output_dir}/${file}.yaml" \
    "$(env_value VOICE_ROUTE_KEY_FILE) == \"/var/run/secrets/voice/route-key\"" \
    "${file}: VOICE_ROUTE_KEY_FILE is not the mounted key"
  assert_yq "${output_dir}/${file}.yaml" \
    "${container_query} | [.volumeMounts[] | select(.name == \"voice-route-key\" and .mountPath == \"/var/run/secrets/voice\" and .readOnly == true)] | length == 1" \
    "${file}: the route key is not mounted read-only at /var/run/secrets/voice"
  assert_yq "${output_dir}/${file}.yaml" \
    "${pod_query} | .spec.volumes[] | select(.name == \"voice-route-key\") | .secret.secretName == \"voice-route-key\"" \
    "${file}: the route key volume does not reference the voice-route-key Secret"
done

# Without the globals there is no subject or host to build, and a guess would
# be a relay that never hears this pod.
if helm template unset "${chart}" --set voice.enabled=true >/dev/null 2>&1; then
  fail "voice enabled without global.environment/region/domain rendered instead of failing"
fi

echo "grounds-gamemode voice contract passed"
