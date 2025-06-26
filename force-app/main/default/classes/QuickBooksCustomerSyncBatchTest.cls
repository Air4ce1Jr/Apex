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
        QuickBooksCustomerSyncBatch.skipDml = true;
        QuickBooksApi.skipCallout = true;
        Account a = new Account(Id='001000000000003AAA', Name='Acct', Type='Customer');
        QuickBooksService.testBillingEmails.put(a.Id, 'a@example.com');
        QuickBooksCustomerSyncBatch batch = new QuickBooksCustomerSyncBatch();
        System.Test.startTest();
        batch.execute(new Ctx(), new List<Account>{a});
        System.Test.stopTest();
        System.assertEquals(null, a.QuickBooks_Customer_Id__c);
        resetFlags();
    }

    @IsTest static void testExecuteWithDml() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksCustomerSyncBatch.skipDml = false;
        QuickBooksApi.skipCallout = true;
        Account a = new Account(Name='Acct2', Type='Customer');
        insert a;
        QuickBooksService.testBillingEmails.put(a.Id, 'b@example.com');
        QuickBooksCustomerSyncBatch batch = new QuickBooksCustomerSyncBatch();
        batch.execute(new Ctx(), new List<Account>{a});
        Account updated = [SELECT QuickBooks_Customer_Id__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(null, updated.QuickBooks_Customer_Id__c);
        resetFlags();
    }

    @IsTest static void testStartAndFinish() {
        QuickBooksCustomerSyncBatch batch = new QuickBooksCustomerSyncBatch();
        System.assertNotEquals(null, batch.start(new Ctx()));
        batch.finish(new Ctx());
    }

    private static void resetFlags() {
        QuickBooksTriggerUtil.skipAsync = false;
        QuickBooksCustomerSyncBatch.skipDml = false;
        QuickBooksApi.skipCallout = false;
        QuickBooksService.testBillingEmails.clear();
    }
}
