#!/usr/bin/env bash
set -euo pipefail
set -x

### === CONFIGURATION ===
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"
SOURCE_PATH="force-app/main/default"
MODE="${1:-test}"             # Options: test, validate, deploy
ORG_TARGET="${2:-sandbox}"   # Options: sandbox or production

### === STEP 1: Internet Check ===
echo ">>> Checking internet access..."
curl -Is https://login.salesforce.com | grep HTTP || { echo "❌ ERROR: No internet access"; exit 1; }

### === STEP 2: Node.js + SFDX Install (no sudo) ===
echo ">>> Ensuring local Node.js + SFDX CLI..."

if ! command -v sfdx >/dev/null; then
  echo ">>> Installing Node.js (no sudo)..."

  NODE_VERSION="v18.18.0"
  NODE_DISTRO="linux-x64"
  NODE_ARCHIVE="node-$NODE_VERSION-$NODE_DISTRO.tar.xz"
  curl -fsSL "https://nodejs.org/dist/$NODE_VERSION/$NODE_ARCHIVE" -o node.tar.xz
  mkdir -p "$HOME/.local/node"
  tar -xf node.tar.xz -C "$HOME/.local/node" --strip-components=1
  rm node.tar.xz
  export PATH="$HOME/.local/node/bin:$PATH"

  echo ">>> Configuring npm for unreliable networks..."
  npm config set fetch-retry-maxtimeout 120000   # max 2 minutes :contentReference[oaicite:6]{index=6}
  npm config set fetch-retry-mintimeout 20000    # min 20 seconds :contentReference[oaicite:7]{index=7}
  npm config set prefer-offline true             # use cache first :contentReference[oaicite:8]{index=8}

  retry_npm_install() {
    local tries=0
    until npm install -g sfdx-cli --prefer-offline; do
      ((tries++))
      echo "⚠️ npm install failed (try #$tries). Retrying..."
      sleep 5
      [[ $tries -gt 3 ]] && { echo "❌ npm install failed after $tries tries"; exit 1; }
    done
  }

  echo ">>> Installing Salesforce CLI with retries..."
  retry_npm_install
  hash -r
fi

echo "✅ Installed: sfdx v$(sfdx --version), node v$(node -v)"

### === STEP 3: Authenticate Orgs ===
echo ">>> Authenticating Sandbox..."
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias "$SANDBOX_ALIAS"
rm sandboxAuthUrl.txt

echo ">>> Authenticating Production..."
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias "$PROD_ALIAS"
rm prodAuthUrl.txt

echo "✅ Connected orgs:"
sfdx force:org:list --all

### === STEP 4: Select Org ===
if [[ "$ORG_TARGET" == "production" ]]; then
  ORG="$PROD_ALIAS"
elif [[ "$ORG_TARGET" == "sandbox" ]]; then
  ORG="$SANDBOX_ALIAS"
else
  echo "❌ Invalid org target: $ORG_TARGET"
  exit 1
fi

### === STEP 5: Execute Mode ===
case "$MODE" in
  test)
    echo "→ Running Apex tests on $ORG"
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
    echo "→ Validating deployment on $ORG"
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
    echo "→ Deploying to $ORG (tests WILL run)"
    sfdx force:source:deploy \
      --targetusername "$ORG" \
      --sourcepath "$SOURCE_PATH" \
      --testlevel RunLocalTests \
      --wait 10 \
      --verbose \
      --loglevel DEBUG
    ;;
  *)
    echo "❌ Unknown mode: $MODE (use 'test', 'validate', or 'deploy')"
    exit 1
    ;;
esac

echo "✅ '$MODE' completed on $ORG"
