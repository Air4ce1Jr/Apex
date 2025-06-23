#!/usr/bin/env bash
set -euo pipefail
set -x

### === CONFIGURATION ===
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"
SOURCE_PATH="force-app/main/default"
MODE="${1:-test}"                # test, validate, or deploy
ORG_TARGET="${2:-sandbox}"      # sandbox or production

### === STEP 1: Internet Check ===
echo ">>> Checking internet access..."
curl -Is https://login.salesforce.com | grep HTTP || { echo "❌ No internet access"; exit 1; }

### === STEP 2: Node.js + SFDX Install (no sudo) ===
echo ">>> Ensuring local Node.js + SFDX CLI..."

if ! command -v sfdx >/dev/null; then
  echo "Installing Node.js (no sudo)..."
  NODE_VERSION="v18.18.0"
  NODE_DISTRO="linux-x64"
  NODE_ARCHIVE="node-$NODE_VERSION-$NODE_DISTRO.tar.xz"
  curl -fsSL "https://nodejs.org/dist/$NODE_VERSION/$NODE_ARCHIVE" -o node.tar.xz
  mkdir -p "$HOME/.local/node"
  tar -xf node.tar.xz -C "$HOME/.local/node" --strip-components=1
  rm node.tar.xz
  export PATH="$HOME/.local/node/bin:$PATH"

  echo "Configuring npm for unreliable networks..."
  npm config set fetch-retry-maxtimeout 600000
  npm config set fetch-retry-mintimeout 120000
  npm config set prefer-offline true
  npm config set and true # placeholder

  retry_npm_install() {
    local tries=0
    until npm install -g sfdx-cli --prefer-offline; do
      ((tries++))
      echo "⚠️ npm install failed (try #$tries). Retrying..."
      sleep 5
      [[ $tries -gt 3 ]] && { echo "❌ npm install failed after $tries tries"; exit 1; }
    done
  }

  echo "Installing Salesforce CLI with retries..."
  retry_npm_install
  hash -r
fi

echo "✅ SFDX v$(sfdx --version), Node v$(node -v)"

### === STEP 3: Authenticate Orgs ===
echo "Authenticating Sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

echo "Authenticating Production..."
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias "$PROD_ALIAS"
rm prodAuthUrl.txt

echo "Connected orgs:"
sfdx force:org:list --all

### === STEP 4: Choose Org ===
ORG="$([[ "$ORG_TARGET" == "production" ]] && echo "$PROD_ALIAS" || echo "$SANDBOX_ALIAS")"

### === STEP 5: Run Mode ===
case "$MODE" in
  test)
    echo "→ Running Apex tests on $ORG"
    sfdx force:apex:test:run --targetusername "$ORG" --codecoverage \
      --resultformat human --outputdir test-results \
      --wait 10 --synchronous --loglevel DEBUG
    ;;
  validate)
    echo "→ Validating deploy on $ORG"
    sfdx force:source:deploy --targetusername "$ORG" --sourcepath "$SOURCE_PATH" \
      --testlevel RunLocalTests --checkonly --wait 10 \
      --verbose --loglevel DEBUG
    ;;
  deploy)
    echo "→ Deploying to $ORG"
    sfdx force:source:deploy --targetusername "$ORG" --sourcepath "$SOURCE_PATH" \
      --testlevel RunLocalTests --wait 10 --verbose --loglevel DEBUG
    ;;
  *)
    echo "❌ Unknown mode '$MODE'. Use test|validate|deploy."; exit 1
    ;;
esac

echo "✅ '$MODE' completed on $ORG"
