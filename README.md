# charts

This repository contains the Helm charts for the grounds.gg stack, published as OCI artifacts to `ghcr.io/groundsgg/charts`.

## Install (OCI)

Helm needs OCI support (Helm v3).

```sh
helm install grounds-api oci://ghcr.io/groundsgg/charts/grounds-api --version <chart-version>
```

### grounds-service permissions runtime token

`grounds-service` can project a second, audience-scoped consumer token without
changing its existing `groundsToken`:

```yaml
serviceAccount:
  create: true
  name: service-moderation
permissionsToken:
  enabled: true
```

The token has the fixed `service-permissions` audience, is rotated by the
kubelet, and is mounted read-only at
`/var/run/secrets/grounds-permissions/token`. The chart also exports that path
as `PERMISSIONS_TOKEN_FILE`. An explicit `serviceAccount.name` is required,
and its mount directory must not overlap the grounds-services or Kubernetes API
token mounts. This option creates no RBAC; cluster-scoped permissions runtime
access remains an infrastructure responsibility. Applications with a different
configuration key must point it at the same mounted file explicitly.

## License

Licensed under the Apache License, Version 2.0.
