# Codex Agent Guide

## 1. Setup

* **Setup script**: `./setup_codex.sh`
* **Required env vars**:

  * `SFDX_AUTH_URL` — OAuth web sfdxAuthUrl for your sandbox
  * `SFDX_DEFAULTUSERNAME` — alias or username of your sandbox org
* **Allowed network** (setup phase only):

  * `registry.npmjs.org` (to install sfdx-cli)
  * `test.salesforce.com` (sandbox auth & metadata)
  * `login.salesforce.com` (prod auth if needed)

## 2. Reference Documentation

The following reference files are located at the root of the repo (`https://github.com/Air4ce1Jr/Apex/tree/main`):

* **Revenova TMS Web Services Guide**: `Revenova TMS Web Services Guide.pdf`
* **Pub/Sub API Accounting Integration**: `PubSub API Accounting Integration.pdf`
* **Data Dictionaries**:

  * `Data Dictionary A through C.pdf`
  * `Data Dictionary D through F.pdf`
  * `Data Dictionary G through R.pdf`
  * `Data Dictionary S through Z.pdf`

> Codex should use these PDF files to lookup API names, endpoints, payload structures, and field definitions when generating or testing Apex code.

## 3. Validation & Testing

1. **Run Apex tests** (must achieve **≥ 90%** code coverage):

   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
   ```
2. **Validate-only deploy** (runs tests & checks without deployment):

   ```bash
   sfdx force:source:deploy --checkonly -p force-app/main/default --testlevel RunLocalTests
   ```

## 4. Pull Requests

* **Title format**: `[QuickBooks→Salesforce] <concise summary>`
* **Body should include**:

  1. Summary of changes
  2. Verified test coverage (%)
  3. Validation-only deploy summary

## 5. QuickBooks Connectivity

* **Named Credential**: `QuickBooks_NC`
* **External Credential**: `QuickBooks_EC`
* **Apex callout example**:

  ```apex
  HttpRequest req = new HttpRequest();
  req.setEndpoint('callout:QuickBooks_NC/v3/company/{COMPANY_ID}/invoice');
  req.setMethod('POST');
  ```
