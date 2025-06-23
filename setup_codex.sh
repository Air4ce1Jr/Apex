#!/usr/bin/env bash
set -euo pipefail
set -x

### === CONFIGURATION ===
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"

SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"

SOURCE_PATH="force-app/main/default"
MODE="${1:-test}"   # test, validate, or deploy
ORG_TARGET="${2:-sandbox}"  # sandbox or production


### === STEP 1: Internet + SFDX Checks ===
echo ">>> Checking internet connection..."
curl -Is https://login.salesforce.com | grep HTTP || { echo "❌ ERROR: No internet access"; exit 1; }

echo ">>> Verifying sfdx CLI..."
if ! command -v sfdx >/dev/null 2>&1; then
  echo "⚠️ Installing Node and Salesforce CLI..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  npm install -g sfdx-cli
  hash -r
fi

echo "✅ SFDX version: $(sfdx --version)"


### === STEP 2: Authenticate Orgs ===
echo ">>> Authenticating Sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

echo ">>> Authenticating Production..."
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias "$PROD_ALIAS"
rm prodAuthUrl.txt

echo ">>> Connected Orgs:"
sfdx force:org:list --all


### === STEP 3: Determine Org Target ===
if [[ "$ORG_TARGET" == "sandbox" ]]; then
  ORG="$SANDBOX_ALIAS"
elif [[ "$ORG_TARGET" == "production" ]]; then
  ORG="$PROD_ALIAS"
else
  echo "❌ Invalid org target: $ORG_TARGET (must be 'sandbox' or 'production')"
  exit 1
fi

### === STEP 4: Run Selected Mode ===
case "$MODE" in
  test)
    echo ">>> Running Apex tests against $ORG"
    sfdx force:apex:test:run \
      --targetusername "$ORG" \
      --codecoverage \
      --resultformat human \
      --outputdir test-results \
      --wait 10 \
      --synchronous \
      --loglevel DEBUG
    ;;

  validate)
    echo ">>> Running validation-only deploy against $ORG"
    sfdx force:source:deploy \
      --targetusername "$ORG" \
      --sourcepath "$SOURCE_PATH" \
      --testlevel RunLocalTests \
      --checkonly \
      --wait 10 \
      --verbose \
      --loglevel DEBUG
    ;;

  deploy)
    echo ">>> Deploying to $ORG (tests WILL run)"
    sfdx force:source:deploy \
      --targetusername "$ORG" \
      --sourcepath "$SOURCE_PATH" \
      --testlevel RunLocalTests \
      --wait 10 \
      --verbose \
      --loglevel DEBUG
    ;;

  *)
    echo "❌ Invalid mode: $MODE (must be 'test', 'validate', or 'deploy')"
    exit 1
    ;;
esac

echo "✅ Operation '$MODE' completed on $ORG"
