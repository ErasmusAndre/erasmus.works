# Kustomization Grouping

Use section comments in `kustomization.yaml` only when they make a larger file easier to scan.

Do not add comments to tiny files.
Do not invent one-off group names.

## Group order

When needed, use these groups in this order:

1. `# Core`
2. `# Storage`
3. `# Networking`
4. `# Metrics`
5. `# SSO`

## What belongs where

- `# Core`: normal required resources for the component
  Examples: `namespace.yaml`, `application.yaml`, `deployment.yaml`, `externalsecret.yaml`, `postgres.yaml`, `redis.yaml`
- `# Storage`: persistent storage resources
  Examples: `pv.yaml`, `pvc.yaml`, volume-related resources
- `# Networking`: routing and network policy
  Examples: `httproute.yaml`, `ingress.yaml`, `gateway.yaml`, `networkpolicy.yaml`, `backendtrafficpolicy.yaml`
- `# Metrics`: observability resources
  Examples: `metrics-service.yaml`, `metrics-servicemonitor.yaml`, dashboards, alerts
- `# SSO`: optional authentication resources
  Examples: OIDC config, RBAC mapping for SSO groups, auth provider secrets

## Rules

- Prefer no comments over low-value comments
- Use comments only when a file has clear sections
- `# SSO` should usually be last
- Keep comment names exact: `# Core`, not `# Core resources`

## Example

```yaml
resources:
  # Core
  - externalsecrets.yaml
  - postgres.yaml

  # Storage
  - pvc.yaml

  # Networking
  - networkpolicy.yaml
  - httproute.yaml

  # Metrics
  - metrics-servicemonitor.yaml

  # SSO
  - authentik-secret.yaml
```
