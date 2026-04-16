public with sharing class PreAuthCaseAction {

    public class CreateRequest {
        @InvocableVariable(required=true) public String memberId;
        @InvocableVariable(required=true) public String cpt;
        @InvocableVariable public String providerNpi;
        @InvocableVariable public String indication;
    }

    public class CreateResponse {
        @InvocableVariable public Id caseId;
        @InvocableVariable public String caseNumber;
    }

    @InvocableMethod(label='Create MRI Pre-Auth Case' description='Creates a Case for MRI pre-authorization')
    public static List<CreateResponse> createCase(List<CreateRequest> requests) {
        List<Case> toInsert = new List<Case>();
        for (CreateRequest req : requests) {
            toInsert.add(new Case(
                Subject = 'MRI Pre-Auth: ' + req.cpt,
                Description = req.indication,
                Status = 'New',
                Type = 'MRI Pre-Auth',
                Origin = 'Chat',
                MemberId__c = req.memberId,
                CPTCode__c = req.cpt,
                ProviderNPI__c = req.providerNpi
            ));
        }
        insert toInsert;
        Map<Id, Case> refetched = new Map<Id, Case>(
            [SELECT Id, CaseNumber FROM Case WHERE Id IN :toInsert]
        );
        List<CreateResponse> results = new List<CreateResponse>();
        for (Case c : toInsert) {
            CreateResponse r = new CreateResponse();
            r.caseId = c.Id;
            Case fetched = refetched.get(c.Id);
            r.caseNumber = fetched != null ? fetched.CaseNumber : null;
            results.add(r);
        }
        return results;
    }
}
