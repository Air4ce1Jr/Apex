trigger CustomerInvoiceAccessorialTrigger on rtms__CustomerInvoiceAccessorial__c (after insert, after update) {
    if (Trigger.isAfter && !QuickBooksTriggerUtil.skipAsync) {
        QuickBooksSyncJob job = new QuickBooksSyncJob('rtms__CustomerInvoiceAccessorial__c', new List<Id>(Trigger.newMap.keySet()));
    if (System.Test.isRunningTest() && QuickBooksTriggerUtil.runInline) {
            job.execute(null);
        } else {
            System.enqueueJob(job);
        }
    }
}
