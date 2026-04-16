public with sharing class BenefitsCalloutHelper {
    public static Map<String, Object> call(String path, String memberId, String cpt) {
        Map<String, Object> body = new Map<String, Object>{
            'member_id' => memberId,
            'cpt' => cpt
        };
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BenefitsMCP' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(60000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new CalloutException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
        }
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }
}
