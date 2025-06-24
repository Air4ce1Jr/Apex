#!/usr/bin/env bash
set -euo pipefail
set -x

# ——— CONFIG ———
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
MODE="${1:-validate}"       # validate | deploy
ENV="${2:-sandbox}"          # sandbox | production
SOURCE_PATH="force-app/main/default"
MAX_RETRIES=3

# ——— FUNCTION: abort stuck Apex test jobs ———
abort_stuck_tests() {
  local ORG="$1"
  echo "» Checking for stuck Apex test jobs in $ORG..."
  local IDS
  IDS=$(sfdx force:data:soql:query -u "$ORG" \
    -q "SELECT Id FROM ApexTestQueueItem WHERE Status='Queued'" --json \
    | jq -r '.result.records[].Id' || true)

  [[ -z "$IDS" ]] && { echo "✔ No queued jobs."; return; }

  echo "⚠ Found queued jobs: $IDS — aborting..."
  for id in $IDS; do
    sfdx force:data:record:update -s ApexTestQueueItem -i "$id" \
      -v "Status='Aborted'" -u "$ORG" || echo "⚠ Failed to abort $id"
    echo "→ Aborted queue item $id"
  done
}

# ——— AUTH ———
echo "🔐 Authenticating sandbox..."
echo "$SANDBOX_URL" > sb.txt
sfdx force:auth:sfdxurl:store -f sb.txt -a "$SANDBOX_ALIAS"
rm sb.txt

echo "🔐 Authenticating production..."
echo "$PROD_URL" > prod.txt
sfdx force:auth:sfdxurl:store -f prod.txt -a "$PROD_ALIAS"
rm prod.txt

echo "✅ Connected orgs:"
sfdx force:org:list --all

# ——— PREP: SELECT ORG ———
if [[ "$ENV" == "production" ]]; then ORG="$PROD_ALIAS"; else ORG="$SANDBOX_ALIAS"; fi

# ——— STEP: RETRY LOOP ———
for attempt in $(seq 1 $MAX_RETRIES); do
  echo "=== Attempt #$attempt of $MAX_RETRIES on $ENV ($MODE) ==="

  abort_stuck_tests "$ORG"

  if [[ "$MODE" == "validate" ]]; then
    echo "→ Running validation in $ORG..."
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --checkonly --wait 10 --verbose; then
      echo "✅ Validation succeeded!"
      exit 0
    fi

  elif [[ "$MODE" == "deploy" ]]; then
    echo "→ Running full deploy in $ORG..."
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --wait 10 --verbose; then
      echo "🎉 Deploy succeeded!"
      exit 0
    fi

  else
    echo "❌ Unknown mode: $MODE (use validate or deploy)"
    exit 2
  fi

  echo "⚠ $MODE failed. Checking if retryable..."
  abort_stuck_tests "$ORG"
  sleep $((attempt * 5))  # exponential backoff
done

echo "❌ All $MAX_RETRIES attempts failed in $ENV ($MODE)."
exit 1
