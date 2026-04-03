# Authentik New App Notes

## Scope

Short checklist for adding a new app to Authentik through this repo.

Keep it GitOps-managed where possible.

## Repo Steps

1. Add an Authentik blueprint under `kubernetes/infra/authentik/blueprints/`.
2. Add the generated ConfigMap in `kubernetes/infra/authentik/kustomization.yaml`.
3. If the blueprint needs a client secret, add it to `kubernetes/infra/authentik/externalsecrets.yaml`.
4. Mount the blueprint into the Authentik worker in `kubernetes/infra/authentik/values.yaml`.
   If it is not mounted into `/blueprints/...`, Authentik will not import it.
5. Add the app-side OIDC config in the target app manifests.
6. If the app needs its own Kubernetes secret, wire it with External Secrets.

## Blueprint Pattern

Typical blueprint contents:

- OAuth2/OIDC provider
- Authentik application
- optional groups such as admin/viewer access groups

Current examples:

- `kubernetes/infra/authentik/blueprints/argocd.yaml`
- `kubernetes/infra/authentik/blueprints/nextcloud.yaml`
- `kubernetes/infra/authentik/blueprint-immich-configmap.yaml`

## Secret Pattern

- Keep the OAuth client secret in Bitwarden
- Reference it from `kubernetes/infra/authentik/externalsecrets.yaml`
- Reference it from the target app secret/config as needed

Example Bitwarden secret names:

- `argocd-oauth2-client-secret`
- `grafana-oauth2-client-secret`
- `immich-oauth2-client-secret`
- `nextcloud-oauth2-client-secret`

## After Sync

1. Verify the Authentik application and provider exist.
2. Verify any expected groups were created.
3. Add your user to the right Authentik group if needed.
4. Test login in the target app.

## Notes

- Do not manually create the Authentik app/provider if the blueprint is meant to manage it.
- If the app does not appear in Authentik after sync, first check the worker blueprint mount in `kubernetes/infra/authentik/values.yaml`.
