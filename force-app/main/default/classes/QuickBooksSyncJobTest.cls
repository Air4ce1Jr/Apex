@IsTest(SeeAllData=true)
private class QuickBooksSyncJobTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        Account a = new Account(Name='Acct', QuickBooks_Customer_Id__c='QB1');
        insert a;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            Account__c=a.Id,
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=5
        );
        insert inv;
        List<Id> ids = new List<Id>{inv.Id};
        System.Test.startTest();
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoice__c', ids));
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testAccountQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        Account a = new Account(Name='Acct');
        insert a;
        System.Test.startTest();
        System.enqueueJob(new QuickBooksSyncJob('Account', new List<Id>{a.Id}));
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }
}

