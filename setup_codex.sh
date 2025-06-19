#!/usr/bin/env bash
set -euo pipefail
set -x

# Normalize line endings
sed -i 's/\r$//' "$0"

echo ">>> Installing Salesforce CLI"
npm install -g sfdx-cli

# ——— SANDBOX AUTH ———
if [ -z "${SFDX_AUTH_URL:-}" ]; then
  echo "ERROR: \$SFDX_AUTH_URL is not set" >&2
  exit 1
fi
echo ">>> Authenticating sandbox org (alias: QuickBooksSandbox)"
echo "$SFDX_AUTH_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias QuickBooksSandbox
rm sandboxAuthUrl.txt

# ——— PRODUCTION AUTH ———
if [ -z "${SFDX_PROD_AUTH_URL:-}" ]; then
  echo "ERROR: \$SFDX_PROD_AUTH_URL is not set" >&2
  exit 1
fi
echo ">>> Authenticating production org (alias: ProductionOrg)"
echo "$SFDX_PROD_AUTH_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias ProductionOrg
rm prodAuthUrl.txt

# ——— CONFIGURE DEFAULT USER ———
if [ -z "${SFDX_DEFAULTUSERNAME:-}" ]; then
  echo "ERROR: \$SFDX_DEFAULTUSERNAME is not set" >&2
  exit 1
fi
echo ">>> Setting default username to sandbox ($SFDX_DEFAULTUSERNAME)"
sfdx force:config:set defaultusername="$SFDX_DEFAULTUSERNAME" --global

echo ">>> Displaying connected orgs"
sfdx force:org:list --all
