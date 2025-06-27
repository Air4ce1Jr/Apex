#!/usr/bin/env bash
set -euo pipefail
set -x

# ——— QUICKBOOKS CREDENTIALS ———
QBO_CLIENT_ID="ABMfKDQ3CPWeXA9byYwd4lV78WefshtTuwFnLrhtSqxQymeOOo"
QBO_CLIENT_SECRET="urtCni09oxfUiDNAx5j1p5nzI21JzfJRTzZAX1yN"

# ——— SALESFORCE AUTH URLs ———
SANDBOX_URL="force://PlatformCLI::SANDBOX_AUTH_TOKEN@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::PROD_AUTH_TOKEN@continental-tds.my.salesforce.com"

# ——— CONFIG ———
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
MODE="${1:-validate}"        # validate | deploy | test
ENV="${2:-sandbox}"          # sandbox | production
SOURCE_PATH="force-app/main/default"
MAX_RETRIES=3

# ——— FUNCTION: Abort Stuck Apex Test Jobs ———
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

# ——— AUTH TO SALESFORCE ORGS ———
npm install --global sfdx-cli

echo "🔐 Authenticating to Sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

echo "🔐 Authenticating to Production..."
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias "$PROD_ALIAS"
rm prodAuthUrl.txt

echo "✅ Connected orgs:"
sfdx force:org:list --all

# ——— SELECT ORG ———
if [[ "$ENV" == "production" ]]; then
  ORG="$PROD_ALIAS"
else
  ORG="$SANDBOX_ALIAS"
fi

# ——— EXECUTION BLOCK ———
TEST_CLASSES=("QuickBooksInvoiceTest" "CustomerInvoiceTriggerTest" "QuickBooksSyncJobTest")
TEST_CLASS_LIST=$(IFS=, ; echo "${TEST_CLASSES[*]}")

run_tests_with_fallback() {
  if sfdx apex run test --synchronous \
          --code-coverage \
          --test-level RunSpecifiedTests \
          --tests "$TEST_CLASS_LIST" \
          --target-org "$ORG" \
          --result-format human; then
    echo "✅ All tests passed together!"
    return 0
  else
    echo "⚠️ Bulk test run failed — falling back to individual test execution..."
    FAILED=0
    for class in "${TEST_CLASSES[@]}"; do
      echo "→ Running test: $class"
      if sfdx apex run test --synchronous \
              --code-coverage \
              --test-level RunSpecifiedTests \
              --tests "$class" \
              --target-org "$ORG" \
              --result-format human; then
        echo "✅ $class passed"
      else
        echo "❌ $class failed"
        FAILED=1
      fi
    done

    if [[ "$FAILED" -eq 1 ]]; then
      echo "❌ One or more test classes failed."
      return 1
    else
      echo "✅ All individual tests passed."
      return 0
    fi
  fi
}

if [[ "$MODE" == "validate" ]]; then
  for attempt in $(seq 1 "$MAX_RETRIES"); do
    echo "=== Attempt #$attempt of $MAX_RETRIES on $ENV ($MODE) ==="
    abort_stuck_tests "$ORG"
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --checkonly --wait 10 --verbose; then
      echo "✅ Validation deploy succeeded. Running tests..."
      if run_tests_with_fallback; then
        exit 0
      else
        exit 1
      fi
    fi
    echo "⚠ $MODE failed. Retrying after aborting stuck jobs..."
    sleep $((attempt * 5))
  done
  echo "❌ All $MAX_RETRIES attempts failed in $ENV ($MODE)."
  exit 1

elif [[ "$MODE" == "deploy" ]]; then
  for attempt in $(seq 1 "$MAX_RETRIES"); do
    echo "=== Attempt #$attempt of $MAX_RETRIES on $ENV ($MODE) ==="
    abort_stuck_tests "$ORG"
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --wait 10 --verbose; then
      echo "🎉 Deployment succeeded. Running tests..."
      if run_tests_with_fallback; then
        exit 0
      else
        exit 1
      fi
    fi
    echo "⚠ $MODE failed. Retrying after aborting stuck jobs..."
    sleep $((attempt * 5))
  done
  echo "❌ All $MAX_RETRIES attempts failed in $ENV ($MODE)."
  exit 1

elif [[ "$MODE" == "test" ]]; then
  echo "→ Running Apex tests in $ORG (synchronously, with fallback)..."
  if run_tests_with_fallback; then
    exit 0
  else
    exit 1
  fi

else
  echo "❌ Unknown mode: $MODE (use validate, deploy, or test)"
  exit 2
fi
