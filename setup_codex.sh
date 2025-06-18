#!/usr/bin/env bash
set -euo pipefail
set -x

# Normalize line endings
sed -i 's/\r$//' "$0"

echo ">>> Installing Salesforce CLI"
npm install -g sfdx-cli

echo ">>> Authenticating via SFDX_AUTH_URL"
echo "$SFDX_AUTH_URL" > sfdxAuthUrl.txt
# note: -f maps to --sfdx-url-file, -a maps to --alias
sfdx force:auth:sfdxurl:store --sfdxurlfile sfdxAuthUrl.txt --setalias QuickBooksSandbox
rm sfdxAuthUrl.txt

echo ">>> Setting default username"
sfdx force:config:set defaultusername="$SFDX_DEFAULTUSERNAME" --global

echo ">>> Displaying org info"
sfdx force:org:display --targetusername "$SFDX_DEFAULTUSERNAME" --json
