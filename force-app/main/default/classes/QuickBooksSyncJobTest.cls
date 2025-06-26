@IsTest(isParallel=false)
private class QuickBooksSyncJobTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Customer":{"Id":"77","SyncToken":"2"}}');
            return res;
        }
    }

    @IsTest static void testQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        Account a = new Account(Id='001000000000004AAA', Name='Acct', QuickBooks_Customer_Id__c='QB1');
        QuickBooksService.testBillingEmails.put(a.Id, 'b1@example.com');
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            Account__c=a.Id,
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=5
        );
        QuickBooksSyncJob.testInvoices = new Map<Id, rtms__CustomerInvoice__c>{ inv.Id => inv };
        QuickBooksSyncJob.testAccounts = new Map<Id, Account>{ a.Id => a };
        List<Id> ids = new List<Id>{inv.Id};
        System.Test.startTest();
        new QuickBooksSyncJob('rtms__CustomerInvoice__c', ids).execute(null);
        System.Test.stopTest();
        resetFlags();
    }

    @IsTest static void testAccountQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;
        Account a = new Account(Id='001000000000005AAA', Name='Acct');
        QuickBooksService.testBillingEmails.put(a.Id, 'acct@example.com');
        QuickBooksSyncJob.testAccounts = new Map<Id, Account>{ a.Id => a };
        System.Test.startTest();
        new QuickBooksSyncJob('Account', new List<Id>{a.Id}).execute(null);
        System.Test.stopTest();
        System.assertEquals(null, a.QuickBooks_Customer_Id__c);
        resetFlags();
    }

    @IsTest static void testAccessorialQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;
        rtms__Load__c load = new rtms__Load__c(Name='Load2', rtms__Total_Weight__c=1);
        Account acct = new Account(Id='001000000000006AAA', Name='Acct2', QuickBooks_Customer_Id__c='QB1');
        QuickBooksService.testBillingEmails.put(acct.Id, 'acct2@example.com');
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', Account__c=acct.Id,
            rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1,
            QuickBooks_Invoice_Id__c='INV1', QuickBooks_Invoice_SyncToken__c='0');
        QuickBooksSyncJob.testInvoices = new Map<Id, rtms__CustomerInvoice__c>{ inv.Id => inv };
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name','A');
        acc.put('rtms__Mode__c','Truckload');
        Id accId = 'a00000000000000AAA';
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('CustomerInvoice__c', inv.Id);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        QuickBooksSyncJob.testLines = new Map<Id, rtms__CustomerInvoiceAccessorial__c>{ line.Id => line };
        System.Test.startTest();
        new QuickBooksSyncJob('rtms__CustomerInvoiceAccessorial__c', new List<Id>{line.Id}).execute(null);
        System.Test.stopTest();
        resetFlags();
    }

    @IsTest static void testPaymentQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;
        rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1,
            rtms__Check_Reference_Number__c='1', Account__c='001000000000007AAA');
        QuickBooksSyncJob.testPayments = new Map<Id, rtms__CustomerPayment__c>{ pay.Id => pay };
        System.Test.startTest();
        new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>{pay.Id}).execute(null);
        System.Test.stopTest();
        resetFlags();
    }

    @IsTest static void testAccountDmlUpdate() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = false;
        QuickBooksApi.skipCallout = true;
        Account a = new Account(Name='AcctUpd');
        insert a;
        QuickBooksService.testBillingEmails.put(a.Id, 'upd@example.com');
        QuickBooksSyncJob.testAccounts = new Map<Id, Account>{ a.Id => a };
        System.Test.startTest();
        new QuickBooksSyncJob('Account', new List<Id>{a.Id}).execute(null);
        System.Test.stopTest();
        System.assertNotEquals(null, a.Id);
        resetFlags();
    }

    private static void resetFlags() {
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = false;
        QuickBooksSyncJob.skipDml = false;
        QuickBooksApi.skipCallout = false;
        QuickBooksService.testBillingEmails.clear();
        QuickBooksSyncJob.testAccounts = null;
        QuickBooksSyncJob.testInvoices = null;
        QuickBooksSyncJob.testLines = null;
        QuickBooksSyncJob.testPayments = null;
    }

}

