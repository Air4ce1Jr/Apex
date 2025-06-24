bo2hti-codex/test-and-deploy-quickbooks-salesforce-sync
@IsTest(isParallel=false)

@IsTest
 main
private class QuickBooksAccountSchedulerTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"1","SyncToken":"1"}}');
            return res;
        }
    }

    @IsTest static void testScheduler() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
 bo2hti-codex/test-and-deploy-quickbooks-salesforce-sync
        System.Test.startTest();
        new QuickBooksAccountScheduler().execute(null);
        System.Test.stopTest();

        String cron = '0 0 0 * * ?';
        System.Test.startTest();
        String jobId = System.schedule('QBAccount', cron, new QuickBooksAccountScheduler());
        System.Test.stopTest();
        System.assertNotEquals(null, jobId);
 main
    }
}
