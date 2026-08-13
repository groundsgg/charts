# Changelog

## [0.13.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.12.0...grounds-velocity-v0.13.0) (2026-08-13)


### Features

* **grounds-velocity:** mount the floodgate key for a bedrock proxy ([#161](https://github.com/groundsgg/charts/issues/161)) ([a8c8da7](https://github.com/groundsgg/charts/commit/a8c8da7738ccf3e7d96a2e9d7c7fd2399554e86d))

## [0.12.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.11.0...grounds-velocity-v0.12.0) (2026-08-03)


### Features

* **grounds-velocity:** opt-in Prometheus metrics on the proxy pods ([#149](https://github.com/groundsgg/charts/issues/149)) ([d9d370c](https://github.com/groundsgg/charts/commit/d9d370c6ce7ca37cea2f283741f51b01e3597a1f))

## [0.11.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.10.0...grounds-velocity-v0.11.0) (2026-08-02)


### Features

* **grounds-velocity:** render global.continent as CONTINENT ([#143](https://github.com/groundsgg/charts/issues/143)) ([c5c2583](https://github.com/groundsgg/charts/commit/c5c2583246edb3e2da743dcccc3632ca17141c49))

## [0.10.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.9.0...grounds-velocity-v0.10.0) (2026-08-02)


### Features

* **grounds-velocity:** route the continent entry points through mc-router ([#141](https://github.com/groundsgg/charts/issues/141)) ([b502f33](https://github.com/groundsgg/charts/commit/b502f33293636aac239f973c135b3e0dd1d97182))

## [0.9.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.8.0...grounds-velocity-v0.9.0) (2026-08-01)


### Features

* **velocity:** graceful drain on rollout — preStop, probes, grace period ([#139](https://github.com/groundsgg/charts/issues/139)) ([33a942e](https://github.com/groundsgg/charts/commit/33a942eb4178fb85ad22c96943e9eac3028a42ec))

## [0.8.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.7.0...grounds-velocity-v0.8.0) (2026-07-27)


### Features

* **permissions:** support platform-owned client RBAC ([#118](https://github.com/groundsgg/charts/issues/118)) ([2eec17c](https://github.com/groundsgg/charts/commit/2eec17cce875e8c436b8c238181cc9c535ab6408))

## [0.7.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.6.0...grounds-velocity-v0.7.0) (2026-07-27)


### Features

* **charts:** add permissions REST runtime identity ([#112](https://github.com/groundsgg/charts/issues/112)) ([590b8a4](https://github.com/groundsgg/charts/commit/590b8a44cefad10259b2df27612304a92111f814))

## [0.6.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.5.2...grounds-velocity-v0.6.0) (2026-07-25)


### Features

* **velocity:** take the region catalogue from a global value ([#110](https://github.com/groundsgg/charts/issues/110)) ([82aa503](https://github.com/groundsgg/charts/commit/82aa5039e3ed14d7b820233d77fa659335ca582a))

## [0.5.2](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.5.1...grounds-velocity-v0.5.2) (2026-07-25)


### Bug Fixes

* **velocity:** drop the flat continent name ([#108](https://github.com/groundsgg/charts/issues/108)) ([31fefe4](https://github.com/groundsgg/charts/commit/31fefe406fcba4a63c23b95bec0a576b2d3e40e6))

## [0.5.1](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.5.0...grounds-velocity-v0.5.1) (2026-07-25)


### Bug Fixes

* **velocity:** the continent entry name is flat ([#106](https://github.com/groundsgg/charts/issues/106)) ([0777761](https://github.com/groundsgg/charts/commit/07777615200715c58c5692be79381e9af088f11c))

## [0.5.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.4.0...grounds-velocity-v0.5.0) (2026-07-25)


### Features

* **velocity:** answer to the continent's typed name as well ([#104](https://github.com/groundsgg/charts/issues/104)) ([7cd3025](https://github.com/groundsgg/charts/commit/7cd3025fe38b4e19371be819a3011880075fd52e))

## [0.4.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.3.0...grounds-velocity-v0.4.0) (2026-07-25)


### Features

* **velocity:** derive the mc-router names from the region's identity ([#102](https://github.com/groundsgg/charts/issues/102)) ([8500584](https://github.com/groundsgg/charts/commit/8500584040e15d3fda053657e703163cfedcb854))

## [0.3.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.2.4...grounds-velocity-v0.3.0) (2026-07-24)


### Features

* allow pull secrets on a chart-created ServiceAccount ([#97](https://github.com/groundsgg/charts/issues/97)) ([429d02a](https://github.com/groundsgg/charts/commit/429d02a917b06606aabb6695a809e5a076bb015e))
* **velocity,gamemode:** let a cluster declare which region it is ([#100](https://github.com/groundsgg/charts/issues/100)) ([39bc470](https://github.com/groundsgg/charts/commit/39bc470b2a167cc8a8febf216051d0c47a521ad8))

## [0.2.4](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.2.3...grounds-velocity-v0.2.4) (2026-07-12)


### Bug Fixes

* **grounds-velocity:** copy baked plugins without preserving timestamps ([#79](https://github.com/groundsgg/charts/issues/79)) ([d8f8cd4](https://github.com/groundsgg/charts/commit/d8f8cd4e5a360a478a066551ffb2fe7dfdc2fb5d))

## [0.2.3](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.2.2...grounds-velocity-v0.2.3) (2026-07-12)


### Bug Fixes

* **grounds-velocity:** keep image-baked plugins when fetching extra JARs ([#77](https://github.com/groundsgg/charts/issues/77)) ([1caa5dc](https://github.com/groundsgg/charts/commit/1caa5dcae4b62ce8b8f74220dcfe0f4ca0b1707e))

## [0.2.2](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.2.1...grounds-velocity-v0.2.2) (2026-06-30)


### Bug Fixes

* **grounds-velocity:** stop shadowing baked plugins with empty emptyDir ([#69](https://github.com/groundsgg/charts/issues/69)) ([732b531](https://github.com/groundsgg/charts/commit/732b531480b6af0bb879e3e3e9cdd3c8392fef9b))

## [0.2.1](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.2.0...grounds-velocity-v0.2.1) (2026-06-05)


### Bug Fixes

* **grounds-velocity:** bind/Service port 25565 to match the image ([#62](https://github.com/groundsgg/charts/issues/62)) ([cc4df3e](https://github.com/groundsgg/charts/commit/cc4df3eda435c9f63da0d8b3648e6dbd1d001a67))
* **grounds-velocity:** restore inert serviceAccount/groundsToken values ([#64](https://github.com/groundsgg/charts/issues/64)) ([397216a](https://github.com/groundsgg/charts/commit/397216abacc8b6a3a2c92e132980828dedd9802a))

## [0.2.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.1.0...grounds-velocity-v0.2.0) (2026-06-02)


### Features

* **nats:** B4 scoped-permission charts — grounds-nats + SA/token support ([#48](https://github.com/groundsgg/charts/issues/48)) ([a428b4e](https://github.com/groundsgg/charts/commit/a428b4e947e8416676c781c7817117b5cb07f847))

## [0.1.0](https://github.com/groundsgg/charts/compare/grounds-velocity-v0.0.1...grounds-velocity-v0.1.0) (2026-05-03)


### Features

* add grounds-velocity, plugin-velocity-jar, grounds-gamemode charts ([#32](https://github.com/groundsgg/charts/issues/32)) ([00a4348](https://github.com/groundsgg/charts/commit/00a434848bdf1fd0f3189c74ae2036f0a074b797))
