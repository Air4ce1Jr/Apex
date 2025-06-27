public with sharing class QuickBooksPaymentScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        if (Test.isRunningTest()) {
            new QuickBooksSyncJob('Payments', new List<Id>()).execute(null);
        } else {
            System.enqueueJob(new QuickBooksSyncJob('Payments', new List<Id>()));
        }
    }
}

