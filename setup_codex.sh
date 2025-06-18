#!/usr/bin/env bash
set -euo pipefail   # exit on any error, undefined var, or failed pipe
set -x               # echo each command before running it

# Normalize this script’s line endings (strip any stray CRs)
sed -i 's/\r$//' "$0"

echo ">>> Installing Salesforce CLI"
npm install -g sfdx-cli

# Non-interactive auth via the OAuth URL
echo "$SFDX_AUTH_URL" | sfdx force:auth:sfdxurl:store --setalias QuickBooksSandbox

echo ">>> Setting default username"
sfdx force:config:set defaultusername=$SFDX_DEFAULTUSERNAME

echo ">>> Displaying org info"
sfdx force:org:display --targetusername $SFDX_DEFAULTUSERNAME --json
