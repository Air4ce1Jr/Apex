@IsTest(SeeAllData=true)
private class QuickBooksInvoiceServiceTest {
    class QBMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().contains('?minorversion=75'));
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testSendInvoice() {
        System.Test.setMock(HttpCalloutMock.class, new QBMock());
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=15
        );
        insert inv;
        System.Test.startTest();
        QuickBooksInvoiceService.sendInvoice(inv.Id);
        System.Test.stopTest();
    }
}

