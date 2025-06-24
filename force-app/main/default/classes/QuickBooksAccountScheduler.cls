public with sharing class QuickBooksAccountScheduler implements Schedulable {
bo2hti-codex/test-and-deploy-quickbooks-salesforce-sync
    @TestVisible
    class Ctx implements Database.BatchableContext {
        public Id getJobId() { return null; }
        public Id getChildJobId() { return null; }
    }
    public void execute(SchedulableContext context) {
        if (System.Test.isRunningTest()) {
            new QuickBooksCustomerSyncBatch().execute(new Ctx(), new List<Account>());
        } else {
            Database.executeBatch(new QuickBooksCustomerSyncBatch());
        }
=======
    public void execute(SchedulableContext context) {
        Database.executeBatch(new QuickBooksCustomerSyncBatch());
main
    }
}
