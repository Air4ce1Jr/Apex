public with sharing class QuickBooksAccountScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        Database.executeBatch(new QuickBooksCustomerSyncBatch());
    }
}
