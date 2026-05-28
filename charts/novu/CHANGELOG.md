# Changelog

## Unreleased

### Migration Notes

* Replaces the Bitnami Redis subchart with the official Valkey chart. Review Redis values before upgrading because the values schema and workload names changed.
* Replaces the Bitnami MongoDB subchart with this chart's MongoDB workload using the official `mongo` image. Existing Bitnami MongoDB PVCs are not migrated automatically.
* If MongoDB persistence was disabled, enabling it later does not migrate data previously stored in `emptyDir`.
* If MongoDB auth was disabled on first install, enabling it later requires manually creating or migrating users on the existing database.

## [0.1.1](https://github.com/groundsgg/charts/compare/novu-v0.1.0...novu-v0.1.1) (2026-05-27)


### Bug Fixes

* **novu:** support redis authentication ([#38](https://github.com/groundsgg/charts/issues/38)) ([21b6a53](https://github.com/groundsgg/charts/commit/21b6a53b577c52e39cd6839e08f76ab2eb79955d))

## [0.1.0](https://github.com/groundsgg/charts/compare/novu-v0.0.1...novu-v0.1.0) (2026-05-27)


### Features

* **novu:** add notification chart ([#36](https://github.com/groundsgg/charts/issues/36)) ([bc5394f](https://github.com/groundsgg/charts/commit/bc5394fa83cd60a93aab9952d4ed4f8925e51ae2))

## Changelog
