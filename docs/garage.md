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

## Bootstrap

Garage deployment is GitOps-managed, but the initial cluster layout is a
one-time runtime bootstrap step.

Check the current node status and copy the node ID:

```bash
kubectl --kubeconfig talos/kubeconfig -n garage exec deploy/garage -c app -- /garage status
```

Assign the single node a role and capacity:

```bash
kubectl --kubeconfig talos/kubeconfig -n garage exec deploy/garage -c app -- \
  /garage layout assign -z homelab -c 100G <node-id>
```

Apply the initial layout:

```bash
kubectl --kubeconfig talos/kubeconfig -n garage exec deploy/garage -c app -- \
  /garage layout apply --version 1
```

Verify that the node has a zone and capacity instead of `NO ROLE ASSIGNED`:

```bash
kubectl --kubeconfig talos/kubeconfig -n garage exec deploy/garage -c app -- /garage status
```

This cluster has already been bootstrapped with:

- zone: `homelab`
- capacity: `100G`

## CNPG Credentials

Per-cluster CNPG backups should use their own Garage S3 key and a separate path
inside the shared `cnpg-backups` bucket.

For Docmost, the repo expects these Bitwarden secrets:

- `docmost-cnpg-backup-secret-access-key`

The Garage access key ID for Docmost is stored directly in the manifest, and
only the secret access key is stored in Bitwarden.

Those values map to the `ExternalSecret` in
`kubernetes/apps/docmost/externalsecrets.yaml`.

For Nextcloud, the repo expects these Bitwarden secrets:

- `nextcloud-cnpg-backup-secret-access-key`

Those values map to the `ExternalSecret` in
`kubernetes/apps/nextcloud/externalsecrets.yaml`.
