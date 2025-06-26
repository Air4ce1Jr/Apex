@IsTest
private class QuickBooksTriggersTest {
    class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest static void testTriggersInline() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = true;
        QuickBooksTriggerUtil.skipAsync = false;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;

        Account a = new Account(Name='A', DBA_Name__c='A DBA');
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1, rtms__Accounting_Status__c='Ready for Accounting');
        rtms__CustomerPayment__c p = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1, rtms__Check_Reference_Number__c='1');

        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);

        System.Test.startTest();
        insert a;
        insert load;
        inv.put('rtms__Load__c', load.Id);
        insert inv;
        p.put('rtms__Load__c', load.Id);
        p.put('rtms__Customer_Invoice__c', inv.Id);
        p.put('Account__c', a.Id);
        insert p;
        insert acc;
        line.put('rtms__Accessorial__c', acc.Id);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        insert line;
        System.Test.stopTest();
        QuickBooksApi.skipCallout = false;

        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType='Queueable']);
        resetFlags();
    }

    @IsTest static void testTriggersAsync() {
        System.Test.setMock(HttpCalloutMock.class, new Mock());
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = true;
        QuickBooksSyncJob.skipDml = true;
        QuickBooksApi.skipCallout = true;

        Account a = new Account(Name='A', DBA_Name__c='A DBA');
        rtms__Load__c load = new rtms__Load__c(Name='L', rtms__Total_Weight__c=1);
        rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv2', rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=1, rtms__Accounting_Status__c='Ready for Accounting');
        rtms__CustomerPayment__c p = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=1, rtms__Check_Reference_Number__c='1');

        SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
        acc.put('Name', 'A');
        acc.put('rtms__Mode__c', 'Truckload');
        rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='line', rtms__Charge__c=1, QBO_Item_Id__c='1', rtms__Unit_Price__c=1, rtms__Quantity__c=1);
        line.put('rtms__Customer_Invoice__c', inv.Id);

        System.Test.startTest();
        insert a;
        insert load;
        inv.put('rtms__Load__c', load.Id);
        insert inv;
        p.put('rtms__Load__c', load.Id);
        p.put('rtms__Customer_Invoice__c', inv.Id);
        p.put('Account__c', a.Id);
        insert p;
        insert acc;
        line.put('rtms__Accessorial__c', acc.Id);
        line.put('rtms__Customer_Invoice__c', inv.Id);
        insert line;
        System.Test.stopTest();
        QuickBooksApi.skipCallout = false;

        Integer jobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType='Queueable'];
        System.assertEquals(0, jobs);
        resetFlags();
    }

    private static void resetFlags() {
        QuickBooksTriggerUtil.runInline = false;
        QuickBooksTriggerUtil.skipAsync = false;
        QuickBooksSyncJob.skipDml = false;
        QuickBooksApi.skipCallout = false;
    }
}
