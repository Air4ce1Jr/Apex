public with sharing class QuickBooksInvoiceService {
    private static final String ENDPOINT = '/v3/company/{COMPANY_ID}/invoice';

    public static void sendInvoice(Id invoiceId) {
        String companyId = getCompanyId();
        String resource = ENDPOINT.replace('{COMPANY_ID}', companyId);
        QuickBooksApi.send('POST', resource, new Map<String, Id>{'id' => invoiceId});
    }

    private static String getCompanyId() {
        return '9341454816381446';
    }
}

