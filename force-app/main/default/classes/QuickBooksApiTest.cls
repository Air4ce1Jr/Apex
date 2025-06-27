@IsTest
private class QuickBooksApiTest {
    class Mock implements HttpCalloutMock {
        Integer count = 0;
        Integer status;
        public Mock(Integer status){ this.status = status; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (status == 200 && count == 0) {
                res.setStatusCode(500);
            } else {
                res.setStatusCode(status);
                res.setBody('{"ok":true}');
            }
            count++;
            return res;
        }
    }

    @IsTest static void testSendSuccessWithRetry() {
        Mock m = new Mock(200);
        Test.setMock(HttpCalloutMock.class, m);
        Test.startTest();
        HttpResponse res = QuickBooksApi.send('GET', '/v3/company/1/customer', null);
        Test.stopTest();
        System.assertEquals(200, res.getStatusCode());
    }

    @IsTest static void testSendError() {
        Mock m = new Mock(400);
        Test.setMock(HttpCalloutMock.class, m);
        Boolean thrown = false;
        try {
            QuickBooksApi.send('GET', '/v3/company/1/customer', null);
        } catch (Exception e) {
            thrown = true;
        }
        System.assert(thrown);
    }
}

