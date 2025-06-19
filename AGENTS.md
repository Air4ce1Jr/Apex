# Codex Agent Guide

## 1. Setup

* **Setup script**: `./setup_codex.sh`
* **Required env vars**:

  * `SFDX_AUTH_URL` — OAuth sfdxAuthUrl for your **sandbox** org
  * `SFDX_DEFAULTUSERNAME` — alias or username for your **sandbox** org
  * `SFDX_PROD_AUTH_URL` — OAuth sfdxAuthUrl for your **production** org
  * `SFDX_PROD_USERNAME` — alias or username for your **production** org
* **Allowed network** (setup phase only):

  * `registry.npmjs.org` (to install sfdx-cli)
  * `deb.debian.org` / `archive.ubuntu.com` (for Node.js/npm)
  * `github.com` / `raw.githubusercontent.com` (sfdx-cli binary)
  * `developer.salesforce.com` (Salesforce CLI installer)
  * `test.salesforce.com` (sandbox auth & metadata)
  * `login.salesforce.com` (prod auth & metadata)

## 2. Reference Documentation

The following reference files are located at the root of the repo (`https://github.com/Air4ce1Jr/Apex/tree/main`):

* **Revenova TMS Web Services Guide**: `Revenova TMS Web Services Guide.pdf`
* **Pub/Sub API Accounting Integration**: `PubSub API Accounting Integration.pdf`
* **Data Dictionaries**:

  * `Data Dictionary A through C.pdf`
  * `Data Dictionary D through F.pdf`
  * `Data Dictionary G through R.pdf`
  * `Data Dictionary S through Z.pdf`

> Codex should use these PDF files to look up API names, endpoints, payload structures, and field definitions when generating or testing Apex code.

## 3. Validation & Testing

1. **Run Apex tests** against your **sandbox** (must achieve **≥ 100%** coverage on any new/modified classes):

   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
   ```

2. **Validate-only deploy to sandbox** (runs tests & checks without actual deployment):

   ```bash
   sfdx force:source:deploy --checkonly -p force-app/main/default \
     --testlevel RunLocalTests
   ```

   * If legacy controllers fall below coverage, write additional unit tests to bring overall org coverage above **75%**.

3. **Deploy to sandbox**:

   ```bash
   sfdx force:source:deploy -p force-app/main/default --testlevel RunLocalTests
   ```

   * Confirm **org-wide coverage ≥ 75%**.

4. **Validate against production** (after sandbox is green):

   ```bash
   sfdx force:source:deploy -p force-app/main/default \
     --targetusername "$SFDX_PROD_USERNAME" \
     --testlevel RunLocalTests
   ```

   * Ensure **org-wide coverage ≥ 75%** in production as well.
   * No failing tests or compilation errors.

## 4. Pull Requests & Change Sets

* **Pull request title**:

  ```
  [QuickBooks→Salesforce] <concise summary>
  ```

* **PR body** must include:

  1. Summary of changes
  2. Verified test coverage (%) for new/modified classes
  3. Validation-only deploy summary (test run and coverage metrics)

* **Outbound Change Set** (for production deployment):

  1. In sandbox, create an **Outbound Change Set** containing all metadata (Apex classes, triggers, test classes).
  2. Upload to production.
  3. In production, deploy the change set with **Run Local Tests** / **Run All Tests** enabled.
  4. Confirm successful deployment and **org-wide coverage ≥ 75%**.

## 5. QuickBooks Connectivity

* **Named Credential**: `QuickBooks_NC`
* **External Credential**: `QuickBooks_EC`
* **Apex callout example**:

  ```apex
  HttpRequest req = new HttpRequest();
  req.setEndpoint('callout:QuickBooks_NC/v3/company/{COMPANY_ID}/invoice');
  req.setMethod('POST');
  ```
