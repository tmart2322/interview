public with sharing class PreAuthUpdateAction {

    public class UpdateRequest {
        @InvocableVariable(required=true) public Id caseId;
        @InvocableVariable(required=true) public String decision;
        @InvocableVariable public String rationale;
        @InvocableVariable public String authNumber;
    }

    public class UpdateResponse {
        @InvocableVariable public Id caseId;
        @InvocableVariable public String status;
    }

    @InvocableMethod(label='Update Pre-Auth Case Decision' description='Updates Case with pre-auth decision and rationale')
    public static List<UpdateResponse> updateCaseDecision(List<UpdateRequest> requests) {
        Set<Id> ids = new Set<Id>();
        for (UpdateRequest req : requests) ids.add(req.caseId);
        Map<Id, Case> existing = new Map<Id, Case>(
            [SELECT Id, Description FROM Case WHERE Id IN :ids]
        );
        List<Case> toUpdate = new List<Case>();
        List<UpdateResponse> results = new List<UpdateResponse>();
        for (UpdateRequest req : requests) {
            Case c = existing.get(req.caseId);
            if (c == null) continue;
            c.Status = req.decision;
            String appended = (c.Description == null ? '' : c.Description + '\n\n')
                + 'Decision: ' + req.decision
                + (req.authNumber != null ? ' (Auth #' + req.authNumber + ')' : '')
                + (req.rationale != null ? '\nRationale: ' + req.rationale : '');
            c.Description = appended;
            toUpdate.add(c);
            UpdateResponse r = new UpdateResponse();
            r.caseId = c.Id;
            r.status = req.decision;
            results.add(r);
        }
        update toUpdate;
        return results;
    }
}
