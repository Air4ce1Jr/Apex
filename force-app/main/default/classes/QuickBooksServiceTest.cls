public with sharing class QuickBooksService {
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

    // Synchronizes an Account record with QuickBooks.
    public static CustomerResult createOrUpdateCustomer(Account acct) {
        Boolean isUpdate = String.isNotBlank(acct.QuickBooks_Customer_Id__c);

        // Ensure necessary fields are loaded for create/update logic
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

        if ((acct.Id == null && isUpdate) || (acct.Id != null && acct.Name == null)) {
            acct = [
                SELECT Id, Name, DBA_Name__c, QuickBooks_Email__c,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
                  FROM Account
                 WHERE Id = :acct.Id
                 LIMIT 1
            ];
        }

        if (acct.Id == null && isUpdate) {
            acct = [
                SELECT Id, Name, DBA_Name__c, QuickBooks_Email__c,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       QuickBooks_Customer_Id__c, QuickBooks_Customer_SyncToken__c
                  FROM Account
                 WHERE QuickBooks_Customer_Id__c = :acct.QuickBooks_Customer_Id__c
                 LIMIT 1
            ];
        }

        // (Payload construction and HTTP callout omitted)

        // Enqueue async sync job only when allowed
        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('Account', new List<Id>{acct.Id}));
        }

        // Return the result object
        CustomerResult result = new CustomerResult();
        result.id = acct.QuickBooks_Customer_Id__c;
        result.syncToken = acct.QuickBooks_Customer_SyncToken__c;
        return result;
    }

    // Synchronizes customer invoice
    public static void createOrUpdateInvoice(rtms__CustomerInvoice__c invoice, String customerId) {
        // (Payload construction and HTTP callout omitted)

        // Enqueue async sync job after callout
        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerInvoice__c', new List<Id>{invoice.Id}));
        }
    }

    // Creates invoice lines
    public static void createInvoiceLines(List<rtms__CustomerInvoiceAccessorial__c> lines, String invoiceId, String syncToken) {
        // No async job for lines (handled within batch or job itself)
    }

    // Creates payment
    public static void createPayment(rtms__CustomerPayment__c payment, String customerId, String invoiceId) {
        // (Payload construction and HTTP callout omitted)

        if (!QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
            System.enqueueJob(new QuickBooksSyncJob('rtms__CustomerPayment__c', new List<Id>{payment.Id}));
        }
    }
}
