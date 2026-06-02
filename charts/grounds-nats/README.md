# grounds-nats

Self-contained NATS broker (operator-mode + auth-callout + deny-sentinel) **plus** the
`service-nats-authz` callout responder, packaged to run **inside a single boundary** — a
per-developer vCluster (v2.2 "Option 1") or any standalone namespace.

The responder validates SA-tokens against `kubernetes.default.svc` and reads SA
`gg.grounds/events` annotations from the same apiserver, so deployed inside a vCluster it
transparently authenticates **that vCluster's own** identities — no cross-cluster trust.

## Proven

End-to-end auth-callout verified 2026-06-02 in a throwaway vCluster on the platform cluster:
a vCluster SA-token (annotated `events:[{subject:test.subject,dir:both}]`) connecting as a
NATS bearer was granted **exactly** `pub=[test.subject] sub=[test.subject]`; publishing to an
undeclared subject got a scoped `Permissions Violation`. Responder log:
`allow default/test-sa — pub=[test.subject] sub=[test.subject]`.

## Keys (the important part)

The 9 `keys.*` values are an operator/account/user nkey+JWT set. Generate them like
`pulumi/scripts/nats-bootstrap/bootstrap.ts generate()`, but that script has **three bugs**
that produce a non-working broker — the set MUST be:

1. **Accounts operator-signed** — `encodeAccount(name, akp, claim, { signer: operator })`.
   Without `signer`, accounts self-sign and the full resolver rejects them.
2. **AUTH account `authorization.allowed_accounts: ["*"]`** — so the callout can place issued
   users into target accounts.
3. **AUTH account explicit `limits: { conn: -1, … }`** — a no-limits JWT account defaults
   `conn` to 0 → "maximum account active connections exceeded" on the first connect.

Pass them at install time:

```sh
helm install gn ./grounds-nats \
  --set-file keys.operatorJwt=operatorJwt.txt \
  --set-file keys.systemAccountPub=systemAccountPub.txt \
  --set-file keys.systemAccountJwt=systemAccountJwt.txt \
  --set-file keys.authAccountPub=authAccountPub.txt \
  --set-file keys.authAccountJwt=authAccountJwt.txt \
  --set-file keys.sentinelJwt=sentinelJwt.txt \
  --set-file keys.authServiceCreds=authServiceCreds.txt \
  --set-file keys.operatorXkeyPrivate=operatorXkeyPrivate.txt \
  --set-file keys.accountSigningNkey=accountSigningNkey.txt
```

## Notes

- `broker.image` must be `nats:2.12.6-alpine` or newer — `default_sentinel` needs nats ≥ 2.11.
- A `wait-for-broker` initContainer gates the responder: its auth-callout dispatcher
  subscribes **once** at startup and does not retry, so it must not start before the broker
  is serving. (A more robust fix would re-subscribe on reconnect in the responder itself.)
- First callout per cold responder is ~2s (JWKS + k8s SA lookup); a NATS client with the
  default ~2s connect deadline may time out on its very first publish, then succeed.
