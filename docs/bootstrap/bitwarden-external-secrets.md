# Bitwarden Secrets Manager Bootstrap

This repo installs External Secrets Operator with a Bitwarden SDK server and
uses an `ExternalSecret` to create the `cloudflared` secret in `cloudflare-system`.

## Manual bootstrap secret

The one manual secret that remains is the Bitwarden machine-account access token
used to bootstrap External Secrets Operator:

```sh
kubectl -n external-secrets create secret generic bitwarden-access-token --from-literal=token='REPLACE_ME'
```

This bootstrap token secret is intentionally not committed to Git.

## Flow

1. Argo CD syncs `kubernetes/infra`.
2. `external-secrets` installs the operator, the Bitwarden SDK server, and the `ClusterSecretStore`.
3. The `cloudflared` `ExternalSecret` reads `cloudflare-tunnel-token` from Bitwarden Secrets Manager.
4. External Secrets Operator creates the Kubernetes `Secret/cloudflared`.
5. The existing cloudflared Deployment consumes `tunnel-token` from that generated secret.
