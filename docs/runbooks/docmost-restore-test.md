# Docmost Restore Test

The restore drill stays disabled by default. Production `docmost`, `docmost-postgres`, and `docmost-data` are not modified.

Control file:

- [kubernetes/apps/docmost/restore-drill/request.yaml](../../kubernetes/apps/docmost/restore-drill/request.yaml)

## Start

Set [request.yaml](../../kubernetes/apps/docmost/restore-drill/request.yaml) to:

```yaml
state: start
note: ""
```

Commit and push.

Or run the `Docmost Restore Drill` workflow in GitHub Actions with `state=start`.

The manual workflow path expects a repository Actions secret named `WORKFLOW_PUSH_TOKEN`.

GitHub Actions then:

- adds `restore-drill` to [kubernetes/apps/docmost/kustomization.yaml](../../kubernetes/apps/docmost/kustomization.yaml)
- updates `spec.trigger.manual` in [kubernetes/apps/docmost/restore-drill/restore.yaml](../../kubernetes/apps/docmost/restore-drill/restore.yaml)
- writes `state: started` back to [request.yaml](../../kubernetes/apps/docmost/restore-drill/request.yaml)

Wait for the workflow commit, then check:

```bash
kubectl -n argocd get application docmost
kubectl -n apps get pvc,replicationdestination,externalsecret,cluster,deployment,service | rg 'docmost-data-restore|docmost-postgres-restore|docmost-restore-test'
kubectl -n apps rollout status deploy/docmost-restore-test --timeout=10m
```

Open:

```text
http://restore-test.homelab
```

Minimum pass criteria:

- restore PVC is `Bound`
- VolSync restore completes
- `docmost-postgres-restore` is ready
- `docmost-restore-test` is ready
- login works
- a representative page or attachment loads

Optional deeper checks:

```bash
kubectl -n apps exec deploy/docmost-restore-test -- ls -lah /app/data/storage
kubectl -n apps logs deploy/docmost-restore-test --tail=100
kubectl -n apps logs docmost-postgres-restore-1 --tail=100
kubectl -n apps exec -it docmost-postgres-restore-1 -- psql -U docmost -d docmost -c '\dt'
```

## Cleanup

Set [request.yaml](../../kubernetes/apps/docmost/restore-drill/request.yaml) to:

```yaml
state: cleanup
note: ""
```

Commit and push.

Or run the `Docmost Restore Drill` workflow in GitHub Actions with `state=cleanup`.

GitHub Actions then:

- removes `restore-drill` from [kubernetes/apps/docmost/kustomization.yaml](../../kubernetes/apps/docmost/kustomization.yaml)
- writes `state: idle` back to [request.yaml](../../kubernetes/apps/docmost/restore-drill/request.yaml)

Confirm prune:

```bash
kubectl -n apps get pvc docmost-data-restore
kubectl -n apps get replicationdestination docmost-data-restore
kubectl -n apps get externalsecret docmost-restore-test-secrets
kubectl -n apps get cluster docmost-postgres-restore
kubectl -n apps get deploy docmost-restore-test
kubectl -n apps get httproute docmost-restore-test
```
