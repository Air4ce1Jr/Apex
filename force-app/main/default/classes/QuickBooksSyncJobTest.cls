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
        QuickBooksTriggerUtil.skipAsync = true;
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        Account a = new Account(Name='Acct', QuickBooks_Customer_Id__c='QB1');
        insert a;
        insert new Contact(LastName='Billing', Email='b1@example.com', Title='Billing', AccountId=a.Id);
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            Account__c=a.Id,
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=5
        );
        insert inv;
        List<Id> ids = new List<Id>{inv.Id};
        System.Test.startTest();
        new QuickBooksSyncJob('rtms__CustomerInvoice__c', ids).execute(null);
        System.Test.stopTest();
    }

    @IsTest static void testAccountQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        Account a = new Account(Name='Acct');
        insert a;
        insert new Contact(LastName='Billing', Email='acct@example.com', Title='Billing', AccountId=a.Id);
        System.Test.startTest();
        new QuickBooksSyncJob('Account', new List<Id>{a.Id}).execute(null);
        System.Test.stopTest();
        a = [SELECT QuickBooks_Customer_Id__c FROM Account WHERE Id = :a.Id];
        System.assertEquals('77', a.QuickBooks_Customer_Id__c);
    }

    @IsTest static void testAccessorialQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.skipAsync = true;
        rtms__Load__c load = new rtms__Load__c(Name='Load2', rtms__Total_Weight__c=1);
        insert load;
        Account acct = new Account(Name='Acct2', QuickBooks_Customer_Id__c='QB1');
        insert acct;
        insert new Contact(LastName='Billing', Email='acct2@example.com', Title='Billing', AccountId=acct.Id);
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', Account__c=acct.Id,
            rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1,
            QuickBooks_Invoice_Id__c='INV1', QuickBooks_Invoice_SyncToken__c='0');
        insert inv;
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name','A');
        acc.put('rtms__Mode__c','Truckload');
        insert acc;
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('CustomerInvoice__c', inv.Id);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        insert line;
        System.Test.startTest();
        new QuickBooksSyncJob('rtms__CustomerInvoiceAccessorial__c', new List<Id>{line.Id}).execute(null);
        System.Test.stopTest();
    }

}

