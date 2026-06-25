# OIDC bootstrap — wire GitHub Actions to your Azure subscription (no secrets)

Each pupil deploys the CFS landing zone to **their own** Azure subscription. GitHub Actions
authenticates with **workload identity federation (OIDC)** — there is **no client secret** and
**no key** stored anywhere. The workflow exchanges a short-lived GitHub token for an Azure token
at run time.

## What the bootstrap creates

| Object | Purpose |
| --- | --- |
| Entra **app registration** + **service principal** | The identity GitHub assumes. |
| **Federated credential** | Trust between a GitHub repo branch/environment and the app — scoped to `repo:<org>/<repo>:ref:refs/heads/main` (or `:environment:lab`). |
| **Role assignment** | `Owner` (or `Contributor` + `User Access Administrator`) at subscription scope, because the template is subscription-scoped and creates resource groups + RBAC. |

## Prerequisites

- `az login` as a user who can create app registrations and assign roles on the target subscription.
- The GitHub repo where the workflows run.

## Run it

PowerShell:

```pwsh
./infra/scripts/oidc-bootstrap.ps1 `
  -GitHubOrg NikoMix `
  -GitHubRepo microhack-networking-services `
  -Branch main
```

Bash:

```bash
./infra/scripts/oidc-bootstrap.sh \
  --org NikoMix \
  --repo microhack-networking-services \
  --branch main
```

Use `-Environment lab` / `--environment lab` instead of a branch if you gate deploys behind a
GitHub **environment** (recommended for the deploy/teardown workflows). You can run the script
twice — once for the branch (PR validation) and once for the environment (deploy).

## Add the identifiers to GitHub

The script prints three **identifiers** (not secrets). Add them under
**Settings → Secrets and variables → Actions**. They can be repository *variables* or *secrets*;
the workflows read them as secrets by default:

| Name | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | app registration `appId` |
| `AZURE_TENANT_ID` | tenant id |
| `AZURE_SUBSCRIPTION_ID` | subscription id |

## Verify

Trigger **Validate Infra** (push/PR) — it runs `bicep build`, `terraform validate`, and the
policy scan without touching Azure. Then run **Deploy** (workflow dispatch) and confirm the
`azure/login` step succeeds via OIDC with no secret configured.

## Cleanup

Delete the federated credential, role assignment, and app registration when the lab ends:

```bash
az role assignment delete --assignee <appId> --scope /subscriptions/<subId>
az ad app delete --id <appId>
```
