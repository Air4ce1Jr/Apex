trigger CustomerInvoiceAccessorialTrigger on rtms__CustomerInvoiceAccessorial__c (after insert, after update) {
    if (Trigger.isAfter) {
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoiceAccessorial__c', new List<Id>(Trigger.newMap.keySet())));
    }
}
