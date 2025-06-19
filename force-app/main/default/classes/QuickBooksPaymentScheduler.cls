public with sharing class QuickBooksPaymentScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        System.enqueueJob(new QuickBooksSyncJob('Payments', new List<Id>()));
    }
}

