# VolSync Restic Notes

## Scope

This note covers the repo-side VolSync setup for scheduled filesystem backups to the TrueNAS NFS share.

This setup is intentionally simple:

- live app data stays on Longhorn
- VolSync runs once per day
- Restic stores backup snapshots on the NFS share
- PostgreSQL backups are handled separately

## Current Settings

NFS export:

```text
192.168.20.40:/mnt/tank/k8s-volsync
```

Shared backup PVC:

```text
volsync-repository
500Gi
```

Backup schedule:

```text
0 3 * * *
```

That means one backup run per day at `03:00`.

Restic retention:

- `daily: 7`
- `weekly: 4`
- `monthly: 3`
- `pruneIntervalDays: 7`

This keeps short-term recovery points without writing to the NAS all day.

## External Secret Refresh

The generated Kubernetes secret is refreshed from Bitwarden every `24h`.

That refresh interval:

- does not trigger backups
- does not write to the NAS
- only controls how often External Secrets checks Bitwarden for password changes

## First Workload

The first protected PVC is `docmost-data`.

The Restic repository path for it is:

```text
/mnt/repo/docmost-data
```

Future apps can reuse the same Bitwarden password secret and write to their own repository path.

## Notes

- The NFS path in the PV must match the exported path shown by `showmount -e 192.168.20.40`.
- VolSync is for app PVC backups here, not PostgreSQL.
- The shared Restic password comes from the Bitwarden secret `volsync-restic-password`.
- If that password is rotated, reduce the refresh interval temporarily or force an External Secrets sync.

Official references:

- https://volsync.readthedocs.io/en/latest/installation/index.html
- https://volsync.readthedocs.io/en/latest/usage/restic/index.html
- https://volsync.readthedocs.io/en/latest/usage/movervolumes.html
- https://restic.readthedocs.io/en/stable/
