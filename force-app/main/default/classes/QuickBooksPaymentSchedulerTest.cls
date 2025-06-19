@IsTest
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
        String cron = '0 0 0 * * ?';
        Test.startTest();
        String jobId = System.schedule('QBPay', cron, new QuickBooksPaymentScheduler());
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}


