#!/usr/bin/env bash
# Deploy the CFS secure hub & spoke landing zone (Bicep, subscription scope).
# Runs a what-if preview first, then deploys unless --what-if-only is passed.
# Uses the current az login context (OIDC in CI, az login locally). No secrets handled.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT="all"
LOCATION="swedencentral"
TEMPLATE_FILE="${SCRIPT_DIR}/../bicep/main.bicep"
PARAMETER_FILE="${SCRIPT_DIR}/../bicep/parameters/lab.bicepparam"
DEPLOYMENT_NAME="cfs-network-$(date +%Y%m%d%H%M%S)"
WHAT_IF_ONLY="false"

usage() {
  echo "Usage: $0 [-c component] [-l location] [-p parameter-file] [-t template-file] [--what-if-only]"
  echo "  component: all (default) | gateway | hub | spoke | edge   (run 'gateway' FIRST)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--component) COMPONENT="$2"; shift 2 ;;
    -l|--location) LOCATION="$2"; shift 2 ;;
    -p|--parameters) PARAMETER_FILE="$2"; shift 2 ;;
    -t|--template) TEMPLATE_FILE="$2"; shift 2 ;;
    --what-if-only) WHAT_IF_ONLY="true"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

echo "==> Validating Azure CLI session..."
if ! az account show --output none 2>/dev/null; then
  echo "Not logged in to Azure. Run 'az login' (or rely on OIDC in CI) first." >&2
  exit 1
fi
az account show --query "{subscription:name,id:id}" --output tsv

echo "==> Building Bicep template..."
az bicep build --file "${TEMPLATE_FILE}"

echo "==> Running what-if preview (subscription scope, component=${COMPONENT})..."
az deployment sub what-if \
  --name "${DEPLOYMENT_NAME}" \
  --location "${LOCATION}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAMETER_FILE}" \
  --parameters deploymentComponent="${COMPONENT}"

if [[ "${WHAT_IF_ONLY}" == "true" ]]; then
  echo "==> --what-if-only set — stopping before deploy."
  exit 0
fi

echo "==> Deploying (component=${COMPONENT})..."
az deployment sub create \
  --name "${DEPLOYMENT_NAME}" \
  --location "${LOCATION}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAMETER_FILE}" \
  --parameters deploymentComponent="${COMPONENT}" \
  --output none

echo "==> Deployment complete. Outputs:"
az deployment sub show --name "${DEPLOYMENT_NAME}" --query properties.outputs --output jsonc

# -----------------------------------------------------------------------------
# Post-deploy: approve the Front Door Premium -> Application Gateway Private Link
# connection. The shared private link request lands as "Pending" on the App
# Gateway and must be approved before Front Door can route to the origin.
# -----------------------------------------------------------------------------
if [[ "${COMPONENT}" == "all" || "${COMPONENT}" == "edge" ]]; then
  echo "==> Approving Front Door -> App Gateway Private Link connection..."
  AGW_ID="$(az deployment sub show --name "${DEPLOYMENT_NAME}" \
    --query "properties.outputs.applicationGatewayResourceId.value" --output tsv)"
  if [[ -z "${AGW_ID}" ]]; then
    echo "    No Application Gateway in this deployment — skipping."
  else
    APPROVED="false"
    for _ in $(seq 1 10); do
      PENDING="$(az network private-endpoint-connection list --id "${AGW_ID}" \
        --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].id" \
        --output tsv 2>/dev/null || true)"
      if [[ -n "${PENDING}" ]]; then
        while IFS= read -r CONN_ID; do
          [[ -z "${CONN_ID}" ]] && continue
          az network private-endpoint-connection approve --id "${CONN_ID}" \
            --description 'Approved by lab deploy (Front Door Premium origin)' --output none
          echo "    Approved: ${CONN_ID}"
          APPROVED="true"
        done <<< "${PENDING}"
        break
      fi
      sleep 15
    done
    if [[ "${APPROVED}" != "true" ]]; then
      echo "    No pending connection found yet. If Front Door shows an unapproved origin, re-run:"
      echo "      az network private-endpoint-connection list --id ${AGW_ID}"
    fi
  fi
fi
