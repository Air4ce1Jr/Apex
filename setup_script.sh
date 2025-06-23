#!/usr/bin/env bash
set -euo pipefail
set -x

# ——— Normalize line endings (optional) ———
# On macOS/Linux you can usually skip this; uncomment if you really need it.
# sed -i 's/\r$//' "${BASH_SOURCE[0]}"

echo ">>> Installing Salesforce CLI (if not already installed)"
npm install -g sfdx-cli

# ——— SANDBOX AUTH ———
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
echo ">>> Authenticating Sandbox (alias: QuickBooksSandbox)"
echo "$SANDBOX_URL" > sandboxAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile sandboxAuthUrl.txt --setalias QuickBooksSandbox
rm sandboxAuthUrl.txt

# ——— PRODUCTION AUTH ———
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"
echo ">>> Authenticating Production (alias: ProductionOrg)"
echo "$PROD_URL" > prodAuthUrl.txt
sfdx force:auth:sfdxurl:store --sfdxurlfile prodAuthUrl.txt --setalias ProductionOrg
rm prodAuthUrl.txt

# ——— SET DEFAULT ORG ———
DEFAULT_USERNAME="QuickBooksSandbox"
echo ">>> Setting default org to Sandbox ($DEFAULT_USERNAME)"
sfdx force:config:set defaultusername="$DEFAULT_USERNAME" --global

# ——— QUICKBOOKS OAUTH2 CREDENTIALS ———
echo ">>> Loading QuickBooks OAuth2 credentials into environment"

QB_CLIENT_ID="ABMfKDQ3CPWeXA9byYwd4lV78WefshtTuwFnLrhtSqxQymeOOo"
QB_CLIENT_SECRET="urtCni09oxfUiDNAx5j1p5nzI21JzfJRTzZAX1yN"
QB_API_ID="181d373a-0721-4e4b-8c82-03a909e56d48"
QB_SANDBOX_COMPANY_ID="9341454816381446"
QB_REDIRECT_URLS="\
https://continental-tds.my.salesforce.com/services/authcallback/Quickbooks,\
https://continental-tds--quickbooks.sandbox.my.salesforce.com/services/authcallback/Quickbooks,\
https://developer.intuit.com/v2/OAuth2Playground/RedirectUrl\
"

export QBO_CLIENT_ID="$QB_CLIENT_ID"
export QBO_CLIENT_SECRET="$QB_CLIENT_SECRET"
export QBO_API_ID="$QB_API_ID"
export QBO_SANDBOX_COMPANY_ID="$QB_SANDBOX_COMPANY_ID"
export QBO_REDIRECT_URLS="$QB_REDIRECT_URLS"

ENV_FILE=".env"
echo ">>> Persisting QuickBooks creds to $ENV_FILE (add to .gitignore!)"
cat > "$ENV_FILE" <<EOF
# QuickBooks OAuth2 settings
QBO_CLIENT_ID=$QB_CLIENT_ID
QBO_CLIENT_SECRET=$QB_CLIENT_SECRET
QBO_API_ID=$QB_API_ID
QBO_SANDBOX_COMPANY_ID=$QB_SANDBOX_COMPANY_ID
QBO_REDIRECT_URLS=$QB_REDIRECT_URLS
EOF

echo ">>> Environment setup complete. Connected orgs:"
sfdx force:org:list --all

echo ">>> Done. You can now `sfdx force:org:open -u QuickBooksSandbox` or `-u ProductionOrg`"
