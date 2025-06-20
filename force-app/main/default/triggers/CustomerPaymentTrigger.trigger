trigger CustomerPaymentTrigger on rtms__CustomerPayment__c (after insert, after update) {
    if (Trigger.isAfter) {
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>(Trigger.newMap.keySet())));
    }
}
