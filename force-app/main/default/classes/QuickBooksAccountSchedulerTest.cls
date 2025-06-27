@IsTest(isParallel=false)

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
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        new QuickBooksAccountScheduler().execute(null);
        Test.stopTest();

        String cron = '0 0 0 * * ?';
        Test.startTest();
        String jobId = System.schedule('QBAccount', cron, new QuickBooksAccountScheduler());
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}
