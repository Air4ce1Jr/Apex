public with sharing class QuickBooksService {
    private static final String COMPANY_ID = '9341454816381446';
    private static String baseUrl(String path) {
        return '/v3/company/' + COMPANY_ID + path;
    }

    public static void createOrUpdateCustomer(Account acct) {
        Boolean isUpdate = String.isNotBlank(acct.QuickBooks_Customer_Id__c);
        String method = isUpdate ? 'PATCH' : 'POST';
        String resource = baseUrl('/customer');
        Map<String,Object> body = new Map<String,Object>{
            'DisplayName' => acct.DBA_Name__c,
            'PrimaryEmailAddr' => new Map<String,Object>{'Address'=>acct.QuickBooks_Email__c},
            'BillAddr' => new Map<String,Object>{
                'Line1'=>acct.BillingStreet,
                'City'=>acct.BillingCity,
                'CountrySubDivisionCode'=>acct.BillingState,
                'PostalCode'=>acct.BillingPostalCode
            }
        };
        if (isUpdate) {
            body.put('Id', acct.QuickBooks_Customer_Id__c);
            body.put('SyncToken', acct.QuickBooks_Customer_SyncToken__c);
        } else {
            body.put('Active', true);
        }
        QuickBooksApi.send(method, resource, body);
    }

    public static void createOrUpdateInvoice(rtms__CustomerInvoice__c inv) {
        Boolean isUpdate = String.isNotBlank(inv.QuickBooks_Invoice_Id__c);
        String method = isUpdate ? 'PATCH' : 'POST';
        String resource = baseUrl('/invoice');
        Map<String,Object> body = new Map<String,Object>{
            'CustomerRef' => new Map<String,Object>{'value'=>inv.Account__c},
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

    public static void createInvoiceLines(List<rtms__CustomerInvoiceAccessorial__c> lines, String qboInvoiceId) {
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
            'Line' => payloadLines
        };
        QuickBooksApi.send('POST', resource, body);
    }

    public static void createPayment(rtms__CustomerPayment__c pay) {
        String resource = baseUrl('/payment');
        Map<String,Object> body = new Map<String,Object>{
            'CustomerRef' => new Map<String,Object>{'value'=>pay.Account__c},
            'TotalAmt' => pay.rtms__Payment_Amount__c,
            'TxnDate' => (pay.rtms__Payment_Date__c != null ? String.valueOf(pay.rtms__Payment_Date__c) : null),
            'PaymentRefNum' => pay.rtms__Check_Reference_Number__c,
            'Line' => new List<Object>{
                new Map<String,Object>{
                    'Amount' => pay.rtms__Payment_Amount__c,
                    'LinkedTxn' => new List<Object>{
                        new Map<String,Object>{
                            'TxnId' => pay.CustomerInvoice__c,
                            'TxnType' => 'Invoice'
                        }
                    }
                }
            }
        };
        QuickBooksApi.send('POST', resource, body);
    }
}
