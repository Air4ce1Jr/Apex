public with sharing class QuickBooksScheduler implements Schedulable {
    @TestVisible
    class Ctx implements Database.BatchableContext {
        public Id getJobId() { return null; }
        public Id getChildJobId() { return null; }
    }

    public String mode { get; private set; }

    public QuickBooksScheduler() {
        this('Customer');
    }

    public QuickBooksScheduler(String mode) {
        this.mode = mode;
    }

    public void execute(SchedulableContext context) {
        if (mode == 'Payment') {
            if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
                System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>()));
            } else {
                new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>()).execute(null);
            }
        } else {
            if (Test.isRunningTest()) {
                new QuickBooksCustomerSyncBatch().execute(new Ctx(), new List<Account>());
            } else {
                Database.executeBatch(new QuickBooksCustomerSyncBatch());
            }
        }
    }
}
