public with sharing class QuickBooksAccountScheduler implements Schedulable {
    @TestVisible static Boolean runInline = false;

    @TestVisible
    class Ctx implements Database.BatchableContext {
        public Id getJobId() { return null; }
        public Id getChildJobId() { return null; }
    }

    public void execute(SchedulableContext context) {
        if (System.Test.isRunningTest() && runInline) {
            new QuickBooksCustomerSyncBatch().execute(new Ctx(), new List<Account>());
        } else {
            Database.executeBatch(new QuickBooksCustomerSyncBatch());
        }
    }
}
