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
