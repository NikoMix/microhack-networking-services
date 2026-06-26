#!/usr/bin/env bash
# Bootstrap GitHub -> Azure OIDC for the CFS networking microhack (no secrets stored).
# Creates/reuses an Entra app + SP, adds a federated credential for a repo branch or
# environment, and assigns subscription-scope RBAC. No client secret is ever created.
set -euo pipefail

GITHUB_ORG=""
GITHUB_REPO=""
BRANCH="main"
ENVIRONMENT=""
APP_NAME="cfs-microhack-oidc"
ROLE="Owner"

usage() {
  cat <<EOF
Usage: $0 --org <github-org> --repo <repo> [--branch main | --environment lab]
          [--app-name cfs-microhack-oidc] [--role Owner]
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) GITHUB_ORG="$2"; shift 2 ;;
    --repo) GITHUB_REPO="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --app-name) APP_NAME="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[[ -z "${GITHUB_ORG}" || -z "${GITHUB_REPO}" ]] && usage

if ! az account show --output none 2>/dev/null; then
  echo "Not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi
SUB_ID="$(az account show --query id --output tsv)"
TENANT_ID="$(az account show --query tenantId --output tsv)"
echo "Subscription: $(az account show --query name --output tsv) (${SUB_ID})"

# 1. App registration (idempotent)
APP_ID="$(az ad app list --display-name "${APP_NAME}" --query '[0].appId' --output tsv)"
if [[ -z "${APP_ID}" ]]; then
  echo "==> Creating app registration ${APP_NAME} ..."
  APP_ID="$(az ad app create --display-name "${APP_NAME}" --query appId --output tsv)"
else
  echo "==> Reusing app registration ${APP_NAME} (${APP_ID})."
fi

# 2. Service principal (idempotent)
if [[ -z "$(az ad sp list --filter "appId eq '${APP_ID}'" --query '[0].id' --output tsv)" ]]; then
  echo "==> Creating service principal ..."
  az ad sp create --id "${APP_ID}" --output none
fi

# 3. Federated credential
if [[ -n "${ENVIRONMENT}" ]]; then
  SUBJECT="repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${ENVIRONMENT}"
  CRED_NAME="gh-${ENVIRONMENT}"
else
  SUBJECT="repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/${BRANCH}"
  CRED_NAME="gh-branch-${BRANCH}"
fi

if [[ -z "$(az ad app federated-credential list --id "${APP_ID}" --query "[?subject=='${SUBJECT}'] | [0].name" --output tsv)" ]]; then
  echo "==> Adding federated credential (${SUBJECT}) ..."
  TMP="$(mktemp)"
  cat > "${TMP}" <<EOF
{
  "name": "${CRED_NAME}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${SUBJECT}",
  "description": "GitHub Actions OIDC for the CFS microhack",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
  az ad app federated-credential create --id "${APP_ID}" --parameters "${TMP}" --output none
  rm -f "${TMP}"
else
  echo "==> Federated credential already present (${SUBJECT})."
fi

# 4. RBAC at subscription scope
echo "==> Assigning ${ROLE} at subscription scope ..."
az role assignment create \
  --assignee "${APP_ID}" \
  --role "${ROLE}" \
  --scope "/subscriptions/${SUB_ID}" \
  --output none 2>/dev/null || true

cat <<EOF

==> OIDC bootstrap complete. Add these to GitHub (Settings > Secrets and variables > Actions):
    AZURE_CLIENT_ID       = ${APP_ID}
    AZURE_TENANT_ID       = ${TENANT_ID}
    AZURE_SUBSCRIPTION_ID = ${SUB_ID}

These are identifiers, not secrets. No client secret was created — login is OIDC only.
EOF
