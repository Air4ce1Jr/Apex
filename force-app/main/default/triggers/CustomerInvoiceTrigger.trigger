trigger CustomerInvoiceTrigger on rtms__CustomerInvoice__c (after insert, after update) {
    if (Trigger.isAfter) {
        CustomerInvoiceTriggerHandler.afterInsertUpdate(Trigger.new, Trigger.oldMap);
    }
}
