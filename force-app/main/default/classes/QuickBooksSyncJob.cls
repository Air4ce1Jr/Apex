public with sharing class QuickBooksSyncJob implements Queueable, Database.AllowsCallouts {
    @TestVisible
    public static Boolean skipAsync = false;
    private String sObjectType;
    private List<Id> recordIds;

    public QuickBooksSyncJob(String sObjectType, List<Id> recordIds) {
        this.sObjectType = sObjectType;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {public with sharing class QuickBooksService {
    @TestVisible
    public static Boolean skipDml = false;

    private static final String COMPANY_ID = '9341454816381446';

    private static String baseUrl(String path) {
        return '/v3/company/' + COMPANY_ID + path;
    }

    public class CustomerResult {
        public String id;
        public String syncToken;
    }

    public static CustomerResult createOrUpdateCustomer(Account acct) {
        Boolean isUpdate = String.isNotBlank(acct.QuickBooks_Customer_Id__c);

        if ((acct.Id == null && isUpdate) || acct.Name == null || acct.DBA_Name__c == null) {
            acct = [
                SELECT Id, Name, DBA_Name__c, QuickBooks_Email__c,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
                FROM Account
                WHERE QuickBooks_Customer_Id__c = :acct.QuickBooks_Customer_Id__c
                LIMIT 1
            ];
        }

        // [ ... omitted for brevity: payload build + callout ... ]

        // example of guarding against async job enqueue
        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('Account', new List<Id>{acct.Id}));
        }

        CustomerResult result = new CustomerResult();
        result.id = 'someId';
        result.syncToken = 'someToken';
        return result;
    }

    public static void createOrUpdateInvoice(rtms__CustomerInvoice__c invoice, String customerId) {
        // [ ... prepare payload ... ]

        // callout logic here

        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoice__c', new List<Id>{invoice.Id}));
        }
    }

    public static void createInvoiceLines(List<rtms__CustomerInvoiceAccessorial__c> lines, String invoiceId, String syncToken) {
        // [ ... perform logic ... ]
        // No enqueue logic here unless you later add it
    }

    public static void createPayment(rtms__CustomerPayment__c payment, String customerId, String invoiceId) {
        // [ ... prepare payload ... ]

        // callout logic here

        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>{payment.Id}));
        }
    }
}

        if (sObjectType == 'Account') {
            for (Account acct : [SELECT Id, Name, DBA_Name__c, QuickBooks_Email__c,
                    BillingStreet, BillingCity, BillingState, BillingPostalCode,
                    QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c,
                    (SELECT Id, Email, Title FROM Contacts WHERE Title = 'Billing')
                FROM Account WHERE Id IN :recordIds]) {
                QuickBooksService.createOrUpdateCustomer(acct);
            }
        } else if (sObjectType == 'rtms__CustomerInvoice__c') {
            for (rtms__CustomerInvoice__c inv : [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c, Invoice_Number__c,
                    Invoice_Date__c, Invoice_Due_Date__c,
                    Invoice_Comments__c, QuickBooks_Invoice_Id__c,
                    QuickBooks_Invoice_SyncToken__c
                FROM rtms__CustomerInvoice__c WHERE Id IN :recordIds]) {
                QuickBooksService.createOrUpdateInvoice(inv, inv.Account__r.QuickBooks_Customer_Id__c);
            }
        } else if (sObjectType == 'rtms__CustomerInvoiceAccessorial__c') {
            List<rtms__CustomerInvoiceAccessorial__c> lines = [SELECT Id, Name, rtms__Charge__c,
                    QBO_Item_Id__c, rtms__Unit_Price__c, rtms__Quantity__c,
                    CustomerInvoice__c
                FROM rtms__CustomerInvoiceAccessorial__c WHERE Id IN :recordIds];
            Map<Id, List<rtms__CustomerInvoiceAccessorial__c>> byInv = new Map<Id, List<rtms__CustomerInvoiceAccessorial__c>>();
            for (rtms__CustomerInvoiceAccessorial__c l : lines) {
                if (!byInv.containsKey(l.CustomerInvoice__c)) {
                    byInv.put(l.CustomerInvoice__c, new List<rtms__CustomerInvoiceAccessorial__c>());
                }
                byInv.get(l.CustomerInvoice__c).add(l);
            }
            Map<Id, rtms__CustomerInvoice__c> invoices = new Map<Id, rtms__CustomerInvoice__c>([
                SELECT Id, QuickBooks_Invoice_Id__c, QuickBooks_Invoice_SyncToken__c FROM rtms__CustomerInvoice__c WHERE Id IN :byInv.keySet()
            ]);
            for (Id invId : byInv.keySet()) {
                if (invoices.containsKey(invId)) {
                    rtms__CustomerInvoice__c invRecord = invoices.get(invId);
                    QuickBooksService.createInvoiceLines(byInv.get(invId), invRecord.QuickBooks_Invoice_Id__c, invRecord.QuickBooks_Invoice_SyncToken__c);
                }
            }
        } else if (sObjectType == 'rtms__CustomerPayment__c') {
            for (rtms__CustomerPayment__c pay : [SELECT Id, Account__c, Account__r.QuickBooks_Customer_Id__c,
                    rtms__Payment_Amount__c, rtms__Payment_Date__c,
                    rtms__Check_Reference_Number__c, CustomerInvoice__c, CustomerInvoice__r.QuickBooks_Invoice_Id__c
                FROM rtms__CustomerPayment__c WHERE Id IN :recordIds]) {
                QuickBooksService.createPayment(pay, pay.Account__r.QuickBooks_Customer_Id__c,
                        pay.CustomerInvoice__r.QuickBooks_Invoice_Id__c);
            }
        }
    }
}


