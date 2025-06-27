@IsTest(isParallel=false)
private class QuickBooksCustomerSyncBatchTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"55","SyncToken":"3"}}');
            return res;
        }
    }
    class Ctx implements Database.BatchableContext {
        public Id getJobId() { return null; }
        public Id getChildJobId() { return null; }
    }
    @IsTest static void testBatch() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksCustomerSyncBatch.skipDml = false;
        Account a = new Account(Name='Acct', Type='Customer');
        insert a;
        insert new Contact(LastName='Bill', Email='a@example.com', Title='Billing', AccountId=a.Id);
        Test.startTest();
        new QuickBooksCustomerSyncBatch().execute(new Ctx(), new List<Account>{a});

        Test.stopTest();
        QuickBooksCustomerSyncBatch.skipDml = false;
        a = [SELECT QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c FROM Account WHERE Id = :a.Id];
        System.assertEquals('55', a.QuickBooks_Customer_Id__c);
        System.assertEquals('3', a.QuickBooks_Customer_SyncToken__c);
    }
}
