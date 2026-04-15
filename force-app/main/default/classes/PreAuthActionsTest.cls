@isTest
public class PreAuthActionsTest {

    private class FraudMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"riskScore":0.08,"rationale":"low risk","flags":[]}');
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
    static void testCreateAndUpdateCase() {
        PreAuthCaseAction.CreateRequest cr = new PreAuthCaseAction.CreateRequest();
        cr.memberId = 'M12345';
        cr.cpt = '70553';
        cr.providerNpi = '1234567890';
        cr.indication = 'Persistent headache >3 months';

        Test.startTest();
        List<PreAuthCaseAction.CreateResponse> created = PreAuthCaseAction.createCase(
            new List<PreAuthCaseAction.CreateRequest>{ cr }
        );
        System.assertEquals(1, created.size());
        System.assertNotEquals(null, created[0].caseId);

        Case c = [SELECT Id, Subject, Status, MemberId__c FROM Case WHERE Id = :created[0].caseId];
        System.assertEquals('MRI Pre-Auth: 70553', c.Subject);
        System.assertEquals('M12345', c.MemberId__c);

        PreAuthCaseAction.UpdateRequest ur = new PreAuthCaseAction.UpdateRequest();
        ur.caseId = created[0].caseId;
        ur.decision = 'Approved';
        ur.rationale = 'Meets medical necessity';
        ur.authNumber = 'AUTH-001';

        List<PreAuthCaseAction.UpdateResponse> updated = PreAuthCaseAction.updateCaseDecision(
            new List<PreAuthCaseAction.UpdateRequest>{ ur }
        );
        System.assertEquals('Approved', updated[0].status);
        Test.stopTest();

        Case after = [SELECT Status, Description FROM Case WHERE Id = :created[0].caseId];
        System.assertEquals('Approved', after.Status);
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
        System.assertEquals('low risk', results[0].rationale);
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

        System.assertEquals(null, results[0].riskScore);
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
        BenefitsMCPAction.Request r = new BenefitsMCPAction.Request();
        r.memberId = 'M1'; r.cpt = '70553';

        Test.startTest();
        List<BenefitsMCPAction.CoverageResponse> results = BenefitsMCPAction.getCoverage(
            new List<BenefitsMCPAction.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(80, results[0].coveragePct);
        System.assertEquals(250, results[0].copay);
        System.assertEquals(450, results[0].planYearRemainingDeductible);
    }

    @isTest
    static void testBenefitsFailure() {
        Test.setMock(HttpCalloutMock.class, new FailMock());
        BenefitsMCPAction.Request r = new BenefitsMCPAction.Request();
        r.memberId = 'M1'; r.cpt = '70553';

        Test.startTest();
        List<BenefitsMCPAction.EligibilityResponse> elig = BenefitsMCPAction.checkEligibility(
            new List<BenefitsMCPAction.Request>{ r }
        );
        List<BenefitsMCPAction.CoverageResponse> cov = BenefitsMCPAction.getCoverage(
            new List<BenefitsMCPAction.Request>{ r }
        );
        Test.stopTest();

        System.assertNotEquals(null, elig[0].errorMessage);
        System.assertNotEquals(null, cov[0].errorMessage);
    }
}
