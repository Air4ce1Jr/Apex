#!/usr/bin/env bash
set -euo pipefail   # exit on any error, undefined var, or failed pipe
set -x  
npm install -g sfdx-cli

# install dos2unix if you don’t have it (macOS: brew install dos2unix)
dos2unix setup_codex.sh

echo ">>> Installing Salesforce CLI"
npm install -g sfdx-cli

echo ">>> Authenticating via SFDX_AUTH_URL"
echo "$SFDX_AUTH_URL" | sfdx auth:sfdxurl:store --setalias QuickBooksSandbox

echo ">>> Setting default username"
sfdx force:config:set defaultusername=$SFDX_DEFAULTUSERNAME

echo ">>> Displaying org info"
sfdx force:org:display --targetusername $SFDX_DEFAULTUSERNAME --json

