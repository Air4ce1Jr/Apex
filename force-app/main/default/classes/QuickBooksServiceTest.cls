@IsTest(SeeAllData=true)
private class QuickBooksServiceTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testCreateCustomer() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        Account acct = new Account(Name='a', DBA_Name__c='DBA', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606', QuickBooks_Email__c='a@example.com');
        insert acct;
        System.Test.startTest();
        QuickBooksService.createOrUpdateCustomer(acct);
        System.Test.stopTest();
    }

    @IsTest static void testCreateInvoiceLineAndPayment() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        insert load;
        Account acct = new Account(Name='A', QuickBooks_Customer_Id__c='QB1');
        insert acct;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='inv', Account__c=acct.Id,
            rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1);
        insert inv;
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        insert acc;
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1,
            rtms__Check_Reference_Number__c='1');
        pay.put('rtms__Customer_Invoice__c', inv.Id);
        pay.put('rtms__Load__c', load.Id);
        pay.put('Account__c', acct.Id);
        insert pay;
        System.Test.startTest();
        QuickBooksService.createOrUpdateInvoice(inv, acct.QuickBooks_Customer_Id__c);
        QuickBooksService.createInvoiceLines(new List<rtms__CustomerInvoiceAccessorial__c>{line}, '1');
        QuickBooksService.createPayment(pay, acct.QuickBooks_Customer_Id__c, '1');
        System.Test.stopTest();
    }
}
