public with sharing class QuickBooksCustomerSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, DBA_Name__c, QuickBooks_Email__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode,
                QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
            FROM Account WHERE Type = 'Customer'
        ]);
    }
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acct : scope) {
            QuickBooksService.createOrUpdateCustomer(acct);
        }
    }
    public void finish(Database.BatchableContext bc) {}
}
