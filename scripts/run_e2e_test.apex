// Creates test Account, Invoice, Invoice Line and Payment
// and calls QuickBooksService methods with HttpCalloutMock.

QuickBooksServiceTest.Mock mock = new QuickBooksServiceTest.Mock();
System.Test.setMock(HttpCalloutMock.class, mock);

Account acct = new Account(Name='Test Acct', DBA_Name__c='DBA', BillingStreet='1', BillingCity='Chicago', BillingStateCode='IL', BillingCountryCode='US', BillingPostalCode='60606', QuickBooks_Email__c='test@example.com');
insert acct;

rtms__Load__c load = new rtms__Load__c(Name='Load', rtms__Total_Weight__c=1);
insert load;

rtms__CustomerInvoice__c inv = new rtms__CustomerInvoice__c(Name='Inv', rtms__Load__c=load.Id, rtms__Invoice_Date__c=Date.today(), rtms__Invoice_Due_Date__c=Date.today().addDays(1), rtms__Invoice_Total__c=10);
insert inv;

SObject acc = Schema.getGlobalDescribe().get('rtms__Accessorial__c').newSObject();
acc.put('Name','A');
acc.put('rtms__Mode__c','Truckload');
insert acc;
Id accId = acc.Id;

rtms__CustomerInvoiceAccessorial__c line = new rtms__CustomerInvoiceAccessorial__c(Name='Line', rtms__Charge__c=5, QBO_Item_Id__c='123', rtms__Unit_Price__c=5, rtms__Quantity__c=1);
line.put('rtms__Customer_Invoice__c', inv.Id);
line.put('rtms__Accessorial__c', accId);

rtms__CustomerPayment__c pay = new rtms__CustomerPayment__c(rtms__Payment_Amount__c=5, rtms__Check_Reference_Number__c='CHK1');
pay.put('rtms__Customer_Invoice__c', inv.Id);
pay.put('rtms__Load__c', load.Id);
insert pay;

System.Test.startTest();
QuickBooksService.createOrUpdateCustomer(acct);
QuickBooksService.createOrUpdateInvoice(inv);
QuickBooksService.createInvoiceLines(new List<rtms__CustomerInvoiceAccessorial__c>{line}, '1');
QuickBooksService.createPayment(pay);
System.Test.stopTest();
