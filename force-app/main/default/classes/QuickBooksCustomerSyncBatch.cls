public with sharing class QuickBooksCustomerSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    @TestVisible static Boolean skipDml = false;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, QuickBooks_Email__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode,
                QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c,
                (SELECT Id, Email, Title FROM Contacts WHERE Title = 'Billing')
            FROM Account WHERE Type = 'Customer'
        ]);
    }
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> updates = new List<Account>();
        for (Account acct : scope) {
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
        if (!updates.isEmpty() && !skipDml) {
            update updates;
        }
    }
    public void finish(Database.BatchableContext bc) {}
}
