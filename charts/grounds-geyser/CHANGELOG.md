# Changelog

## [0.3.0](https://github.com/groundsgg/charts/compare/grounds-geyser-v0.2.0...grounds-geyser-v0.3.0) (2026-08-13)


### ⚠ BREAKING CHANGES

* **grounds-geyser:** the workload is a DaemonSet, so replicaCount and the anti-affinity toggle are gone, and so is the external-dns annotation — the Bedrock name is declared by the satellite stack next to the records it already writes for these same addresses.

### Features

* **grounds-geyser:** run on every node ([#163](https://github.com/groundsgg/charts/issues/163)) ([23e8512](https://github.com/groundsgg/charts/commit/23e8512da505bdf08d29f63605a6c8f7f331d0ec))

## [0.2.0](https://github.com/groundsgg/charts/compare/grounds-geyser-v0.1.0...grounds-geyser-v0.2.0) (2026-08-13)


### Features

* **grounds-geyser:** add bedrock entry point chart ([#152](https://github.com/groundsgg/charts/issues/152)) ([8fc035c](https://github.com/groundsgg/charts/commit/8fc035c6bfffbd22abbc04c3bcb727d495a392b8))


### Bug Fixes

* **grounds-geyser:** mount the config where geyser can rewrite it ([#160](https://github.com/groundsgg/charts/issues/160)) ([f1818db](https://github.com/groundsgg/charts/commit/f1818dba763d63cefda0bf494371536646e9c4ed))

## 0.1.0 (2026-08-13)


### Features

* **grounds-geyser:** add bedrock entry point chart ([#152](https://github.com/groundsgg/charts/issues/152)) ([8fc035c](https://github.com/groundsgg/charts/commit/8fc035c6bfffbd22abbc04c3bcb727d495a392b8))
