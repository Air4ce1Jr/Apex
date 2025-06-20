@IsTest(SeeAllData=true)
private class QuickBooksTriggersTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testAccountTrigger() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        Account a = new Account(Name='A');
        System.Test.startTest();
        insert a;
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testPaymentTrigger() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1);
        insert inv;
        rtms__CustomerPayment__c p = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1, rtms__Check_Reference_Number__c='1');
        p.put('rtms__Customer_Invoice__c', inv.Id);
        p.put('rtms__Load__c', load.Id);
        System.Test.startTest();
        insert p;
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }

    @IsTest static void testAccessorialTrigger() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        rtms__Load__c load = new rtms__Load__c(Name='L2', rtms__Total_Weight__c=1);
        insert load;
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv3', rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1);
        insert inv;
        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        insert acc;
        Id accId = acc.Id;
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        line.put('rtms__Accessorial__c', accId);
        System.Test.startTest();
        insert line;
        System.Test.stopTest();
        System.assertEquals('Queueable', [SELECT JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC LIMIT 1].JobType);
    }
}
