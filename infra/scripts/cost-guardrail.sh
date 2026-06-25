#!/usr/bin/env bash
# Report current month-to-date cost for the CFS lab resource groups and check the budget.
# Read-only — creates/changes nothing.
set -euo pipefail

NAME_PREFIX="cfs"
REGION_TOKEN="swc"
BUDGET_NAME="cfs-lab-budget-swc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name-prefix) NAME_PREFIX="$2"; shift 2 ;;
    --region-token) REGION_TOKEN="$2"; shift 2 ;;
    --budget-name) BUDGET_NAME="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--name-prefix cfs] [--region-token swc] [--budget-name <name>]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if ! az account show --output none 2>/dev/null; then
  echo "Not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi
az account show --query "{subscription:name,id:id}" --output tsv

echo "==> Month-to-date usage (may lag ~8-24h)..."
if ! az consumption usage list --output table 2>/dev/null; then
  echo "    No usage data returned yet (new subscriptions can take a day)."
fi

echo "==> Budget status for ${BUDGET_NAME}..."
if ! az consumption budget show --budget-name "${BUDGET_NAME}" \
      --query "{name:name,amount:amount,timeGrain:timeGrain,currentSpend:currentSpend.amount}" \
      --output jsonc 2>/dev/null; then
  echo "    Budget '${BUDGET_NAME}' not found. Deploy with budgetContactEmails set to create it."
fi
