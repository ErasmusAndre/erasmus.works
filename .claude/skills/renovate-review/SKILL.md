---
name: renovate-review
description: This skill should be used when the user asks to "review Renovate PRs", "check Renovate pull requests", "triage Renovate updates", "merge Renovate bot PRs", "which Renovate PRs should I merge", "babysit Renovate", "review dependency updates", "check homelab PRs", or wants help deciding which automated dependency update pull requests are safe to merge for this homelab Kubernetes GitOps repo. Always invoke this skill when the user mentions Renovate and PRs together, even casually.
version: 1.0.0
---

# Renovate Bot PR Review

A systematic workflow for safely triaging and merging Renovate Bot pull requests in the erasmus.works homelab Kubernetes GitOps repo.

## Overview

The goal is to: check that the cluster is healthy, understand what Renovate has opened, determine which PRs are safe to batch-merge vs. which need individual care, research any breaking changes for riskier updates, and hand the user a prioritized merge plan.

## Hard Rules — Never Break These

- **Never merge a PR** without the user explicitly saying to merge it. Produce a plan and wait for the user to act.
- **Never create a commit** or push any change to Git without explicit user instruction.
- **Never run `kubectl apply`** outside of pre-approved CRD pre-staging steps, and always confirm with the user before doing so.

Present recommendations, explain risks, and let the user pull the trigger on every action.

## Step 1: Verify Cluster Health

Check the cluster is stable before recommending any merges.

First, locate the kubeconfig. Try in order:
1. Default (`~/.kube/config` or `$KUBECONFIG` if set)
2. Project path: `talos/kubeconfig` relative to the repo root (i.e. `kubernetes/clusters/../../../talos/kubeconfig` → `<repo-root>/talos/kubeconfig`)

For this repo the kubeconfig lives at `talos/kubeconfig` from the repo root. Export it explicitly:

```bash
export KUBECONFIG=/home/andre/code/ew/erasmus.works/talos/kubeconfig
```

Then run these read-only checks:

```bash
kubectl get nodes
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | grep -v "^NAMESPACE" | grep -v "Completed"
kubectl -n argocd get applications --no-headers | grep -v -E "(Synced\s+Healthy|OutOfSync\s+Healthy)"
```

Look for:
- All nodes in `Ready` state
- No pods stuck in `CrashLoopBackOff`, `OOMKilled`, `Pending` (unscheduled), or `Error`
- All Argo CD apps `Synced` and `Healthy` (OutOfSync is OK if Argo is actively syncing)

Surface any degraded state clearly. If the cluster has problems, flag them first and note which may be related to recent merges.

## Step 2: List and Fetch Open Renovate PRs

```bash
gh pr list --repo ErasmusAndre/erasmus.works --author "renovate[bot]" --state open --json number,title,labels,body,url --limit 50
```

For each PR, note:
- **PR number and title** — title encodes the package name and version bump (e.g. `chore(deps): update helm release longhorn to v1.8.0`)
- **Update type** — patch (`x.y.Z`), minor (`x.Y.z`), major (`X.y.z`), or digest pin
- **Package manager** — Helm chart, Docker image, GitHub Action, Talos image
- **Package name** — check against the critical packages list in `references/critical-packages.md`

## Step 3: Triage by Risk Level

Classify each PR into one of these buckets:

### Low Risk — Safe to batch-merge
- Patch bumps (`x.y.Z`) for non-critical packages
- Docker digest pin updates (SHA-only, no version change)
- GitHub Actions patch/minor/digest (these auto-merge already, but may still be open)

### Medium Risk — Merge one at a time, verify sync after each
- Minor bumps (`x.Y.z`) for non-critical packages
- Any package whose changelog mentions behavior changes even in a minor release
- Grouped PRs (e.g. bjw-s app-template, status page images) — treat the whole group as one merge

### High Risk — Research required before merging
- Any update to a **critical package** (see `references/critical-packages.md`)
- Any **major version** bump (`X.y.z`)
- Any update that mentions CRD changes, schema renames, or migration steps in the PR body

## Step 4: Research Breaking Changes

For every High Risk PR, search online before advising:

- Search: `"<package-name>" "<old-version>" to "<new-version>" breaking changes`
- Check the project's GitHub Releases or CHANGELOG
- Look for Kubernetes-specific concerns:
  - CRD additions, removals, or field renames (require pre-merge apply step)
  - Helm values restructured or renamed
  - Authentication/RBAC model changes
  - Storage migration requirements that are not reversible

Use the `WebSearch` tool to find release notes. Summarize findings per PR in the merge plan.

## Step 5: Produce the Merge Plan

Present the plan in this structure:

---

### Cluster Health
State: [Healthy / Degraded — describe any issues]

### Batch A — Safe to merge together now
| PR | Title | Why safe |
|----|-------|----------|
| #123 | chore(deps): update X to v1.2.3 | patch, non-critical |

### Batch B — Merge individually, verify Argo sync after each
| PR | Title | Notes |
|----|-------|-------|
| #124 | chore(deps): update Y to v2.1.0 | minor, check changelog |

### Needs research / manual review
| PR | Title | Blocker |
|----|-------|---------|
| #125 | chore(deps): update longhorn to v1.8.0 | critical infra, major-adjacent |

### Do not merge yet
| PR | Title | Reason |
|----|-------|--------|
| #126 | chore(deps): update ArgoCD to v3.0.0 | breaking API changes found, needs prep |

---

For each High Risk or "do not merge" PR, include a short explanation of what the breaking change is and what action is required before merging.

## Step 6: After Merging

Once the user merges a batch, suggest they verify:

```bash
# Watch Argo CD reconcile
kubectl -n argocd get applications -w

# Check for any newly degraded apps
kubectl -n argocd get applications --no-headers | grep -v -E "Synced\s+Healthy"
```

For critical infrastructure updates, suggest waiting 5-10 minutes and checking the specific app's pods before merging the next batch.

## Key Behaviors

- **Never merge PRs** — present the plan and wait for explicit user instruction to merge each batch
- **Never commit or push** — the user controls all Git operations
- **Never run `kubectl apply`** without confirming with the user first — the only exception is CRD pre-staging steps, which must still be proposed and approved before execution
- **Never suggest `helm install` or `helm upgrade`** — all changes go through Git/Argo CD
- **Bias toward caution on critical packages** — it's better to leave a PR open than to take down Longhorn or CNPG
- **Group-PRs are atomic** — if Renovate grouped multiple packages into one PR, treat it as a single merge decision, not individual package decisions
- **Re-check health after each merge batch** — wait for user confirmation before moving to the next batch

## Additional Resources

- `references/critical-packages.md` — the list of packages that always require manual review, with notes on past gotchas
