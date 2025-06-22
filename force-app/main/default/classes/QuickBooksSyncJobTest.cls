@IsTest(SeeAllData=true)
private class QuickBooksSyncJobTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(
            Name='Inv',
            rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(),
            rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=5
        );
        insert inv;
        List<Id> ids = new List<Id>{inv.Id};
        System.Test.startTest();
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoice__c', ids));
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testAccountQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        Account a = new Account(Name='Acct');
        insert a;
        System.Test.startTest();
        System.enqueueJob(new QuickBooksSyncJob('Account', new List<Id>{a.Id}));
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testLineAndPaymentQueueable() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='L2', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', rtms__Load__c=load.Id,
            rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1),
            rtms__Invoice_Total__c=2, QuickBooks_Invoice_Id__c='123');
        insert inv;
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        insert acc;
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1,
            QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        insert line;
        rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1, rtms__Check_Reference_Number__c='1');
        pay.put('rtms__Customer_Invoice__c', inv.Id);
        pay.put('rtms__Load__c', load.Id);
        insert pay;
        System.Test.startTest();
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoiceAccessorial__c', new List<Id>{line.Id}));
        System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>{pay.Id}));
        System.Test.stopTest();
        Integer cnt = [SELECT COUNT() FROM AsyncApexJob WHERE JobType='Queueable' AND Status='Completed'];
        System.assert(cnt >= 2);
    }
}

