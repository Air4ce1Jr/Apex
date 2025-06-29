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
    // The returned CustomerResult values should be persisted back to the
    // standard Account fields QuickBooks_Customer_Id__c and
    // QuickBooks_Customer_SyncToken__c by the caller.
    public static CustomerResult createOrUpdateCustomer(Account acct) {
        Boolean isUpdate = String.isNotBlank(acct.QuickBooks_Customer_Id__c);
        if ((acct.Id == null && isUpdate) || acct.Name == null || acct.DBA_Name__c == null) {
            acct = [
                SELECT Id, Name,
                       DBA_Name__c,
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
        if ((acct.Id == null && isUpdate) || (acct.Id != null && acct.Name == null)) {
            acct = [
                SELECT Id, Name,
                       DBA_Name__c,
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
        String email = acct.QuickBooks_Email__c;
        if (String.isBlank(email) && acct.Id != null) {
                email = cons[0].Email;
            }
        }
        Map<String,Object> body = new Map<String,Object>{
            'DisplayName' => acct.Name,
            'BillAddr' => new Map<String,Object>{
                'Line1'=>acct.BillingStreet,
                'City'=>acct.BillingCity,
                'CountrySubDivisionCode'=>acct.BillingState,
                'PostalCode'=>acct.BillingPostalCode
            }
        };
        if (String.isNotBlank(email)) {
            body.put('PrimaryEmailAddr', new Map<String,Object>{'Address'=>email});
        }
        if (isUpdate) {
            body.put('Id', acct.QuickBooks_Customer_Id__c);
            body.put('SyncToken', acct.QuickBooks_Customer_SyncToken__c);
        } else {
            body.put('Active', true);
        }
        HttpResponse res = QuickBooksApi.send(method, resource, body);
        CustomerResult result = new CustomerResult();
        try {
            Map<String,Object> wrapper = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            if (wrapper.containsKey('Customer')) {
                Map<String,Object> cust = (Map<String,Object>)wrapper.get('Customer');
                result.id = (String)cust.get('Id');
                Object st = cust.get('SyncToken');
                if (st != null) result.syncToken = String.valueOf(st);
            }
        } catch (Exception e) {
            // Ignore parse errors; result will be empty
        }
        if (!skipDml && acct.Id != null && (String.isNotBlank(result.id) || String.isNotBlank(result.syncToken))) {
            Account upd = new Account(Id=acct.Id);
            Boolean changed = false;
            if (String.isNotBlank(result.id)) {
                upd.QuickBooks_Customer_Id__c = result.id;
                changed = true;
            }
            if (String.isNotBlank(result.syncToken)) {
                upd.QuickBooks_Customer_SyncToken__c = result.syncToken;
                changed = true;
            }
            if (changed) update upd;
        }
        return result;
    }

    public static void createOrUpdateInvoice(rtms__CustomerInvoice__c inv, String qbCustomerId) {
        Boolean isUpdate = String.isNotBlank(inv.QuickBooks_Invoice_Id__c);
        String method = isUpdate ? 'PATCH' : 'POST';
        String resource = baseUrl('/invoice');
        Map<String,Object> body = new Map<String,Object>{
            'CustomerRef' => new Map<String,Object>{'value'=>qbCustomerId},
            'DocNumber' => inv.Invoice_Number__c,
            'TxnDate' => (inv.Invoice_Date__c != null ? String.valueOf(inv.Invoice_Date__c) : null),
            'DueDate' => (inv.Invoice_Due_Date__c != null ? String.valueOf(inv.Invoice_Due_Date__c) : null),
            'PrivateNote' => inv.Invoice_Comments__c
        };
        if (isUpdate) {
            body.put('Id', inv.QuickBooks_Invoice_Id__c);
            body.put('SyncToken', inv.QuickBooks_Invoice_SyncToken__c);
        }
        QuickBooksApi.send(method, resource, body);
    }

    public static void createInvoiceLines(List<rtms__CustomerInvoiceAccessorial__c> lines, String qboInvoiceId, String syncToken) {
        String resource = baseUrl('/invoice');
        List<Object> payloadLines = new List<Object>();
        for (rtms__CustomerInvoiceAccessorial__c line : lines) {
            payloadLines.add(new Map<String,Object>{
                'DetailType' => 'SalesItemLineDetail',
                'Description' => line.Name,
                'Amount' => line.rtms__Charge__c,
                'SalesItemLineDetail' => new Map<String,Object>{
                    'ItemRef' => new Map<String,Object>{'value'=>line.QBO_Item_Id__c},
                    'UnitPrice' => line.rtms__Unit_Price__c,
                    'Qty' => line.rtms__Quantity__c
                }
            });
        }
        Map<String,Object> body = new Map<String,Object>{
            'Id' => qboInvoiceId,
            'SyncToken' => syncToken,
            'sparse' => true,
            'Line' => payloadLines
        };
        QuickBooksApi.send('PATCH', resource, body);
    }

    public static void createPayment(rtms__CustomerPayment__c pay, String qbCustomerId, String qbInvoiceId) {
        String resource = baseUrl('/payment');
        Map<String,Object> body = new Map<String,Object>{
            'CustomerRef' => new Map<String,Object>{'value'=>qbCustomerId},
            'TotalAmt' => pay.rtms__Payment_Amount__c,
            'TxnDate' => (pay.rtms__Payment_Date__c != null ? String.valueOf(pay.rtms__Payment_Date__c) : null),
            'PaymentRefNum' => pay.rtms__Check_Reference_Number__c,
            'Line' => new List<Object>{
                new Map<String,Object>{
                    'Amount' => pay.rtms__Payment_Amount__c,
                    'LinkedTxn' => new List<Object>{
                        new Map<String,Object>{
                            'TxnId' => qbInvoiceId,
                            'TxnType' => 'Invoice'
                        }
                    }
                }
            }
        };
        QuickBooksApi.send('POST', resource, body);
    }
}
