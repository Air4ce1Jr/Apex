#!/usr/bin/env bash
set -euo pipefail
set -x

### ——— CONFIGURATION ———
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
MODE="${1:-test}"            # Options: test | validate | deploy
ORG_TARGET="${2:-sandbox}"   # Options: sandbox or production
SOURCE_PATH="force-app/main/default"

### ——— HELPER: Abort stuck Apex Test jobs ———
abort_stuck_tests() {
  local ORG="$1"
  echo ">>> Checking for queued ApexTestQueueItem in $ORG..."
  local QUEUED_IDS
  QUEUED_IDS=$(sfdx force:data:soql:query -u "$ORG" \
    -q "SELECT Id FROM ApexTestQueueItem WHERE Status='Queued'" --json \
    | jq -r '.result.records[].Id' || true)
  
  if [[ -z "$QUEUED_IDS" ]]; then
    echo "✔️ No queued jobs."
  else
    echo "⚠️ Found queued jobs: $QUEUED_IDS – aborting..."
    for id in $QUEUED_IDS; do
      sfdx force:data:record:update \
        -s ApexTestQueueItem -i "$id" -v "Status='Aborted'" -u "$ORG"
      echo "→ Aborted job $id"
    done
  fi
}

### ——— STEP 1: Authenticate Orgs ———
echo "Authenticating to Sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store -f sandboxAuthUrl.txt -a "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

echo "Authenticating to Production..."
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store -f prodAuthUrl.txt -a "$PROD_ALIAS"
rm prodAuthUrl.txt

echo "✅ Connected orgs:"
sfdx org list --all

### ——— STEP 2: Decide target org ———
if [[ "$ORG_TARGET" == "production" ]]; then
  ORG="$PROD_ALIAS"
elif [[ "$ORG_TARGET" == "sandbox" ]]; then
  ORG="$SANDBOX_ALIAS"
else
  echo "❌ Invalid ORG_TARGET: $ORG_TARGET"
  exit 1
fi

### ——— STEP 3: Run requested operation ———
case "$MODE" in
  test)
    abort_stuck_tests "$ORG"
    echo "→ Running Apex tests on $ORG..."
    sfdx apex run test \
      -o "$ORG" \
      -c \
      -r human \
      --wait 10 --synchronous
    ;;
  
  validate)
    abort_stuck_tests "$ORG"
    echo "→ Validating deployment on $ORG..."
    sfdx force:source:deploy \
      -u "$ORG" \
      -p "$SOURCE_PATH" \
      -l RunLocalTests \
      --checkonly --wait 10 --verbose
    ;;
  
  deploy)
    abort_stuck_tests "$ORG"
    echo "→ Deploying to $ORG..."
    sfdx force:source:deploy \
      -u "$ORG" \
      -p "$SOURCE_PATH" \
      -l RunLocalTests \
      --wait 10 --verbose
    ;;
  
  *)
    echo "❌ Unknown MODE: $MODE (use test|validate|deploy)"
    exit 1
    ;;
esac

echo "✅ $MODE operation completed on $ORG."
