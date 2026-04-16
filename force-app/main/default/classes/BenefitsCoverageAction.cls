public with sharing class BenefitsCoverageAction {

    public class Request {
        @InvocableVariable(required=true) public String memberId;
        @InvocableVariable(required=true) public String cpt;
    }

    public class CoverageResponse {
        @InvocableVariable public Decimal coveragePct;
        @InvocableVariable public Decimal copay;
        @InvocableVariable public Decimal planYearRemainingDeductible;
        @InvocableVariable public List<String> reasonCodes;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Get Member Coverage' description='Calls Benefits MCP get_coverage tool')
    public static List<CoverageResponse> getCoverage(List<Request> requests) {
        List<CoverageResponse> results = new List<CoverageResponse>();
        for (Request req : requests) {
            CoverageResponse res = new CoverageResponse();
            res.reasonCodes = new List<String>();
            try {
                Map<String, Object> parsed = BenefitsCalloutHelper.call('/mcp/tools/get_coverage', req.memberId, req.cpt);
                if (parsed.get('coverage_pct') != null) res.coveragePct = (Decimal) parsed.get('coverage_pct');
                if (parsed.get('copay') != null) res.copay = (Decimal) parsed.get('copay');
                if (parsed.get('plan_year_remaining_deductible') != null) res.planYearRemainingDeductible = (Decimal) parsed.get('plan_year_remaining_deductible');
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
