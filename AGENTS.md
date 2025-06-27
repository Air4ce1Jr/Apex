# Codex Agent Guide

## 1. Setup
Maintain Internet Access indefinitely across all domains

* **Required env vars**:

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

## 2. Reference Documentation

The following reference files are located at the root of the repo (`https://github.com/Air4ce1Jr/Apex/tree/main`):

* **Revenova TMS Web Services Guide**: `Revenova TMS Web Services Guide.pdf`
* **Pub/Sub API Accounting Integration**: `PubSub API Accounting Integration.pdf`
* **Customer & Invoice Management Docs**:

  * `CarrierCustomer Invoice Adjustments.pdf`
  * `Customer Payments.pdf`
  * `Master Invoice Number.pdf`
  * `Customer Invoice Batch Print.pdf`
  * `Customer Invoice Batch Email.pdf`
  * `CustomerSpecific Invoice Attachments.pdf`
  * `Customer Invoice Dispute Resolution.pdf`
  * `Automated Customer Invoice Generation.pdf`
  * `Customer Invoice Batch Generation.pdf`
  * `Customer Invoices.pdf`
* **Data Dictionaries**:

  * `Data Dictionary A through C.pdf`
  * `Data Dictionary D through F.pdf`
  * `Data Dictionary G through R.pdf`
  * `Data Dictionary S through Z.pdf`

> Codex should use these PDF files to look up API names, endpoints, payload structures, and field definitions when generating or testing Apex code.

## 3. Validation & Testing

1. **Run Apex tests** (must achieve **≥ 75%%** code coverage on any new or modified classes):

   ```bash
   sfdx force:apex:test:run --codecoverage --resultformat human
   ```

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
  4. Suggestions for fixes 

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

1. A consolidated **field-mapping table** for Customers, Invoices, Invoice Lines, and Payments (all using `rtms__` prefixes).
2. The **full JSON payloads** for Create/Update operations.

---

| QBO Entity       | QBO Field                           | Revenova Object (API Name)                  | Revenova Field (API Name)                        | Notes                        |
| ---------------- | ----------------------------------- | ------------------------------------------- | ------------------------------------------------ | ---------------------------- |
| **Customer**     | `Customer.Id`                       | **Account**                                 | `rtms__QuickBooks_Customer_Id__c` (Text, Ext ID) | Upsert anchor                |
|                  | `DisplayName`                       | **Account**                                 | `DBA_Name__c`                                    | Map to your “DBA Name” field |
|                  | `PrimaryEmailAddr.Address`          | **Account**                                 | `rtms__QuickBooks_Email__c` (Email)              | New                          |
|                  | `BillAddr.Line1`                    | **Account**                                 | `BillingStreet`                                  | Standard billing street      |
|                  | `BillAddr.City`                     | **Account**                                 | `BillingCity`                                    | Standard                     |
|                  | `BillAddr.CountrySubDivisionCode`   | **Account**                                 | `BillingState`                                   | 2-letter state code          |
|                  | `BillAddr.PostalCode`               | **Account**                                 | `BillingPostalCode`                              | Standard                     |
| **Invoice**      | `Invoice.Id`                        | **rtms\_\_CustomerInvoice\_\_c**            | `rtms__QuickBooks_Invoice_Id__c` (Text, Ext ID)  | Upsert anchor                |
|                  | `DocNumber`                         | **rtms\_\_CustomerInvoice\_\_c**            | `rtms__Invoice_Number__c`                        | “Invoice Number”             |
|                  | `TxnDate`                           | **rtms\_\_CustomerInvoice\_\_c**            | `rtms__Invoice_Date__c`                          | “Invoice Date”               |
|                  | `DueDate`                           | **rtms\_\_CustomerInvoice\_\_c**            | `rtms__Invoice_Due_Date__c`                      | “Invoice Due Date”           |
|                  | `TotalAmt`                          | **rtms\_\_CustomerInvoice\_\_c**            | `rtms__Invoice_Total__c`                         | “Invoice Total”              |
| **Invoice Line** | `Line.Description`                  | **rtms\_\_CustomerInvoiceAccessorial\_\_c** | `Name`                                           | Use as line description      |
|                  | `Line.Amount`                       | **rtms\_\_CustomerInvoiceAccessorial\_\_c** | `rtms__Charge__c`                                | Currency                     |
|                  | `SalesItemLineDetail.ItemRef.value` | **rtms\_\_CustomerInvoiceAccessorial\_\_c** | `rtms__QBO_Item_Id__c` (Text)                    | External-ID to QBO Item      |
|                  | `SalesItemLineDetail.UnitPrice`     | **rtms\_\_CustomerInvoiceAccessorial\_\_c** | `rtms__Unit_Price__c`                            | Currency                     |
|                  | `SalesItemLineDetail.Qty`           | **rtms\_\_CustomerInvoiceAccessorial\_\_c** | `rtms__Quantity__c`                              | Number                       |
| **Payment**      | `Payment.Id`                        | **rtms\_\_CustomerPayment\_\_c**            | `rtms__QuickBooks_Payment_Id__c` (Text, Ext ID)  | Upsert anchor                |
|                  | `TotalAmt`                          | **rtms\_\_CustomerPayment\_\_c**            | `rtms__Payment_Amount__c`                        | “Payment Amount”             |
|                  | `TxnDate`                           | **rtms\_\_CustomerPayment\_\_c**            | `rtms__Payment_Date__c`                          | “Payment Date”               |
|                  | `PaymentRefNum`                     | **rtms\_\_CustomerPayment\_\_c**            | `rtms__Check_Reference_Number__c`                | “Check/Reference Number”     |
|                  | `Line[0].LinkedTxn[0].TxnId`        | **rtms\_\_CustomerPayment\_\_c**            | `rtms__CustomerInvoice__c` (Lookup)              | Link to parent invoice       |



---

### Usage Notes

* **Store returned** `Id` (and `SyncToken` if needed) in each `QuickBooks_Id__c` (and QuickBooks_*_SyncToken__c`) field.
* **Named Credential** `QuickBooks_NC` handles OAuth; your Apex just calls `callout:QuickBooks_NC/...`.
* **Error handling:** log non-2xx responses, capture the response body, and retry or surface to an admin.
* **Upsert logic:** use `External Id` fields for UPSERT DML to avoid duplicates.

