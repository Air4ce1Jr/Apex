public with sharing class QuickBooksApi {
    public class QuickBooksException extends Exception {}
    private static final String VERSION_PARAM = '?minorversion=75';
    @TestVisible private static Http HTTP = new Http();

    public static HttpResponse send(String method, String resource, Object body) {
        return send(method, resource, body, 2);
    }

    public static HttpResponse send(String method, String resource, Object body, Integer retries) {
        String endpoint = 'callout:QuickBooks_NC' + resource + VERSION_PARAM;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        if (body != null) {
            req.setBody(JSON.serialize(body));
        }
        HttpResponse res;
        while (true) {
            res = HTTP.send(req);
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                return res;
            }
            if (retries-- <= 0) {
                break;
            }
        }
        throw new QuickBooksException('Callout failed: ' + res.getBody());
    }
}


