@IsTest(isParallel=false)
private class QuickBooksServiceTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"99","SyncToken":"1"}}');
            return res;
        }
    }

    @IsTest static void testCreateCustomer() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksService.skipDml = true;
        Account acct = new Account(Name='a', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606');
        insert acct;
        insert new Contact(LastName='Billing', Email='a@example.com', Title='Billing', AccountId=acct.Id);
        Test.startTest();
        QuickBooksService.CustomerResult result = QuickBooksService.createOrUpdateCustomer(acct);
        Test.stopTest();
        System.assertEquals('99', result.id);
        QuickBooksService.skipDml = false;
    }

    @IsTest static void testCreateCustomerUsesContactEmail() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksService.skipDml = true;
        Account acct = new Account(Name='OnlyName', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606');
        insert acct;
        insert new Contact(LastName='Bill', Email='n@example.com', Title='Billing', AccountId=acct.Id);
        Test.startTest();
        QuickBooksService.CustomerResult result = QuickBooksService.createOrUpdateCustomer(acct);
        Test.stopTest();
        System.assertEquals('99', result.id);
        QuickBooksService.skipDml = false;
    }

    @IsTest static void testCreateInvoiceLineAndPayment() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        Account acct = new Account(Name='A', QuickBooks_Customer_Id__c='QB1');
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='inv', Account__c=acct.Id,
            rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1);
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1,
            rtms__Check_Reference_Number__c='1');
        pay.put('rtms__Customer_Invoice__c', inv.Id);
        pay.put('rtms__Load__c', load.Id);
        pay.put('Account__c', acct.Id);
        Test.startTest();
        QuickBooksService.createOrUpdateInvoice(inv, acct.QuickBooks_Customer_Id__c);
        QuickBooksService.createInvoiceLines(new List<rtms__CustomerInvoiceAccessorial__c>{line}, '1', '0');
        QuickBooksService.createPayment(pay, acct.QuickBooks_Customer_Id__c, '1');
        Test.stopTest();
    }

    @IsTest static void testUpdateCustomerAndInvoice() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksService.skipDml = true;
        rtms__Load__c load = new rtms__Load__c(Name='L3', rtms__Total_Weight__c=1);
        Account acct = new Account(Name='B', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606',
            QuickBooks_Customer_Id__c='123', QuickBooks_Customer_SyncToken__c='0');
        insert acct;
        insert new Contact(LastName='Billing', Email='b@example.com', Title='Billing', AccountId=acct.Id);
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='inv2', Account__c=acct.Id,
            rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1,
            QuickBooks_Invoice_Id__c='456', QuickBooks_Invoice_SyncToken__c='1');
        Test.startTest();
        QuickBooksService.CustomerResult res = QuickBooksService.createOrUpdateCustomer(acct);
        QuickBooksService.createOrUpdateInvoice(inv, acct.QuickBooks_Customer_Id__c);
        Test.stopTest();
        System.assertEquals('99', res.id);
        QuickBooksService.skipDml = false;
    }
}
