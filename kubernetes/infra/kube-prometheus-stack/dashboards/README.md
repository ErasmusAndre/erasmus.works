# Grafana Dashboards

These dashboards are provisioned into Grafana through the existing `ConfigMap` + sidecar pattern in this directory.

## Source

The following files were imported from Grafana community dashboards and kept stock unless noted otherwise:

- `kubernetes-dashboard.json`
  - Source: https://grafana.com/grafana/dashboards/22523-eks-dashboard/
- `kubernetes-ram-cpu-utilization.json`
  - Source: https://grafana.com/grafana/dashboards/16734-kubernetes-cluster-ram-and-cpu-utilization/
- `longhorn-dashboard.json`
  - Source: https://grafana.com/grafana/dashboards/22705-longhorn-dashboard/
- `node-exporter-full.json`
  - Source: https://grafana.com/grafana/dashboards/1860-node-exporter-full
- `argocd-operational-overview.json`
  - Source: https://grafana.com/grafana/dashboards/19993-argocd-operational-overview/
- `loki-istio-service-mesh.json`
  - Source: https://grafana.com/grafana/dashboards/14876-grafana-loki-dashboard-for-istio-service-mesh/
- `envoy-gateway-overview.json`
  - Source: https://grafana.com/grafana/dashboards/24460-envoy-gateway-overview/

## Local tags

We add local Grafana tags to make imported and repo-managed dashboards easier to find:

- `custom`
  - Marks dashboards we intentionally manage from this repo
- `community`
  - Used for imported Grafana community dashboards

## Notes

- Community dashboards may still need small datasource or query adjustments depending on metric labels in this cluster.
- If updating an imported dashboard, prefer replacing it from the upstream Grafana export first, then reapplying local tags if needed.
