public with sharing class FraudAgentAction {

    public class Request {
        @InvocableVariable(required=true) public String memberId;
        @InvocableVariable(required=true) public String cpt;
        @InvocableVariable public String providerNpi;
        @InvocableVariable public String indication;
        @InvocableVariable public String riskTier;
        @InvocableVariable public Integer priorAuthReversals12mo;
        @InvocableVariable public String state;
    }

    public class Response {
        @InvocableVariable public Decimal riskScore;
        @InvocableVariable public String classification;
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
                Map<String, Object> memberContext = new Map<String, Object>{
                    'risk_tier' => String.isBlank(req.riskTier) ? 'standard' : req.riskTier,
                    'prior_auth_reversals_12mo' => req.priorAuthReversals12mo == null ? 0 : req.priorAuthReversals12mo,
                    'state' => String.isBlank(req.state) ? 'TX' : req.state,
                    'flags' => new List<String>()
                };
                Map<String, Object> body = new Map<String, Object>{
                    'member_id' => req.memberId,
                    'cpt' => req.cpt,
                    'provider_npi' => String.isBlank(req.providerNpi) ? '0000000000' : req.providerNpi,
                    'indication' => String.isBlank(req.indication) ? 'not specified' : req.indication,
                    'member_context' => memberContext
                };
                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint('callout:VertexFraudAgent/tasks');
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type', 'application/json');
                httpReq.setBody(JSON.serialize(body));
                httpReq.setTimeout(120000);
                HttpResponse httpRes = new Http().send(httpReq);
                if (httpRes.getStatusCode() >= 200 && httpRes.getStatusCode() < 300) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                    if (parsed.get('risk_score') != null) {
                        res.riskScore = (Decimal) parsed.get('risk_score');
                    }
                    res.classification = (String) parsed.get('classification');
                    res.rationale = (String) parsed.get('rationale');
                    Object flagsObj = parsed.get('flags');
                    if (flagsObj != null) {
                        for (Object f : (List<Object>) flagsObj) {
                            res.flags.add(String.valueOf(f));
                        }
                    }
                } else {
                    res.rationale = 'callout failed: HTTP ' + httpRes.getStatusCode();
                }
            } catch (Exception e) {
                res.rationale = 'callout failed: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
