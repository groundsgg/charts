# charts

This repository contains the Helm charts for the grounds.gg stack, published as OCI artifacts to `ghcr.io/groundsgg/charts`.

## Install (OCI)

Helm needs OCI support (Helm v3).

```sh
helm install grounds-api oci://ghcr.io/groundsgg/charts/grounds-api --version <chart-version>
```

## License

Licensed under the Apache License, Version 2.0.
