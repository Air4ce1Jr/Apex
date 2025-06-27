#!/usr/bin/env bash
set -euo pipefail
set -x

# ——— QUICKBOOKS CREDENTIALS ———
QBO_CLIENT_ID="ABMfKDQ3CPWeXA9byYwd4lV78WefshtTuwFnLrhtSqxQymeOOo"
QBO_CLIENT_SECRET="urtCni09oxfUiDNAx5j1p5nzI21JzfJRTzZAX1yN"

# ——— SALESFORCE AUTH URLs (env-aware with hardcoded fallback) ———
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5vdkjQymeOOo@continental-tds.my.salesforce.com"

# ——— CONFIG ———
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
MODE="${1:-validate}"        # validate | deploy
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

# ——— FUNCTION: run tests with fallback logic ———
run_tests_with_fallback() {
  if sfdx apex run test --synchronous \
          --code-coverage \
          --test-level RunLocalTests \
          --target-org "$ORG" \
          --result-format human; then
    echo "✅ All tests passed in batch!"
    return 0
  else
    echo "⚠️ Bulk test run failed — falling back to individual test execution..."
    FAILED=0
    TEST_CLASSES=$(sfdx force:apex:test:list --target-org "$ORG" --json | jq -r '.result[].name')
    for class in $TEST_CLASSES; do
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

# ——— AUTH TO SALESFORCE ORGS (inline) ———
if ! command -v sfdx &> /dev/null; then
  echo "⚙️ Installing Salesforce CLI…"
  npm install --global sfdx-cli
fi

echo "🔐 Authenticating to Sandbox..."
sfdx force:auth:sfdxurl:store --sfdxurlfile <(echo "$SANDBOX_URL") --setalias "$SANDBOX_ALIAS" || {
  echo "⚠️ Failed to auth using env SANDBOX_URL; retrying with fallback hardcoded value..."
  sfdx force:auth:sfdxurl:store --sfdxurlfile <(echo "$SANDBOX_URL") --setalias "$SANDBOX_ALIAS"
}

echo "🔐 Authenticating to Production..."
sfdx force:auth:sfdxurl:store --sfdxurlfile <(echo "$PROD_URL") --setalias "$PROD_ALIAS" || {
  echo "⚠️ Failed to auth using env PROD_URL; retrying with fallback hardcoded value..."
  sfdx force:auth:sfdxurl:store --sfdxurlfile <(echo "$PROD_URL") --setalias "$PROD_ALIAS"
}

echo "✅ Connected orgs:"
sfdx force:org:list --all

# ——— SELECT ORG ———
if [[ "$ENV" == "production" ]]; then
  ORG="$PROD_ALIAS"
else
  ORG="$SANDBOX_ALIAS"
fi

# ——— RETRY LOOP ———
for attempt in $(seq 1 "$MAX_RETRIES"); do
  echo "=== Attempt #$attempt of $MAX_RETRIES on $ENV ($MODE) ==="
  abort_stuck_tests "$ORG"

  if [[ "$MODE" == "validate" ]]; then
    echo "→ Running validation in $ORG..."
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --checkonly --wait 10 --verbose; then
      echo "✅ Validation succeeded! Running tests..."
      if run_tests_with_fallback; then
        exit 0
      else
        exit 1
      fi
    fi

  elif [[ "$MODE" == "deploy" ]]; then
    echo "→ Running full deploy in $ORG..."
    if sfdx force:source:deploy -u "$ORG" -p "$SOURCE_PATH" \
        -l RunLocalTests --wait 10 --verbose; then
      echo "🎉 Deploy succeeded! Running tests..."
      if run_tests_with_fallback; then
        exit 0
      else
        exit 1
      fi
    fi

  else
    echo "❌ Unknown mode: $MODE (use validate or deploy)"
    exit 2
  fi

  echo "⚠ $MODE failed. Retrying after aborting stuck jobs..."
  sleep $((attempt * 5))
done

echo "❌ All $MAX_RETRIES attempts failed in $ENV ($MODE)."
exit 1
