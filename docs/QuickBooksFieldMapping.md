# QuickBooks Field Mapping

This table outlines how Salesforce fields map to QuickBooks fields when synchronizing customers, invoices, invoice lines, and payments. It is based on the API reference (see `API ExplorerQB.pdf`).

| QuickBooks Field | Salesforce Field | Notes |
|-----------------|-----------------|-------|
| Customer.DisplayName | `Account.Name` | Fallback when `DBA_Name__c` is blank |
| Customer.PrimaryEmailAddr.Address | `Account.QuickBooks_Email__c` or billing contact email | Contact has `Title='Billing'` |
| Customer.BillAddr.Line1 | `Account.BillingStreet` | |
| Customer.BillAddr.City | `Account.BillingCity` | |
| Customer.BillAddr.CountrySubDivisionCode | `Account.BillingState` | |
| Customer.BillAddr.PostalCode | `Account.BillingPostalCode` | |
| Customer.Id (response) | `Account.QuickBooks_Customer_Id__c` | stored after create/update |
| Customer.SyncToken (response) | `Account.QuickBooks_Customer_SyncToken__c` | |
| Invoice.CustomerRef.value | `rtms__CustomerInvoice__c.Account__r.QuickBooks_Customer_Id__c` | |
| Invoice.DocNumber | `rtms__CustomerInvoice__c.Invoice_Number__c` | |
| Invoice.TxnDate | `rtms__CustomerInvoice__c.Invoice_Date__c` | |
| Invoice.DueDate | `rtms__CustomerInvoice__c.Invoice_Due_Date__c` | |
| Invoice.PrivateNote | `rtms__CustomerInvoice__c.Invoice_Comments__c` | |
| Invoice.Id (response) | `rtms__CustomerInvoice__c.QuickBooks_Invoice_Id__c` | |
| Invoice.SyncToken (response) | `rtms__CustomerInvoice__c.QuickBooks_Invoice_SyncToken__c` | |
| InvoiceLine.Description | `rtms__CustomerInvoiceAccessorial__c.Name` | |
| InvoiceLine.Amount | `rtms__CustomerInvoiceAccessorial__c.rtms__Charge__c` | |
| InvoiceLine.SalesItemLineDetail.ItemRef.value | `rtms__CustomerInvoiceAccessorial__c.QBO_Item_Id__c` | |
| InvoiceLine.SalesItemLineDetail.UnitPrice | `rtms__CustomerInvoiceAccessorial__c.rtms__Unit_Price__c` | |
| InvoiceLine.SalesItemLineDetail.Qty | `rtms__CustomerInvoiceAccessorial__c.rtms__Quantity__c` | |
| Payment.CustomerRef.value | `rtms__CustomerPayment__c.Account__r.QuickBooks_Customer_Id__c` | |
| Payment.TotalAmt | `rtms__CustomerPayment__c.rtms__Payment_Amount__c` | |
| Payment.TxnDate | `rtms__CustomerPayment__c.rtms__Payment_Date__c` | |
| Payment.PaymentRefNum | `rtms__CustomerPayment__c.rtms__Check_Reference_Number__c` | |
| Payment.Id (response) | `rtms__CustomerPayment__c.rtms__QuickBooks_Payment_Id__c` | store returned id |
| Payment.Line[0].LinkedTxn.TxnId | `rtms__CustomerPayment__c.CustomerInvoice__r.QuickBooks_Invoice_Id__c` | |
| Estimate.CustomerRef.value | `rtms__Estimate__c.Account__r.QuickBooks_Customer_Id__c` | new estimate sync |
| Estimate.TxnDate | `rtms__Estimate__c.rtms__Estimate_Date__c` | |
| Estimate.ExpirationDate | `rtms__Estimate__c.rtms__Estimate_Expiration_Date__c` | |
