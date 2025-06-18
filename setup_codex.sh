#!/usr/bin/env bash
set -euo pipefail
set -x

#–– 1. Ensure required env-vars are set
: "${SFDX_AUTH_URL:?Environment variable SFDX_AUTH_URL must be set}"
: "${SFDX_DEFAULTUSERNAME:?Environment variable SFDX_DEFAULTUSERNAME must be set}"

#–– 2. Install Node.js & npm if missing (Debian/Ubuntu)
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo ">>> Installing Node.js and npm"
  apt-get update
  apt-get install -y nodejs npm
fi

#–– 3. Install the Salesforce CLI
echo ">>> Installing sfdx-cli via npm"
npm install -g sfdx-cli

#–– 4. Authenticate using the SFDX URL
echo ">>> Authenticating to sandbox via SFDX_AUTH_URL"
printf '%s' "$SFDX_AUTH_URL" > sfdxAuthUrl.txt
sfdx force:auth:sfdxurl:store \
     --setalias QuickBooksSandbox \
     --filename sfdxAuthUrl.txt
rm sfdxAuthUrl.txt

#–– 5. Configure your default username
echo ">>> Setting defaultusername to $SFDX_DEFAULTUSERNAME"
sfdx force:config:set defaultusername="$SFDX_DEFAULTUSERNAME" --global

#–– 6. Verify org connection
echo ">>> Org info:"
sfdx force:org:display --targetusername "$SFDX_DEFAULTUSERNAME" --json
