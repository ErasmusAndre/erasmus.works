# Docmost Restore Test

## Scope

This runbook defines the recurring restore test pattern for `docmost` in namespace `apps`.

It covers:

- weekly smoke restore testing
- monthly fuller restore validation
- GitOps-safe enable and cleanup steps

The restore drill stays disabled by default. Production `docmost`, `docmost-postgres`, and `docmost-data` are not cut over or modified.

## Restore Drill Assets

The restore drill assets are kept in git under:

- [kubernetes/apps/docmost/restore-drill/kustomization.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/kustomization.yaml)
- [kubernetes/apps/docmost/restore-drill/restore.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/restore.yaml)
- [kubernetes/apps/docmost/restore-drill/restore-test.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/restore-test.yaml)

These resources are not part of the active Docmost app Kustomization by default.

## Current Backup Inputs

Docmost app data:

- Namespace: `apps`
- PVC: `docmost-data`
- VolSync `ReplicationSource`: `docmost-data`
- Restic repository secret: `docmost-data-restic-config`
- Restic repository path: `/mnt/repo/docmost-data`
- Backup schedule: `0 3 * * *`

Docmost PostgreSQL:

- Namespace: `apps`
- CNPG cluster: `docmost-postgres`
- ScheduledBackup: `docmost-postgres-backup`
- Backup destination: `s3://cnpg-backups/docmost`
- Backup endpoint: `http://garage.garage.svc.cluster.local:3900`
- Barman server name: `docmost-postgres`

Restore drill resources:

- PVC `docmost-data-restore`
- VolSync `ReplicationDestination` `docmost-data-restore`
- ExternalSecret `docmost-restore-test-secrets`
- CNPG cluster `docmost-postgres-restore`
- Deployment `docmost-restore-test`
- Service `docmost-restore-test`

## Cadence

### Weekly Smoke Restore

Goal:

- prove the repo can recreate the throwaway restore environment through GitOps
- prove VolSync restore still works into a throwaway PVC
- prove CNPG recovery still works from Garage
- prove Docmost can start against restored storage and restored database

Expected operator time:

- roughly 10 to 20 minutes of active work, then wait for reconciliation

### Monthly Full Validation

Goal:

- complete everything in the weekly smoke restore
- perform a more deliberate application-level validation of restored content
- verify a representative sample of real user data, attachments, and login flow

Expected operator time:

- roughly 20 to 40 minutes depending on how much data is inspected

## Prerequisites

- Argo CD is healthy and syncing this repo.
- VolSync, CloudNativePG, Garage, External Secrets, Longhorn, and Docmost are healthy.
- These secrets exist in namespace `apps`:
  - `docmost-data-restic-config`
  - `docmost-postgres-auth`
  - `docmost-postgres-backup-s3`
  - `docmost-app-secrets`
- `docmost-redis` is healthy.
- You have `kubectl` access to the cluster.

Useful prechecks:

```bash
kubectl -n apps get pvc docmost-data
kubectl -n apps get replicationsource docmost-data
kubectl -n apps get scheduledbackup docmost-postgres-backup
kubectl -n apps get secret docmost-data-restic-config docmost-postgres-auth docmost-postgres-backup-s3 docmost-app-secrets
kubectl -n apps get svc docmost-redis
kubectl -n argocd get application docmost
```

## Enable The Restore Drill

