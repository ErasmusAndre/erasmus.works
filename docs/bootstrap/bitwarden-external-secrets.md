# Bitwarden Secrets Manager Bootstrap

This setup uses External Secrets Operator with Bitwarden Secrets Manager.
Bitwarden is the source of truth for secret values. Kubernetes only stores:

- one bootstrap secret with the Bitwarden machine-account token
- one bootstrap TLS secret for the Bitwarden SDK server
- generated app secrets such as `cloudflared`

## What You Need In Bitwarden

Use Bitwarden Secrets Manager, not the normal Bitwarden vault.

- A machine-account token with access to the configured project
- A secret named `cloudflare-tunnel-token`

Bitwarden project:

`https://vault.bitwarden.eu/#/sm/00e4c26a-2e61-4ca9-8ead-b40900e7e081/projects/f2215b03-7218-473e-a29f-b40901159f28/secrets`

## One-Time Cluster Bootstrap

1. Create the Bitwarden machine-account token secret:

```sh
kubectl -n external-secrets create secret generic bitwarden-access-token \
  --from-literal=token='XX_REPLACE_ME__WITH_ACTUAL_SECRET_XX' \
  --dry-run=client -o yaml | kubectl apply -f -
```

2. Create the TLS secret for `bitwarden-sdk-server.external-secrets.svc.cluster.local`:

```sh
kubectl -n external-secrets create secret generic bitwarden-tls-certs \
  --from-file=tls.crt=bitwarden-sdk-server.crt \
  --from-file=tls.key=bitwarden-sdk-server.key \
  --from-file=ca.crt=bitwarden-sdk-server-ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -
```

If you use a self-signed certificate, `bitwarden-sdk-server-ca.crt` can be the
same file as `bitwarden-sdk-server.crt`.

These bootstrap secrets are intentionally not committed to Git.

## What Happens After Sync

1. Argo CD installs External Secrets Operator and the Bitwarden SDK server.
2. The `ClusterSecretStore` connects ESO to Bitwarden Secrets Manager.
3. `ExternalSecret/cloudflared` reads `cloudflare-tunnel-token` from Bitwarden.
4. ESO creates `Secret/cloudflared` in `cloudflare-system`.
5. The `cloudflared` Deployment consumes `tunnel-token` from that generated secret.

## Cloudflare DNS Vs Tunnel Routing

With the current setup, these are separate:

- DNS records for `*.erasmus.works` can be managed from this repo by `external-dns`
- public hostname routing for the Cloudflare Tunnel is still managed in the Cloudflare dashboard

That means adding a new public hostname usually needs two pieces:

1. Add the hostname to a Kubernetes `HTTPRoute` so `external-dns` can create the Cloudflare DNS record.
2. Add the same hostname to the existing Cloudflare Tunnel's `Public Hostnames` so Cloudflare knows where to send that traffic.

For this repo, tunnel public hostnames should point at:

`http://homelab-envoy.envoy-gateway-system.svc.cluster.local:80`

If a `*.erasmus.works` record exists in Cloudflare but the URL still does not work, the
usual cause is a missing tunnel public-hostname entry, not missing DNS.

## How To Add Another Secret

1. Point an `ExternalSecret` at a Bitwarden secret key.
2. Create the value with `linux/bws-secrets.sh` (below) or in Bitwarden Secrets Manager.

Example:

```yaml
spec:
  data:
    - secretKey: example-key
      remoteRef:
        key: example-secret-name-in-bitwarden
```

## Creating Secrets From The CLI

`linux/bws-secrets.sh` lists the Bitwarden keys a path's ExternalSecrets still need and creates
them with random values; it never overwrites. Run it without arguments for usage.

```bash
./linux/bws-secrets.sh missing kubernetes/apps/<app>
./linux/bws-secrets.sh create <app>-postgres-password:hex <app>-api-token:prompt
```

One-time setup: install [`bws`](https://github.com/bitwarden/sdk-sm/releases) into `~/.local/bin`,
run `bws config server-base https://vault.bitwarden.eu`, and save a token from a machine account
with **Can read, write** on the project to `~/.config/bws/token` (mode 600). Keep the ESO
machine account read-only.
