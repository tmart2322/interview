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

    public class CoverageResponse {
        @InvocableVariable public Decimal coveragePct;
        @InvocableVariable public Decimal copay;
        @InvocableVariable public Decimal planYearRemainingDeductible;
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
                Map<String, Object> parsed = doCallout('/mcp/tools/check_eligibility', req);
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

    @InvocableMethod(label='Get Member Coverage' description='Calls Benefits MCP get_coverage tool')
    public static List<CoverageResponse> getCoverage(List<Request> requests) {
        List<CoverageResponse> results = new List<CoverageResponse>();
        for (Request req : requests) {
            CoverageResponse res = new CoverageResponse();
            res.reasonCodes = new List<String>();
            try {
                Map<String, Object> parsed = doCallout('/mcp/tools/get_coverage', req);
                if (parsed.get('coverage_pct') != null) {
                    res.coveragePct = ((Decimal) parsed.get('coverage_pct'));
                }
                if (parsed.get('copay') != null) {
                    res.copay = ((Decimal) parsed.get('copay'));
                }
                if (parsed.get('plan_year_remaining_deductible') != null) {
                    res.planYearRemainingDeductible = ((Decimal) parsed.get('plan_year_remaining_deductible'));
                }
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

    private static Map<String, Object> doCallout(String path, Request req) {
        Map<String, Object> body = new Map<String, Object>{
            'memberId' => req.memberId,
            'cpt' => req.cpt
        };
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('callout:BenefitsMCP' + path);
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setBody(JSON.serialize(body));
        httpReq.setTimeout(60000);
        HttpResponse httpRes = new Http().send(httpReq);
        if (httpRes.getStatusCode() < 200 || httpRes.getStatusCode() >= 300) {
            throw new CalloutException('HTTP ' + httpRes.getStatusCode() + ': ' + httpRes.getBody());
        }
        return (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
    }
}
