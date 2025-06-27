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
        QuickBooksService.skipDml = skipDml;
        for (Account acct : scope) {
            QuickBooksService.createOrUpdateCustomer(acct);
        }
        QuickBooksService.skipDml = false;
    }
    public void finish(Database.BatchableContext bc) {}
}
