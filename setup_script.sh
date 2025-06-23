#!/usr/bin/env bash
set -euo pipefail
set -x

### === CONFIGURATION ===
# Replace these URLs with yours if needed
SANDBOX_ALIAS="QuickBooksSandbox"
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"

# Directory containing metadata
SOURCE_PATH="force-app/main/default"


### === STEP 1: Check Internet Access ===
echo ">>> Checking internet access to Salesforce..."
if ! curl -Is https://login.salesforce.com | grep -q "HTTP"; then
  echo "❌ ERROR: No internet access or DNS resolution failed"
  exit 1
fi

### === STEP 2: Check/install Node and SFDX ===
echo ">>> Checking for sfdx CLI..."
if ! command -v sfdx >/dev/null 2>&1; then
  echo "⚠️  sfdx CLI not found. Installing via npm..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  npm install -g sfdx-cli
  hash -r
fi

echo "✅ SFDX CLI version: $(sfdx --version)"

### === STEP 3: Re-authenticate to Sandbox ===
echo ">>> Authenticating to sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

### === STEP 4: Validate Auth and Org Access ===
echo ">>> Confirming connected orgs..."
sfdx force:org:list --all || { echo "❌ ERROR: Authentication failed"; exit 1; }

### === STEP 5: Run Test or Deploy Command ===

MODE="${1:-test}"  # default to test mode

if [[ "$MODE" == "test" ]]; then
  echo ">>> Running Apex tests (with coverage)..."
  sfdx force:apex:test:run \
    --targetusername "$SANDBOX_ALIAS" \
    --codecoverage \
    --resultformat human \
    --outputdir test-results \
    --wait 10 \
    --synchronous \
    --loglevel DEBUG

elif [[ "$MODE" == "validate" ]]; then
  echo ">>> Running validation-only deploy..."
  sfdx force:source:deploy \
    --targetusername "$SANDBOX_ALIAS" \
    --sourcepath "$SOURCE_PATH" \
    --testlevel RunLocalTests \
    --checkonly \
    --wait 10 \
    --verbose \
    --loglevel DEBUG
else
  echo "❌ ERROR: Unknown mode '$MODE'. Use 'test' or 'validate'."
  exit 1
fi

echo "✅ Finished successfully."
