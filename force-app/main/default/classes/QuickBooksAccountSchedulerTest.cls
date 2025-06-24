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
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        System.Test.startTest();
        new QuickBooksAccountScheduler().execute(null);
        System.Test.stopTest();
    }
}
