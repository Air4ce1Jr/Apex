````markdown
# Codex Agent Guide

## 1. Setup

* **Setup script**: `./setup_codex.sh`
* **Required env vars**:
  * `SFDX_AUTH_URL` — OAuth web sfdxAuthUrl for your sandbox  
  * `SFDX_DEFAULTUSERNAME` — alias or username of your sandbox org
* **Allowed network** (setup phase only):
  * `registry.npmjs.org` (to install sfdx-cli)
  * `deb.debian.org` / `archive.ubuntu.com` (for Node.js/npm)
  * `github.com` / `raw.githubusercontent.com` (sfdx-cli binary)
  * `developer.salesforce.com` (Salesforce CLI installer downloads)
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

> Codex should use these PDF files to look up API names, endpoints, payload structures, and field definitions when generating or testing Apex code.

## 3. Validation & Testing

1. **Run Apex tests** (must achieve **≥ 95%** code coverage on any new or modified classes):
   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
````

2. **Validate-only deploy to sandbox** (runs tests & checks without actual deployment):

   ```bash
   sfdx force:source:deploy --checkonly -p force-app/main/default --testlevel RunLocalTests
   ```

   * If certain legacy controllers fall below coverage, write additional unit tests to bring overall org coverage above **75%**.

3. **Full sandbox deployment**:

   1. **Deploy** via CLI or Change Set to your sandbox, e.g.:

      ```bash
      sfdx force:source:deploy -p force-app/main/default --testlevel RunLocalTests
      ```
   2. Run all local tests to confirm **org-wide coverage ≥ 75%**.
   3. Verify there are no coverage errors remaining.

## 4. Pull Requests & Change Sets

* **Pull request title**:

  ```
  [QuickBooks→Salesforce] <concise summary>
  ```

* **PR body** should include:

  1. Summary of changes
  2. Verified test coverage (%) for new/modified classes
  3. Validation-only deploy summary (test run and coverage)

* **Sandbox Change Set**:

  1. Create an outbound Change Set in sandbox containing your metadata.
  2. Include all Apex classes, triggers, and test classes.
  3. Deploy to target org with “Run Local Tests” / “Run All Tests” enabled.
  4. Verify deployment status and org-wide coverage.

## 5. QuickBooks Connectivity

* **Named Credential**: `QuickBooks_NC`
* **External Credential**: `QuickBooks_EC`
* **Apex callout example**:

  ```apex
  HttpRequest req = new HttpRequest();
  req.setEndpoint('callout:QuickBooks_NC/v3/company/{COMPANY_ID}/invoice');
  req.setMethod('POST');
  ```

```
```
