@isTest
public class PreAuthActionsTest {

    private class FraudMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"risk_score":0.08,"classification":"low_risk","rationale":"low risk","flags":[]}');
            return res;
        }
    }

    private class EligibilityMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"eligible":true,"network_status":"in-network","prior_auth_required":true,"reason_codes":[]}');
            return res;
        }
    }

    private class CoverageMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"coverage_pct":80,"copay":250,"plan_year_remaining_deductible":450,"reason_codes":[]}');
            return res;
        }
    }

    private class FailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('boom');
            return res;
        }
    }

    @isTest
    static void testCreateCase() {
        PreAuthCaseAction.CreateRequest cr = new PreAuthCaseAction.CreateRequest();
        cr.memberId = 'M12345';
        cr.cpt = '70553';
        cr.providerNpi = '1234567890';
        cr.indication = 'Persistent headache >3 months';

        Test.startTest();
        List<PreAuthCaseAction.CreateResponse> created = PreAuthCaseAction.createCase(
            new List<PreAuthCaseAction.CreateRequest>{ cr }
        );
        Test.stopTest();

        System.assertEquals(1, created.size());
        System.assertNotEquals(null, created[0].caseId);
        Case c = [SELECT Subject, MemberId__c FROM Case WHERE Id = :created[0].caseId];
        System.assertEquals('MRI Pre-Auth: 70553', c.Subject);
        System.assertEquals('M12345', c.MemberId__c);
    }

    @isTest
    static void testUpdateCase() {
        Case c = new Case(Subject='MRI Pre-Auth: 70553', Status='New', MemberId__c='M12345');
        insert c;

        PreAuthUpdateAction.UpdateRequest ur = new PreAuthUpdateAction.UpdateRequest();
        ur.caseId = c.Id;
        ur.decision = 'Working';
        ur.rationale = 'Meets medical necessity';
        ur.authNumber = 'AUTH-001';

        Test.startTest();
        List<PreAuthUpdateAction.UpdateResponse> updated = PreAuthUpdateAction.updateCaseDecision(
            new List<PreAuthUpdateAction.UpdateRequest>{ ur }
        );
        Test.stopTest();

        System.assertEquals('Working', updated[0].status);
        Case after = [SELECT Status, Description FROM Case WHERE Id = :c.Id];
        System.assert(after.Description.contains('AUTH-001'));
    }

    @isTest
    static void testFraudAgentSuccess() {
        Test.setMock(HttpCalloutMock.class, new FraudMock());
        FraudAgentAction.Request r = new FraudAgentAction.Request();
        r.memberId = 'M1'; r.cpt = '70553'; r.providerNpi = '1'; r.indication = 'x';

        Test.startTest();
        List<FraudAgentAction.Response> results = FraudAgentAction.scoreRisk(
            new List<FraudAgentAction.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(0.08, results[0].riskScore);
        System.assertEquals('low_risk', results[0].classification);
    }

    @isTest
    static void testFraudAgentFailure() {
        Test.setMock(HttpCalloutMock.class, new FailMock());
        FraudAgentAction.Request r = new FraudAgentAction.Request();
        r.memberId = 'M1'; r.cpt = '70553';

        Test.startTest();
        List<FraudAgentAction.Response> results = FraudAgentAction.scoreRisk(
            new List<FraudAgentAction.Request>{ r }
        );
        Test.stopTest();

        System.assert(results[0].rationale.startsWith('callout failed'));
    }

    @isTest
    static void testCheckEligibility() {
        Test.setMock(HttpCalloutMock.class, new EligibilityMock());
        BenefitsMCPAction.Request r = new BenefitsMCPAction.Request();
        r.memberId = 'M1'; r.cpt = '70553';

        Test.startTest();
        List<BenefitsMCPAction.EligibilityResponse> results = BenefitsMCPAction.checkEligibility(
            new List<BenefitsMCPAction.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].eligible);
        System.assertEquals('in-network', results[0].networkStatus);
        System.assertEquals(true, results[0].priorAuthRequired);
    }

    @isTest
    static void testGetCoverage() {
        Test.setMock(HttpCalloutMock.class, new CoverageMock());
        BenefitsCoverageAction.Request r = new BenefitsCoverageAction.Request();
        r.memberId = 'M1'; r.cpt = '70553';

        Test.startTest();
        List<BenefitsCoverageAction.CoverageResponse> results = BenefitsCoverageAction.getCoverage(
            new List<BenefitsCoverageAction.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(80, results[0].coveragePct);
        System.assertEquals(250, results[0].copay);
        System.assertEquals(450, results[0].planYearRemainingDeductible);
    }

    @isTest
    static void testBenefitsFailure() {
        Test.setMock(HttpCalloutMock.class, new FailMock());
        BenefitsMCPAction.Request eReq = new BenefitsMCPAction.Request();
        eReq.memberId = 'M1'; eReq.cpt = '70553';
        BenefitsCoverageAction.Request cReq = new BenefitsCoverageAction.Request();
        cReq.memberId = 'M1'; cReq.cpt = '70553';

        Test.startTest();
        List<BenefitsMCPAction.EligibilityResponse> elig = BenefitsMCPAction.checkEligibility(
            new List<BenefitsMCPAction.Request>{ eReq }
        );
        List<BenefitsCoverageAction.CoverageResponse> cov = BenefitsCoverageAction.getCoverage(
            new List<BenefitsCoverageAction.Request>{ cReq }
        );
        Test.stopTest();

        System.assertNotEquals(null, elig[0].errorMessage);
        System.assertNotEquals(null, cov[0].errorMessage);
    }
}
