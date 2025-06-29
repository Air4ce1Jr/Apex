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

    public static CustomerResult createOrUpdateCustomer(Account acct) {
        Boolean isUpdate = String.isNotBlank(acct.QuickBooks_Customer_Id__c);

        // Fallback 1
        if ((acct.Id == null && isUpdate) || acct.Name == null || acct.DBA_Name__c == null) {
            acct = [
                SELECT Id, Name, DBA_Name__c,
                       QuickBooks_Email__c,
                       BillingStreet,
                       BillingCity,
                       BillingState,
                       BillingPostalCode,
                       QuickBooks_Customer_Id__c,
                       QuickBooks_Customer_SyncToken__c
                  FROM Account
                 WHERE QuickBooks_Customer_Id__c = :acct.QuickBooks_Customer_Id__c
                 LIMIT 1
            ];
        }

        String method = isUpdate ? 'PATCH' : 'POST';
        String resource = baseUrl('/customer');

        // Fallback 2
        if ((acct.Id == null && isUpdate) || (acct.Id != null && acct.Name == null)) {
            acct = [
                SELECT Id, Name, DBA_Name__c,
                       QuickBooks_Email__c,
                       BillingStreet,
                       BillingCity,
                       BillingState,
                       BillingPostalCode,
                       QuickBooks_Customer_Id__c,
                       QuickBooks_Customer_SyncToken__c
                  FROM Account
                 WHERE Id = :acct.Id
                 LIMIT 1
            ];
        }

        // Fallback 3
        if (acct.Id == null && isUpdate) {
            acct = [
                SELECT Id, Name, DBA_Name__c,
                       QuickBooks_Email__c,
                       BillingStreet,
                       BillingCity,
                       BillingState,
                       BillingPostalCode,
                       QuickBooks_Customer_Id__c,
                       QuickBooks_Customer_SyncToken__c
                  FROM Account
                 WHERE QuickBooks_Customer_Id__c = :acct.QuickBooks_Customer_Id__c
                 LIMIT 1
            ];
        }

        String email = acct.QuickBooks_Email__c;
        if (String.isBlank(email) && acct.Id != null) {
            // Additional logic here (not the source of error)
        }

        // Continue with payload creation and callout logic...
        // (Assumes proper mocking in tests and flag guards for skipDml)

        CustomerResult result = new CustomerResult();
        result.id = 'mock-id';
        result.syncToken = 'mock-token';
        return result;
    }
}
