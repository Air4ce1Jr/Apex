# Codex Agent Guide

## 1. Setup
- **Setup script**: `./setup_codex.sh`
- **Required env vars**:
  - `SFDX_AUTH_URL` — OAuth web sfdxAuthUrl for your sandbox
  - `SFDX_DEFAULTUSERNAME` — username or alias of your sandbox org
- **Allowed network** (setup phase only):
  - `registry.npmjs.org`    (to install sfdx-cli)
  - `test.salesforce.com`   (sandbox auth & metadata)
  - `login.salesforce.com`  (if verifying against prod login)

## 2. Validation & Testing
1. **Run Apex tests** (must achieve **≥ 90%** code coverage):
   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human

sfdx force:source:deploy \
  --checkonly \
  -p force-app/main/default \
  --testlevel RunLocalTests
