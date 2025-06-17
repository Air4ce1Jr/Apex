#!/usr/bin/env bash
npm install -g sfdx-cli

# Non-interactive auth: reads from SFDX_AUTH_URL
echo "$SFDX_AUTH_URL" | sfdx auth:sfdxurl:store --setalias QuickBooksSandbox

# Set the default username so you don’t need --targetusername flags everywhere
sfdx force:config:set defaultusername=$SFDX_DEFAULTUSERNAME

# Verify you’re connected
sfdx force:org:display --targetusername $SFDX_DEFAULTUSERNAME --json
