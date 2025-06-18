#!/usr/bin/env bash
set -euo pipefail

# ensure SFDX source folders exist
mkdir -p force-app/main/default/classes force-app/main/default/triggers

# verify authentication using existing default username
sfdx force:org:display --targetusername "$SFDX_DEFAULTUSERNAME" --json > /dev/null

# retrieve all Apex classes and triggers from the sandbox
sfdx force:source:retrieve -m ApexClass,ApexTrigger --targetusername "$SFDX_DEFAULTUSERNAME"

# stage new or updated files
git add force-app/main/default

# commit and push if there are changes
if git diff --cached --quiet; then
    echo "\u2713 no changes to sync."
else
    git commit -m "chore: sync metadata from sandbox"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$current_branch"
fi

