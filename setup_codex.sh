#!/usr/bin/env bash
set -euo pipefail
set -x

# normalize line endings in this script
sed -i 's/\r$//' "$0"

echo ">>> Installing Salesforce CLI"
npm install -g sfdx-cli

# ——— SANDBOX AUTH ———
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
echo ">>> Authenticating sandbox org (alias: QuickBooksSandbox)"
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias QuickBooksSandbox
rm sandboxAuthUrl.txt

# ——— PRODUCTION AUTH ———
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"
echo ">>> Authenticating production org (alias: ProductionOrg)"
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias ProductionOrg
rm prodAuthUrl.txt

# ——— SET DEFAULT USER ———
# (Still pick the alias you prefer; here we default to the sandbox.)
DEFAULT_USERNAME="QuickBooksSandbox"
echo ">>> Setting default username to sandbox ($DEFAULT_USERNAME)"
sfdx force:config:set defaultusername="$DEFAULT_USERNAME" --global

echo ">>> Displaying connected orgs"
sfdx force:org:list --all
