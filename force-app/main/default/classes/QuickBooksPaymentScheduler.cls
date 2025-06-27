public with sharing class QuickBooksPaymentScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        if (Test.isRunningTest()) {
            new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>()).execute(null);
        } else {
            System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>()));
        }
    }
}

