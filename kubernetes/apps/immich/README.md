# Immich migration notes

This app deploys Immich into the `apps` namespace with:

- the official Immich Helm chart
- Envoy Gateway exposure at `https://immich.erasmus.works`
- a dedicated CloudNativePG cluster on `longhorn`
- the main `/data` tree mounted from the existing TrueNAS NFS export
- `thumbs/` and `encoded-video/` initially reused from the NFS-backed main data volume
- machine-learning model cache on Longhorn

## Manual values to verify before sync

1. Check the NFS server IP in `pv-media-nfs.yaml`.
   The repo already uses `192.168.20.40` for TrueNAS-backed NFS storage in `kubernetes/infra/volsync/nfs-backup-pv.yaml`, so that value is used here too.
   If your Immich dataset is exported from a different TrueNAS IP, update the `server:` field before syncing.
2. Review the PVC sizes in:
   - `pvc-ml-cache.yaml`
3. Create these Bitwarden/External Secrets entries:
   - `immich-postgres-password`
   - `immich-cnpg-backup-secret-access-key`

## Sync and first access

1. Sync the Argo CD app:

```bash
argocd app sync immich
```

2. Wait for the app to become healthy.
3. Open:
   - `https://immich.erasmus.works`
   - or `https://immich.homelab`

## Restore flow

This deployment is prepared for the official Immich onboarding restore flow.

1. Make sure the NFS-backed dataset mounted at `/data` already contains the expected folders from the old instance:
   - `backups`
   - `encoded-video`
   - `images`
   - `library`
   - `profile`
   - `thumbs`
   - `upload`
2. Keep the existing backup file available on your workstation:

```text
/home/andre/code/ew/erasmus.works/temp-immich-migration/immich-db-backup-20260330T020000-v2.6.3-pg14.17.sql.gz
```

3. Visit the new Immich instance and use the welcome screen option `Restore from backup`.
4. When Immich checks storage folders, confirm the expected media folders are visible and writable.
5. If the backup file is not already visible under `/data/backups`, upload the `.sql.gz` file through the onboarding restore UI.
6. Complete the restore and let Immich run any required migrations.

## If restore fails because of the old vector extension

This repo intentionally deploys the current recommended CNPG + VectorChord setup.
It does not recreate the old `pgvecto-rs` database image inside Kubernetes.

If the SQL restore fails with errors referencing `vectors`, `pgvecto.rs`, or missing extension objects, treat that as a one-time migration issue with the old dump format.
In that case:

1. Stop here and keep the new Immich instance for validation only.
2. Use the old instance or a disposable restore environment to verify whether the dump still depends on `pgvecto-rs`.
3. Follow the official Immich migration guidance from `pgvecto.rs` to VectorChord before retrying the restore into this CNPG cluster.

## After restore

1. Log in and validate:
   - users and albums
   - random assets from different years
   - facial recognition and search
   - mobile upload target and app login against `immich.erasmus.works`
2. Rerun thumbnail generation or video transcoding only if you later decide not to keep the reused generated data.
3. Keep `https://immich.erasmuscloud.com` online until the new instance is fully validated.

## Later cleanup option

After migration and validation, you can do a follow-up change to move `thumbs/` onto Longhorn if you still want to reduce small-file NAS chatter during browsing.

## Assumptions in this setup

- The TrueNAS host at `192.168.20.40` is the same system exporting `/mnt/tank/immich-lxc`.
- The old media dataset contents remain the migration source of truth; nothing in this repo attempts to populate or restore the SQL backup automatically.
