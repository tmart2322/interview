public with sharing class BenefitsMCPAction {

    public class Request {
        @InvocableVariable(required=true) public String memberId;
        @InvocableVariable(required=true) public String cpt;
    }

    public class EligibilityResponse {
        @InvocableVariable public Boolean eligible;
        @InvocableVariable public String networkStatus;
        @InvocableVariable public Boolean priorAuthRequired;
        @InvocableVariable public List<String> reasonCodes;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Check Member Eligibility' description='Calls Benefits MCP check_eligibility tool')
    public static List<EligibilityResponse> checkEligibility(List<Request> requests) {
        List<EligibilityResponse> results = new List<EligibilityResponse>();
        for (Request req : requests) {
            EligibilityResponse res = new EligibilityResponse();
            res.reasonCodes = new List<String>();
            try {
                Map<String, Object> parsed = BenefitsCalloutHelper.call('/mcp/tools/check_eligibility', req.memberId, req.cpt);
                res.eligible = (Boolean) parsed.get('eligible');
                res.networkStatus = (String) parsed.get('network_status');
                res.priorAuthRequired = (Boolean) parsed.get('prior_auth_required');
                Object codes = parsed.get('reason_codes');
                if (codes != null) {
                    for (Object c : (List<Object>) codes) {
                        res.reasonCodes.add(String.valueOf(c));
                    }
                }
            } catch (Exception e) {
                res.errorMessage = 'callout failed: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
