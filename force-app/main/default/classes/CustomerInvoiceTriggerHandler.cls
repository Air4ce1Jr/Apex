public with sharing class CustomerInvoiceTriggerHandler {
    public static void afterInsertUpdate(List<rtms__CustomerInvoice__c> records, Map<Id, rtms__CustomerInvoice__c> oldMap) {
        List<Id> toSync = new List<Id>();
        for (rtms__CustomerInvoice__c inv : records) {
            String oldStatus = oldMap != null && oldMap.containsKey(inv.Id) ? oldMap.get(inv.Id).rtms__Accounting_Status__c : null;
            if (inv.rtms__Accounting_Status__c == 'Ready for Accounting' && inv.rtms__Accounting_Status__c != oldStatus) {
                toSync.add(inv.Id);
            }
        }
        if (!toSync.isEmpty() && !QuickBooksTriggerUtil.skipAsync) {
            QuickBooksSyncJob job = new QuickBooksSyncJob('rtms__CustomerInvoice__c', toSync);
            if (System.Test.isRunningTest() && QuickBooksTriggerUtil.runInline) {
                job.execute(null);
            } else {
                System.enqueueJob(job);
            }
        }
    }
}
