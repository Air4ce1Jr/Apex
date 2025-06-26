public with sharing class QuickBooksSyncJob implements Queueable, Database.AllowsCallouts {
    private String sObjectType;
    private List<Id> recordIds;

    @TestVisible static Map<Id, Account> testAccounts;
    @TestVisible static Map<Id, rtms__CustomerInvoice__c> testInvoices;
    @TestVisible static Map<Id, rtms__CustomerInvoiceAccessorial__c> testLines;
    @TestVisible static Map<Id, rtms__CustomerPayment__c> testPayments;
    @TestVisible static Boolean skipDml = false;

    public QuickBooksSyncJob(String sObjectType, List<Id> recordIds) {
        this.sObjectType = sObjectType;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        if (sObjectType == 'Account') {
            List<Account> records = new List<Account>();
            if (System.Test.isRunningTest() && testAccounts != null) {
                for (Id i : recordIds) if (testAccounts.containsKey(i)) records.add(testAccounts.get(i));
            } else {
                records = [SELECT Id, Name, QuickBooks_Email__c,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode,
                        QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c,
                        (SELECT Id, Email, Title FROM Contacts WHERE Title = 'Billing')
                    FROM Account WHERE Id IN :recordIds];
            }
            List<Account> updates = new List<Account>();
            for (Account acct : records) {
                QuickBooksService.CustomerResult res = QuickBooksService.createOrUpdateCustomer(acct);
                Account upd = new Account(Id=acct.Id);
                Boolean changed = false;
                if (String.isNotBlank(res.id)) {
                    upd.QuickBooks_Customer_Id__c = res.id;
                    changed = true;
                }
                if (String.isNotBlank(res.syncToken)) {
                    upd.QuickBooks_Customer_SyncToken__c = res.syncToken;
                    changed = true;
                }
                if (changed) updates.add(upd);
            }
            if (!updates.isEmpty()) {
                if (System.Test.isRunningTest() && skipDml) {
                    for (Account upd : updates) {
                        if (testAccounts != null && testAccounts.containsKey(upd.Id)) {
                            Account tgt = testAccounts.get(upd.Id);
                            if (upd.QuickBooks_Customer_Id__c != null)
                                tgt.QuickBooks_Customer_Id__c = upd.QuickBooks_Customer_Id__c;
                            if (upd.QuickBooks_Customer_SyncToken__c != null)
                                tgt.QuickBooks_Customer_SyncToken__c = upd.QuickBooks_Customer_SyncToken__c;
                        }
                    }
                } else {
                    update updates;
                }
            }
        } else if (sObjectType == 'rtms__CustomerInvoice__c') {
            List<rtms__CustomerInvoice__c> invoices = new List<rtms__CustomerInvoice__c>();
            if (System.Test.isRunningTest() && testInvoices != null) {
                for (Id i : recordIds) if (testInvoices.containsKey(i)) invoices.add(testInvoices.get(i));
            } else {
                invoices = [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c, Invoice_Number__c,
                        Invoice_Date__c, Invoice_Due_Date__c,
                        Invoice_Comments__c, QuickBooks_Invoice_Id__c,
                        QuickBooks_Invoice_SyncToken__c
                    FROM rtms__CustomerInvoice__c WHERE Id IN :recordIds];
            }
            for (rtms__CustomerInvoice__c inv : invoices) {
                QuickBooksService.createOrUpdateInvoice(inv, inv.Account__r.QuickBooks_Customer_Id__c);
            }
        } else if (sObjectType == 'rtms__CustomerInvoiceAccessorial__c') {
            List<rtms__CustomerInvoiceAccessorial__c> lines = new List<rtms__CustomerInvoiceAccessorial__c>();
            if (System.Test.isRunningTest() && testLines != null) {
                for (Id i : recordIds) if (testLines.containsKey(i)) lines.add(testLines.get(i));
            } else {
                lines = [SELECT Id, Name, rtms__Charge__c,
                        QBO_Item_Id__c, rtms__Unit_Price__c, rtms__Quantity__c,
                        CustomerInvoice__c
                    FROM rtms__CustomerInvoiceAccessorial__c WHERE Id IN :recordIds];
            }
            Map<Id, List<rtms__CustomerInvoiceAccessorial__c>> byInv = new Map<Id, List<rtms__CustomerInvoiceAccessorial__c>>();
            for (rtms__CustomerInvoiceAccessorial__c l : lines) {
                if (!byInv.containsKey(l.CustomerInvoice__c)) {
                    byInv.put(l.CustomerInvoice__c, new List<rtms__CustomerInvoiceAccessorial__c>());
                }
                byInv.get(l.CustomerInvoice__c).add(l);
            }
            Map<Id, rtms__CustomerInvoice__c> invoices;
            if (System.Test.isRunningTest() && testInvoices != null) {
                invoices = new Map<Id, rtms__CustomerInvoice__c>();
                for (Id invId : byInv.keySet()) if (testInvoices.containsKey(invId)) invoices.put(invId, testInvoices.get(invId));
            } else {
                invoices = new Map<Id, rtms__CustomerInvoice__c>([
                    SELECT Id, QuickBooks_Invoice_Id__c, QuickBooks_Invoice_SyncToken__c FROM rtms__CustomerInvoice__c WHERE Id IN :byInv.keySet()
                ]);
            }
            for (Id invId : byInv.keySet()) {
                if (invoices.containsKey(invId)) {
                    rtms__CustomerInvoice__c invRecord = invoices.get(invId);
                    QuickBooksService.createInvoiceLines(byInv.get(invId), invRecord.QuickBooks_Invoice_Id__c, invRecord.QuickBooks_Invoice_SyncToken__c);
                }
            }
        } else if (sObjectType == 'rtms__CustomerPayment__c') {
            List<rtms__CustomerPayment__c> pays = new List<rtms__CustomerPayment__c>();
            if (System.Test.isRunningTest() && testPayments != null) {
                for (Id i : recordIds) if (testPayments.containsKey(i)) pays.add(testPayments.get(i));
            } else {
                pays = [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c,
                        rtms__Payment_Amount__c, rtms__Payment_Date__c,
                        rtms__Check_Reference_Number__c, CustomerInvoice__c, CustomerInvoice__r.QuickBooks_Invoice_Id__c
                    FROM rtms__CustomerPayment__c WHERE Id IN :recordIds];
            }
            for (rtms__CustomerPayment__c pay : pays) {
                QuickBooksService.createPayment(pay, pay.Account__r.QuickBooks_Customer_Id__c,
                        pay.CustomerInvoice__r.QuickBooks_Invoice_Id__c);
            }
        }
    }
}


