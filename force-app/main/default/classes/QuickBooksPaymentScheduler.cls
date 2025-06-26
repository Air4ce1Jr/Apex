public with sharing class QuickBooksPaymentScheduler implements Schedulable {
    @TestVisible static Boolean runInline = false;

    public void execute(SchedulableContext context) {
        String type = 'rtms__CustomerPayment__c';
        if (System.Test.isRunningTest() && runInline) {
            new QuickBooksSyncJob(type, new List<Id>()).execute(null);
        } else {
            System.enqueueJob(new QuickBooksSyncJob(type, new List<Id>()));
        }
    }
}

