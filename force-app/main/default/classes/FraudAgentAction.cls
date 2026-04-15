public with sharing class FraudAgentAction {

    public class Request {
        @InvocableVariable(required=true) public String memberId;
        @InvocableVariable(required=true) public String cpt;
        @InvocableVariable public String providerNpi;
        @InvocableVariable public String indication;
    }

    public class Response {
        @InvocableVariable public Decimal riskScore;
        @InvocableVariable public String rationale;
        @InvocableVariable public List<String> flags;
    }

    @InvocableMethod(label='Score Pre-Auth Fraud Risk' description='Calls Vertex AI Fraud Agent via A2A')
    public static List<Response> scoreRisk(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.flags = new List<String>();
            try {
                Map<String, Object> body = new Map<String, Object>{
                    'memberId' => req.memberId,
                    'cpt' => req.cpt,
                    'providerNpi' => req.providerNpi,
                    'indication' => req.indication
                };
                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint('callout:VertexFraudAgent/tasks');
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type', 'application/json');
                httpReq.setBody(JSON.serialize(body));
                httpReq.setTimeout(60000);
                HttpResponse httpRes = new Http().send(httpReq);
                if (httpRes.getStatusCode() >= 200 && httpRes.getStatusCode() < 300) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                    if (parsed.get('riskScore') != null) {
                        res.riskScore = (Decimal) parsed.get('riskScore');
                    }
                    res.rationale = (String) parsed.get('rationale');
                    Object flagsObj = parsed.get('flags');
                    if (flagsObj != null) {
                        for (Object f : (List<Object>) flagsObj) {
                            res.flags.add(String.valueOf(f));
                        }
                    }
                } else {
                    res.riskScore = null;
                    res.rationale = 'callout failed: HTTP ' + httpRes.getStatusCode();
                }
            } catch (Exception e) {
                res.riskScore = null;
                res.rationale = 'callout failed: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
