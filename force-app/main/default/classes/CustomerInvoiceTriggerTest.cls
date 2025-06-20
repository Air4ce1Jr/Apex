@IsTest(SeeAllData=true)
private class CustomerInvoiceTriggerTest {
    // Verifies CustomerInvoiceTrigger enqueues syncs when Accounting_Status__c is set
    class Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testInsertQueuesJob() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=10,
            Accounting_Status__c='Ready for Accounting'
        );
        System.Test.startTest();
        insert inv;
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testUpdateQueuesJob() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv2',
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=20,
 6i2ox7-codex/build-quickbooks-integration-with-salesforce-apex
            Accounting_Status__c='Ready for Accounting'
        );
        insert inv;
        inv.Accounting_Status__c = 'Ready for Accounting';
        System.Test.startTest();
        update inv;
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }
}
