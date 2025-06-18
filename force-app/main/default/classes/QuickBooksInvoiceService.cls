public with sharing class QuickBooksInvoiceService {
    private static final String ENDPOINT = '/v3/company/{COMPANY_ID}/invoice';

    @future(callout=true)
    public static void sendInvoice(Id invoiceId) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        String companyId = getCompanyId();
        String endpoint = 'callout:QuickBooks_NC' + ENDPOINT.replace('{COMPANY_ID}', companyId);
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Id>{'id' => invoiceId}));

        Http http = new Http();
        http.send(req);
    }

    private static String getCompanyId() {
        // Normally retrieved from a custom setting or metadata
        return '1234567890';
    }
}
