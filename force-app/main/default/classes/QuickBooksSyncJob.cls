public with sharing class QuickBooksSyncJob implements Queueable, Database.AllowsCallouts {
    private String sObjectType;
    private List<Id> recordIds;

    public QuickBooksSyncJob(String sObjectType, List<Id> recordIds) {
        this.sObjectType = sObjectType;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        if (sObjectType == 'rtms__CustomerInvoice__c') {
            for (Id id : recordIds) {
                QuickBooksInvoiceService.sendInvoice(id);
            }
        }
    }
}


