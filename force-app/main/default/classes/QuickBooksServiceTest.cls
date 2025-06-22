@IsTest(SeeAllData=true)
private class QuickBooksServiceTest {
    class Mock implements HttpCalloutMock {
        public String lastMethod;
        public HTTPResponse respond(HTTPRequest req) {
            lastMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testCreateCustomer() {
        Mock m = new Mock();
        System.Test.setMock(HttpCalloutMock.class, m);
        Account acct = new Account(Name='a', DBA_Name__c='DBA', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606', rtms__QuickBooks_Email__c='a@example.com');
        insert acct;
        System.Test.startTest();
        QuickBooksService.createOrUpdateCustomer(acct);
        System.assertEquals('POST', m.lastMethod);
        acct.rtms__QuickBooks_Customer_Id__c = '1';
        acct.rtms__QuickBooks_Customer_SyncToken__c = '0';
        QuickBooksService.createOrUpdateCustomer(acct);
        System.assertEquals('PATCH', m.lastMethod);
        System.Test.stopTest();
    }

    @IsTest static void testCreateInvoiceLineAndPayment() {
        Mock m = new Mock();
        System.Test.setMock(HttpCalloutMock.class, m);
        Account acct = new Account(Name='ACC');
        insert acct;
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='inv', rtms__Load__c=load.Id, rtms__Account__c=acct.Id,
            rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1);
        insert inv;
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        insert acc;
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, rtms__QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1, rtms__Check_Reference_Number__c='1');
        pay.put('rtms__Customer_Invoice__c', inv.Id);
        pay.put('rtms__Account__c', acct.Id);
        pay.put('rtms__Load__c', load.Id);
        insert pay;
        System.Test.startTest();
        QuickBooksService.createOrUpdateInvoice(inv);
        System.assertEquals('POST', m.lastMethod);
        inv.rtms__QuickBooks_Invoice_Id__c = '2';
        inv.rtms__QuickBooks_Invoice_SyncToken__c = '0';
        QuickBooksService.createOrUpdateInvoice(inv);
        System.assertEquals('PATCH', m.lastMethod);
        QuickBooksService.createInvoiceLines(new List<rtms__CustomerInvoiceAccessorial__c>{line}, '1');
        QuickBooksService.createPayment(pay);
        System.Test.stopTest();
    }

}
