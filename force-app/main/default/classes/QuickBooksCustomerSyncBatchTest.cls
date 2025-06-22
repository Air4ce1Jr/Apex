@IsTest
private class QuickBooksCustomerSyncBatchTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
    @IsTest static void testBatch() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        Account a = new Account(Name='Acct', DBA_Name__c='DBA', QuickBooks_Email__c='a@example.com');
        insert a;
        Test.startTest();
        Database.executeBatch(new QuickBooksCustomerSyncBatch(), 1);
        Test.stopTest();
        System.assertEquals('BatchApexWorker', [SELECT JobType FROM AsyncApexJob ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }
}
