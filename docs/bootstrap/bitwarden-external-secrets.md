# Bitwarden Secrets Manager Bootstrap

This repo installs External Secrets Operator from the official Helm chart via an
Argo CD `Application` and uses an `ExternalSecret` to create the `cloudflared`
secret in `cloudflare-system`.

## Why Helm here

The Bitwarden Secrets Manager provider needs the Bitwarden SDK server and HTTPS
between ESO and that server. Using the official Helm chart keeps that install
small and avoids carrying the operator manifests and namespace-specific patches
in this repo.

## Manual bootstrap secrets

The Bitwarden machine-account access token:

```sh
kubectl -n external-secrets create secret generic bitwarden-access-token --from-literal=token='REPLACE_ME'
```

The Bitwarden SDK server TLS secret:

```sh
kubectl -n external-secrets create secret generic bitwarden-tls-certs \
  --from-file=tls.crt=bitwarden-sdk-server.crt \
  --from-file=tls.key=bitwarden-sdk-server.key \
  --from-file=ca.crt=bitwarden-sdk-server-ca.crt
```

For a self-signed setup, `bitwarden-sdk-server-ca.crt` can be the same certificate
file as `bitwarden-sdk-server.crt`.

These bootstrap secrets are intentionally not committed to Git.

## Bitwarden values you still need

Use Bitwarden Secrets Manager, not the normal Bitwarden vault.

You still need:

- A Bitwarden machine-account token with access to the configured project
- A TLS certificate for `bitwarden-sdk-server.external-secrets.svc.cluster.local`
- A Bitwarden Secrets Manager secret named `cloudflare-tunnel-token` with the Cloudflare tunnel token as its value

## Flow

1. Argo CD syncs `kubernetes/infra`.
2. The `external-secrets` child app installs ESO and the Bitwarden SDK server from Helm.
3. The `ClusterSecretStore` connects to Bitwarden Secrets Manager through the SDK server.
4. The `cloudflared` `ExternalSecret` reads `cloudflare-tunnel-token` from Bitwarden Secrets Manager.
5. External Secrets Operator creates the Kubernetes `Secret/cloudflared`.
6. The existing cloudflared Deployment consumes `tunnel-token` from that generated secret.
