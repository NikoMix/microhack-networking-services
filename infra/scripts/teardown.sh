#!/usr/bin/env bash
# Tear down the CFS lab landing zone by deleting its resource groups.
# Requires --confirm DELETE to avoid accidental deletion.
set -euo pipefail

NAME_PREFIX="cfs"
REGION_TOKEN="swc"
CONFIRM=""
NO_WAIT="false"

usage() {
  echo "Usage: $0 --confirm DELETE [--name-prefix cfs] [--region-token swc] [--no-wait]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --confirm) CONFIRM="$2"; shift 2 ;;
    --name-prefix) NAME_PREFIX="$2"; shift 2 ;;
    --region-token) REGION_TOKEN="$2"; shift 2 ;;
    --no-wait) NO_WAIT="true"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [[ "${CONFIRM}" != "DELETE" ]]; then
  echo "Refusing to tear down: pass --confirm DELETE to proceed." >&2
  exit 1
fi

if ! az account show --output none 2>/dev/null; then
  echo "Not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi
az account show --query "{subscription:name,id:id}" --output tsv

RESOURCE_GROUPS=(
  "rg-${NAME_PREFIX}-hub-${REGION_TOKEN}"
  "rg-${NAME_PREFIX}-spoke-${REGION_TOKEN}"
  "rg-${NAME_PREFIX}-mgmt-${REGION_TOKEN}"
)

for rg in "${RESOURCE_GROUPS[@]}"; do
  if [[ "$(az group exists --name "${rg}")" != "true" ]]; then
    echo "==> ${rg} does not exist — skipping."
    continue
  fi
  echo "==> Deleting resource group ${rg} ..."
  if [[ "${NO_WAIT}" == "true" ]]; then
    az group delete --name "${rg}" --yes --no-wait
  else
    az group delete --name "${rg}" --yes
  fi
done

echo "==> Teardown requested. Note: VPN/Firewall deletes can take 10-20 min."
