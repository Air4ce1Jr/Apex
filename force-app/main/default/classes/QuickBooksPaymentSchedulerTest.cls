@IsTest(isParallel=false)
private class QuickBooksPaymentSchedulerTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest static void testScheduler() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        new QuickBooksPaymentScheduler().execute(null);
        Test.stopTest();
    }
}