Temporarily edit [kubernetes/apps/docmost/kustomization.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/kustomization.yaml#L1) and add:

```yaml
resources:
  - externalsecrets.yaml
  - postgres.yaml
  - redis.yaml
  - app.yaml
  - volsync.yaml
  - restore-drill
```

Commit and push.

Wait for Argo CD to sync:

```bash
kubectl -n argocd get application docmost
kubectl -n apps get pvc,replicationdestination,externalsecret,cluster,deployment,service | rg 'docmost-data-restore|docmost-postgres-restore|docmost-restore-test'
```

## Trigger A New Restore Run

For each rerun, update the manual VolSync trigger in [restore.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/restore.yaml) to a new value.

Weekly example:

```yaml
spec:
  trigger:
    manual: restore-2026-03-25-weekly
```

Monthly example:

```yaml
spec:
  trigger:
    manual: restore-2026-03-monthly
```

Commit and push after updating the trigger value.

## Watch The Drill

### VolSync PVC Restore

```bash
kubectl -n apps get pvc docmost-data-restore
kubectl -n apps get replicationdestination docmost-data-restore -o yaml
kubectl -n apps get pods | rg volsync-dst-docmost-data-restore
```

Success signal:

- `docmost-data-restore` is `Bound`
- the restore mover job completes successfully
- `ReplicationDestination/docmost-data-restore` shows successful latest mover status

### CNPG Recovery Cluster

```bash
kubectl -n apps get cluster docmost-postgres-restore
kubectl -n apps get pods -l cnpg.io/cluster=docmost-postgres-restore
kubectl -n apps get svc docmost-postgres-restore-rw
```

Success signal:

- CNPG cluster exists
- cluster reports ready
- primary pod is running
- `docmost-postgres-restore-rw` exists

Optional SQL sanity check:

```bash
kubectl -n apps exec -it docmost-postgres-restore-1 -- \
  psql -U docmost -d docmost -c '\dt'
```

### Temporary Docmost App

```bash
kubectl -n apps rollout status deploy/docmost-restore-test --timeout=10m
kubectl -n apps get pods -l app=docmost-restore-test
kubectl -n apps get svc docmost-restore-test
```

Access it locally:

```bash
kubectl -n apps port-forward svc/docmost-restore-test 3001:3000
```

Open:

```text
http://127.0.0.1:3001
```

## Weekly Smoke Restore Success Criteria

The weekly smoke restore passes only if all of these are true:

- Argo syncs the restore drill resources successfully
- `docmost-data-restore` is created and `Bound`
- VolSync restore finishes successfully
- `docmost-postgres-restore` becomes healthy
- `docmost-restore-test` becomes ready
- the Docmost UI loads through local port-forward
- login works with a known valid account
- at least one representative workspace or page is visible

Recommended weekly spot checks:

- login succeeds
- one page opens
- one uploaded attachment or image renders
- application logs do not show obvious restore-related errors

## Monthly Full Validation Success Criteria

The monthly validation includes everything in the weekly smoke restore, plus all of these:

- verify multiple representative workspaces or sections
- verify a representative sample of attachments and uploaded files
- verify recent data looks plausible relative to the backup schedule
- verify the restored storage path contains expected filesystem content
- verify the restored database contains expected tables and non-trivial row counts
- record the date of the drill and any issues found in your normal ops notes

Recommended monthly checks:

```bash
kubectl -n apps exec deploy/docmost-restore-test -- ls -lah /app/data/storage
kubectl -n apps exec deploy/docmost-restore-test -- sh -c 'find /app/data/storage -maxdepth 2 | head -50'
kubectl -n apps logs deploy/docmost-restore-test --tail=100
kubectl -n apps logs docmost-postgres-restore-1 --tail=100
kubectl -n apps exec -it docmost-postgres-restore-1 -- \
  psql -U docmost -d docmost -c '\dt'
```

## Weekly Checklist

1. Re-enable `restore-drill` in [kustomization.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/kustomization.yaml#L1).
2. Change `spec.trigger.manual` in [restore.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/restore.yaml) to a fresh weekly value.
3. Commit and push.
4. Wait for Argo to sync.
5. Confirm restore PVC, CNPG restore cluster, and restore app are healthy.
6. Port-forward the restore app and confirm login plus one page or attachment works.
7. Remove `restore-drill` from [kustomization.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/kustomization.yaml#L1).
8. Commit and push again.
9. Confirm Argo prunes the temporary resources.

## Monthly Checklist

1. Follow the weekly checklist.
2. Use a monthly trigger value in [restore.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/restore-drill/restore.yaml).
3. Validate several workspaces or pages instead of one.
4. Validate multiple attachments or uploads.
5. Inspect restored filesystem content.
6. Run a small SQL sanity check against `docmost-postgres-restore`.
7. Note the outcome and any gaps before cleanup.
8. Remove `restore-drill` from active deployment and confirm prune.

## Cleanup

Disable the drill again through GitOps by reverting [kustomization.yaml](/home/andre/code/ew/erasmus.works/kubernetes/apps/docmost/kustomization.yaml#L1) so it no longer includes:

- `restore-drill`

Commit and push the cleanup change, then wait for Argo CD to prune:

- `docmost-data-restore`
- `ReplicationDestination/docmost-data-restore`
- `docmost-restore-test-secrets`
- `docmost-postgres-restore`
- `docmost-restore-test`

Confirm cleanup:

```bash
kubectl -n apps get pvc docmost-data-restore
kubectl -n apps get replicationdestination docmost-data-restore
kubectl -n apps get externalsecret docmost-restore-test-secrets
kubectl -n apps get cluster docmost-postgres-restore
kubectl -n apps get deploy docmost-restore-test
kubectl -n apps get svc docmost-restore-test
```

## Notes

- The restore drill stays disabled by default.
- The temporary app reuses existing Redis and existing Docmost secrets to keep the drill minimal.
- No public `HTTPRoute` is created for the drill.
- Re-running the drill always requires a fresh manual VolSync trigger value.
- This pattern is trusted for Docmost only after repeated successful weekly and monthly drills.
