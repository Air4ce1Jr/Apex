# Codex Agent Guide

## Setup

* **Setup script**: `./setup_codex.sh` (currently runs `sfdx force:config:list`)

* **Authentication (interactive web login)**:

  1. Open the sandbox login page:

     ```
     https://continental-tds--quickbooks.sandbox.my.salesforce.com/
     ```
  2. Log in with:

     * Username: `admin@continental-tds.com.quickbooks`
     * Password: `REV2025tbl7!`
  3. In the Codex container terminal, run:

     ```bash
     sfdx auth:web:login \
       --instanceurl https://continental-tds--quickbooks.sandbox.my.salesforce.com \
       --setalias MySandbox
     ```

* **Required environment variable**:

  * `SFDX_DEFAULTUSERNAME=MySandbox`

* **Allowed network domains**:

  * `continental-tds--quickbooks.sandbox.my.salesforce.com`
  * `login.salesforce.com`
  * `registry.npmjs.org` (for CLI install)

## Validation & Testing

1. **Run Apex tests** (minimum 90% code coverage):

   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
   ```
2. **Validate-only deployment** (no changes applied):

   ```bash
   sfdx force:source:deploy \
     --checkonly \
     -p force-app/main/default \
     --testlevel RunLocalTests
   ```

## Pull Request Template

* **Title format**: `[QuickBooks→Salesforce] <short summary>`
* **Body**:

  1. Summary of changes
  2. Test coverage report
  3. Validation-only report output
