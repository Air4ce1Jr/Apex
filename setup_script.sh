#!/usr/bin/env bash
set -euo pipefail
set -x


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
DEFAULT_USERNAME="QuickBooksSandbox"
echo ">>> Setting default username to sandbox ($DEFAULT_USERNAME)"
sfdx force:config:set defaultusername="$DEFAULT_USERNAME" --global

echo ">>> Displaying connected orgs"
sfdx force:org:list --all

# ——— QUICKBOOKS OAUTH2 CREDENTIALS ———
echo ">>> Injecting QuickBooks OAuth2 credentials into environment"

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

# Persist for local development / CI
ENV_FILE=".env"
echo ">>> Writing QuickBooks creds to $ENV_FILE (add this to .gitignore!)"
cat > "$ENV_FILE" <<EOF
# QuickBooks OAuth2 settings
QBO_CLIENT_ID=$QB_CLIENT_ID
QBO_CLIENT_SECRET=$QB_CLIENT_SECRET
QBO_API_ID=$QB_API_ID
QBO_SANDBOX_COMPANY_ID=$QB_SANDBOX_COMPANY_ID
QBO_REDIRECT_URLS=$QB_REDIRECT_URLS
EOF

echo ">>> QuickBooks environment variables set."

# ——— VALIDATE & DEPLOY WORKFLOW ———
SOURCE_PATH="force-app/main/default"

run_validate() {
  local ORG="$1"
  echo ">>> Validating on $ORG (check-only, running tests)…"
  sfdx force:source:deploy \
    --targetusername "$ORG" \
    --sourcepath "$SOURCE_PATH" \
    --testlevel RunLocalTests \
    --checkonly \
    --wait 10 \
    --verbose
  return $?
}

# 1) Sandbox check-only
run_validate QuickBooksSandbox
if [[ $? -ne 0 ]]; then
  echo "!!! Sandbox validation FAILED. Fix errors above."
  exit 2
else
  echo "✅ Sandbox validation passed."
fi

# 2) Prod check-only
run_validate ProductionOrg
if [[ $? -ne 0 ]]; then
  echo "!!! Production check-only validation FAILED. Fix errors above."
  exit 2
else
  echo "✅ Production check-only validation passed."
fi

# 3) Final deploy to prod
read -p "All checks passed. Proceed with full deploy to production? (y/N) " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ">>> Deploying to ProductionOrg (this will run tests and commit)…"
  sfdx force:source:deploy \
    --targetusername ProductionOrg \
    --sourcepath "$SOURCE_PATH" \
    --testlevel RunLocalTests \
    --wait 10 \
    --verbose
  if [[ $? -eq 0 ]]; then
    echo "🎉 Deployment to ProductionOrg complete."
  else
    echo "!!! Deployment to ProductionOrg FAILED. Check errors above."
    exit 2
  fi
else
  echo "⏸ Deployment aborted by user."
fi
