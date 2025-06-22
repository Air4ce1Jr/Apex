public with sharing class QuickBooksSyncJob implements Queueable, Database.AllowsCallouts {
    private String sObjectType;
    private List<Id> recordIds;

    public QuickBooksSyncJob(String sObjectType, List<Id> recordIds) {
        this.sObjectType = sObjectType;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        if (sObjectType == 'Account') {
            for (Account acct : [SELECT Id, DBA_Name__c, QuickBooks_Email__c,
                    BillingStreet, BillingCity, BillingState, BillingPostalCode,
                    QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
                FROM Account WHERE Id IN :recordIds]) {
                QuickBooksService.createOrUpdateCustomer(acct);
            }
        } else if (sObjectType == 'rtms__CustomerInvoice__c') {
            for (rtms__CustomerInvoice__c inv : [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c, Invoice_Number__c,
                    Invoice_Date__c, Invoice_Due_Date__c,
                    Invoice_Comments__c, QuickBooks_Invoice_Id__c,
                    QuickBooks_Invoice_SyncToken__c
                FROM rtms__CustomerInvoice__c WHERE Id IN :recordIds]) {
                QuickBooksService.createOrUpdateInvoice(inv, inv.Account__r.QuickBooks_Customer_Id__c);
            }
        } else if (sObjectType == 'rtms__CustomerInvoiceAccessorial__c') {
            List<rtms__CustomerInvoiceAccessorial__c> lines = [SELECT Id, Name, rtms__Charge__c,
                    QBO_Item_Id__c, rtms__Unit_Price__c, rtms__Quantity__c,
                    CustomerInvoice__c
                FROM rtms__CustomerInvoiceAccessorial__c WHERE Id IN :recordIds];
            Map<Id, List<rtms__CustomerInvoiceAccessorial__c>> byInv = new Map<Id, List<rtms__CustomerInvoiceAccessorial__c>>();
            for (rtms__CustomerInvoiceAccessorial__c l : lines) {
                if (!byInv.containsKey(l.CustomerInvoice__c)) {
                    byInv.put(l.CustomerInvoice__c, new List<rtms__CustomerInvoiceAccessorial__c>());
                }
                byInv.get(l.CustomerInvoice__c).add(l);
            }
            Map<Id, rtms__CustomerInvoice__c> invoices = new Map<Id, rtms__CustomerInvoice__c>([
                SELECT Id, QuickBooks_Invoice_Id__c FROM rtms__CustomerInvoice__c WHERE Id IN :byInv.keySet()
            ]);
            for (Id invId : byInv.keySet()) {
                if (invoices.containsKey(invId)) {
                    QuickBooksService.createInvoiceLines(byInv.get(invId), invoices.get(invId).QuickBooks_Invoice_Id__c);
                }
            }
        } else if (sObjectType == 'rtms__CustomerPayment__c') {
            for (rtms__CustomerPayment__c pay : [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c,
                    rtms__Payment_Amount__c, rtms__Payment_Date__c,
                    rtms__Check_Reference_Number__c, CustomerInvoice__c, CustomerInvoice__r.QuickBooks_Invoice_Id__c
                FROM rtms__CustomerPayment__c WHERE Id IN :recordIds]) {
                QuickBooksService.createPayment(pay, pay.Account__r.QuickBooks_Customer_Id__c,
                        pay.CustomerInvoice__r.QuickBooks_Invoice_Id__c);
            }
        }
    }
}


