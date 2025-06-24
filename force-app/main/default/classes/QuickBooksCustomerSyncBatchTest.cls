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
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksCustomerSyncBatch.skipDml = false;
        Account a = new Account(Name='Acct', Type='Customer', DBA_Name__c='DBA', QuickBooks_Email__c='a@example.com');
        insert a;
        System.Test.startTest();
 bo2hti-codex/test-and-deploy-quickbooks-salesforce-sync
        new QuickBooksCustomerSyncBatch().execute(new Ctx(), new List<Account>{a});

        Database.executeBatch(new QuickBooksCustomerSyncBatch(), 1);
 main
        System.Test.stopTest();
        a = [SELECT QuickBooks_Customer_Id__c FROM Account WHERE Id = :a.Id];
        System.assertEquals('55', a.QuickBooks_Customer_Id__c);
    }
}
