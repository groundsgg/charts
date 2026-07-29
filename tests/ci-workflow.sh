#!/usr/bin/env bash
set -euo pipefail

workflow_file="${1:-.github/workflows/ci.yml}"

for event in push pull_request; do
  if ! yq -e ".on.${event}.paths[] | select(. == \"scripts/test-grounds-service-probes.sh\")" "$workflow_file" >/dev/null; then
    echo "Expected ${event} to run CI when the grounds-service probe contract changes." >&2
    exit 1
  fi
  if ! yq -e ".on.${event}.paths[] | select(. == \"tests/grounds-service/**\")" "$workflow_file" >/dev/null; then
    echo "Expected ${event} to run CI when grounds-service contract fixtures change." >&2
    exit 1
  fi
done

if ! yq -e '.jobs."permissions-runtime".name == "🧪 Service runtime contracts"' "$workflow_file" >/dev/null; then
  echo "Expected the existing runtime contract job to use its generic name." >&2
  exit 1
fi

if ! yq -e '.jobs."permissions-runtime".steps[] | select(.run == "bash scripts/test-grounds-service-probes.sh")' "$workflow_file" >/dev/null; then
  echo "Expected the runtime contract job to execute the grounds-service probe contract." >&2
  exit 1
fi

if ! yq -e '.jobs."detect-changed-charts".outputs.charts == "${{ steps.matrix.outputs.charts }}"' "$workflow_file" >/dev/null; then
  echo "Expected detect-changed-charts to expose the generated chart matrix." >&2
  exit 1
fi

if ! yq -e '.jobs.charts.needs == "detect-changed-charts"' "$workflow_file" >/dev/null; then
  echo "Expected chart validation to depend on changed-chart detection." >&2
  exit 1
fi

if ! yq -e '.jobs.charts.strategy.matrix.chart == "${{ fromJSON(needs.detect-changed-charts.outputs.charts) }}"' "$workflow_file" >/dev/null; then
  echo "Expected chart validation to use the generated chart matrix." >&2
  exit 1
fi

if [[ "$(yq -r '.jobs.charts.strategy.matrix.chart | type' "$workflow_file")" == "!!seq" ]]; then
  echo "Expected no static chart matrix." >&2
  exit 1
fi

if ! yq -e '.jobs.charts.steps[] | select(.id == "template-args").run | contains("args=--set novu.secrets.novuSecretKey=test --set novu.secrets.jwtSecret=test")' "$workflow_file" >/dev/null; then
  echo "Expected Novu template arguments to be emitted as one shell argument string." >&2
  exit 1
fi
