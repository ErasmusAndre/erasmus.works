# OpenTofu Notes

OpenTofu here is only for Authentik.

Argo CD remains the source of truth for Kubernetes under `kubernetes/`.
OpenTofu is the explicit IaC layer for Authentik applications, providers,
groups, and related identity objects.

## Commands

From `opentofu/environments/homelab`:

```bash
/tmp/opentofu/tofu fmt -recursive
/tmp/opentofu/tofu init
/tmp/opentofu/tofu validate
/tmp/opentofu/tofu plan
```

Set credentials through environment variables:

```bash
export TF_VAR_authentik_token="replace-me"
```

Keep the token out of Git.

## Status

The layout and provider lock file are in place, and `tofu init` works.

As of 2026-04-04, the upstream `goauthentik/authentik` provider still fails
schema loading under OpenTofu in this environment, so `tofu validate` does not
complete yet.

Until that is resolved, treat this as the prepared migration target for
Authentik rather than the active source of truth.
