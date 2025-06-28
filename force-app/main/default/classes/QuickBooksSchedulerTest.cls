@IsTest(isParallel=false)
private class QuickBooksSchedulerTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"1","SyncToken":"1"}}');
            return res;
        }
    }

    @IsTest static void testCustomerSchedule() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        new QuickBooksScheduler('Customer').execute(null);
        Test.stopTest();

        String cron = '0 0 0 * * ?';
        Test.startTest();
        String jobId = System.schedule('QBAccount', cron, new QuickBooksScheduler('Customer'));
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @IsTest static void testPaymentSchedule() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        new QuickBooksScheduler('Payment').execute(null);
        Test.stopTest();
    }
}
