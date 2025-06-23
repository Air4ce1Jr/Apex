@IsTest
private class QuickBooksCustomerSyncBatchTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"55","SyncToken":"3"}}');
            return res;
        }
    }
    @IsTest static void testBatch() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        Account a = new Account(Name='Acct', Type='Customer', DBA_Name__c='DBA', QuickBooks_Email__c='a@example.com');
        insert a;
        Test.startTest();
        Database.executeBatch(new QuickBooksCustomerSyncBatch(), 1);
        Test.stopTest();
        a = [SELECT QuickBooks_Customer_Id__c FROM Account WHERE Id = :a.Id];
        System.assertEquals('55', a.QuickBooks_Customer_Id__c);
        System.assertEquals('BatchApexWorker',
            [SELECT JobType FROM AsyncApexJob WHERE JobType='BatchApexWorker' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }
}
