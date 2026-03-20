# Grafana Dashboards

These dashboards are provisioned into Grafana through the existing `ConfigMap` + sidecar pattern in this directory.

## Source

The following files are provisioned from this directory. Most were imported from Grafana community dashboards and kept stock unless noted otherwise:

- `kubernetes-dashboard.json`
  - Source: https://grafana.com/grafana/dashboards/22523-eks-dashboard/
- `kubernetes-ram-cpu-utilization.json`
  - Source: https://grafana.com/grafana/dashboards/16734-kubernetes-cluster-ram-and-cpu-utilization/
- `longhorn-dashboard.json`
  - Source: https://grafana.com/grafana/dashboards/22705-longhorn-dashboard/
- `garage-dashboard.json`
  - Source URL not recorded in this repo
- `cloudnative-pg-dashboard.json`
  - Source URL not recorded in this repo
- `node-exporter-full.json`
  - Source: https://grafana.com/grafana/dashboards/1860-node-exporter-full
- `argocd.json`
  - Source: https://grafana.com/grafana/dashboards/14584-argocd/
- `victorialogs-explorer.json`
  - Source: https://grafana.com/grafana/dashboards/22759-victorialogs-explorer/
  - Adjusted to match this repo's Fluent Bit -> VictoriaLogs field names
- `volsync-dashboard.json`
  - Source: https://grafana.com/grafana/dashboards/21356-volsync-dashboard/

## Local tags

We add local Grafana tags to make imported and repo-managed dashboards easier to find:

- `custom`
  - Marks dashboards we intentionally manage from this repo
- `community`
  - Used for imported Grafana community dashboards

## Notes

- Community dashboards may still need small datasource or query adjustments depending on metric labels in this cluster.
- If updating an imported dashboard, prefer replacing it from the upstream Grafana export first, then reapplying local tags if needed.
