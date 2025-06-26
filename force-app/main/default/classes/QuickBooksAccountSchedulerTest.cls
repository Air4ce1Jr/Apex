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

    @IsTest static void testSchedulerInline() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksAccountScheduler.runInline = true;
        System.Test.startTest();
        new QuickBooksAccountScheduler().execute(null);
        System.Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob]);
        resetFlags();
    }

    @IsTest static void testSchedulerAsyncBypass() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksAccountScheduler.runInline = true;
        QuickBooksCustomerSyncBatch.skipDml = true;
        System.Test.startTest();
        new QuickBooksAccountScheduler().execute(null);
        System.Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob]);
        resetFlags();
    }

    private static void resetFlags() {
        QuickBooksAccountScheduler.runInline = false;
        QuickBooksCustomerSyncBatch.skipDml = false;
    }
}
