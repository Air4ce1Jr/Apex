public with sharing class QuickBooksCustomerSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, DBA_Name__c, QuickBooks_Email__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode,
                QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
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
        if (!updates.isEmpty()) {
            update updates;
        }
    }
    public void finish(Database.BatchableContext bc) {}
}
