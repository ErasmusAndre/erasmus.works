# Garage Notes

Garage is deployed in-cluster and uses TrueNAS only as the backing NFS storage.

This keeps the service itself in GitOps while still landing CNPG backup objects on
the NAS.

The workload itself is deployed through Argo CD with the `app-template` Helm
chart

## TrueNAS

Create a dedicated dataset and NFS export:

```text
/mnt/tank/k8s-garage
```

That dataset should be writable from the Kubernetes node at `192.168.20.40`.

Garage creates its own `data` and `meta` directories inside that dataset on
first start.

## Bitwarden Secrets

Create these Bitwarden Secrets Manager secrets:

- `garage-rpc-secret`
- `garage-admin-token`

Use these formats:

- `garage-rpc-secret`: 32-byte hex string, for example `openssl rand -hex 32`
- `garage-admin-token`: long random token, for example `openssl rand -base64 32`

