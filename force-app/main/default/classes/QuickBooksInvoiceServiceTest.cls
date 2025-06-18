@IsTest
private class QuickBooksInvoiceServiceTest {
    class QBMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testSendInvoice() {
        Test.setMock(HttpCalloutMock.class, new QBMock());
        Test.startTest();
        QuickBooksInvoiceService.sendInvoice(Id.valueOf('001000000000000000'));
        Test.stopTest();
    }
}
