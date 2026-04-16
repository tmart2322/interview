# Setup UI Clickthrough — What's Left

Everything testable via API is deployed. This guide covers the remaining Setup-UI work in the exact order to click it.

**Target org**: `interview` — `https://orgfarm-2fd995e381-dev-ed.develop.my.salesforce.com`
**User**: tristan.ca1dd347e7c1@agentforce.com (permset already assigned)

---

## Already done (don't re-do)

- Named Credentials: `VertexFraudAgent`, `BenefitsMCP` (pointing at live Cloud Run URLs)
- External Services: `VertexFraudAgent` (op: `scoreFraudRisk`), `BenefitsMCP` (ops: `checkEligibility`, `getCoverage`)
- Permission Set `MRIPreAuthAgentPerms` deployed + assigned
- 7 Apex classes deployed (5 invocable actions + helper + test), all tests passing
- Custom field `Case.MemberId__c`
- GitHub Pages publishing `/site/` — JSON fixtures available at:
  - `https://tmart2322.github.io/interview/servicenow-cases.json`
  - `https://tmart2322.github.io/interview/sf-cases.json`
  - `https://tmart2322.github.io/interview/members.json`

---

## Step 1 — Verify Agentforce is enabled (2 min)

Setup → **Einstein Setup** → confirm **Einstein Generative AI** is On.
Setup → **Agents** → if you see "Turn on Agents", toggle on.

If either toggle is off, click it. No downstream step works until both are on.

---

## Steps 2 & 3 — Recreate the 5 Agent Actions in UI, attach to topic (~8 min)

**Why this is necessary**: We deployed 5 `GenAiFunction` metadata records and a `GenAiPlugin` topic that binds them. The Topic shell works (the agent picks "MRI Pre-Authorization" correctly), but the 5 functions are structurally incomplete — Salesforce can't retrieve them and reports:
> "The Input LightningTypeBundle schema for action 'X' could not be found. Please remove and re-add the action from the asset library to ensure schema availability."

The `LightningTypeBundle` is auto-generated only when you pick an Apex class through the Agent Builder UI. XML deploys skip this generation.

### Step A — Confirm the 5 deployed Agent Actions exist

**Setup → Agents → Agent Actions** (or use Quick Find → "Agent Actions").

You should see 5 rows:
- `CheckEligibility`
- `CreatePreAuthCase`
- `GetCoverage`
- `ScoreFraudRisk`
- `UpdatePreAuthCase`

These are the broken-from-metadata ones. They must be deleted before recreating.

### Step B — Delete the 5 broken Actions

For each row: dropdown arrow on the right → **Delete**. Confirm.

If **Delete** is greyed out: open the MRI Pre-Authorization **Topic** (Agent Builder → Topics), remove any action references there, save, then come back to Step B.

### Step C — Create the 5 Actions fresh via UI

**Setup → Agents → Agent Actions → New Agent Action** (blue button, top right).

For each of the 5, walk this form:

#### Action 1 — Score MRI Pre-Auth Fraud Risk
- **Reference Action Type**: **Apex**
- **Reference Action**: `FraudAgentAction.scoreRisk` *(start typing "Fraud" to filter the dropdown)*
- Click **Next**
- **Agent Action Label**: `Score MRI Pre-Auth Fraud Risk`
- **Agent Action API Name**: `ScoreFraudRisk`
- **Agent Action Instructions**:
  > Score a submitted MRI pre-authorization request for fraud risk on a 0–1 scale using the Vertex AI agent. Call this AFTER creating the Case, with memberId, cpt, providerNpi, and indication collected from the member.
- Scroll to **Inputs** (auto-populated from Apex):
  - `memberId`: description "Meridian member ID like M-10047". **Required: yes**. Show in Conversation: yes.
  - `cpt`: description "CPT procedure code". **Required: yes**. Show in Conversation: yes.
  - `providerNpi`: description "10-digit NPI of ordering provider". Required: no. Show in Conversation: yes.
  - `indication`: description "Clinical indication / reason". Required: no. Show in Conversation: yes.
  - `riskTier`, `priorAuthReversals12mo`, `state`: **Show in Conversation: NO** (these come from backend, not the member).
- **Outputs**: verify `riskScore`, `classification`, `rationale`, `flags` appear. No changes needed.
- Click **Finish**.

#### Action 2 — Check Member Benefits Eligibility
- Type: **Apex** | Reference: `BenefitsMCPAction.checkEligibility`
- Label: `Check Member Benefits Eligibility` | API Name: `CheckEligibility`
- Instructions:
  > Verify whether the member is eligible for the requested CPT and whether prior authorization is required. Call in parallel with Score MRI Pre-Auth Fraud Risk.
- Inputs: `memberId` (Required), `cpt` (Required). Show both in Conversation.
- Outputs: `eligible`, `networkStatus`, `priorAuthRequired`, `reasonCodes`, `errorMessage` — no changes.
- Finish.

#### Action 3 — Get Member Coverage Details
- Type: **Apex** | Reference: `BenefitsCoverageAction.getCoverage`
- Label: `Get Member Coverage Details` | API Name: `GetCoverage`
- Instructions:
  > Call AFTER eligibility is confirmed to get coverage %, copay, and remaining deductible. Include copay + coverage % in the member's approval message.
- Inputs: `memberId` (Required), `cpt` (Required).
- Outputs: `coveragePct`, `copay`, `planYearRemainingDeductible`, `reasonCodes`, `errorMessage`.
- Finish.

#### Action 4 — Create MRI Pre-Auth Case
- Type: **Apex** | Reference: `PreAuthCaseAction.createCase`
- Label: `Create MRI Pre-Auth Case` | API Name: `CreatePreAuthCase`
- Instructions:
  > Create a Salesforce Case immediately after collecting memberId, cpt, providerNpi, and indication. The returned caseId MUST be saved — Update Pre-Auth Case Decision needs it later.
- Inputs: `memberId` (Required), `cpt` (Required), `providerNpi` (not required), `indication` (not required).
- Outputs: `caseId`, `caseNumber`.
- Finish.

#### Action 5 — Update Pre-Auth Case Decision
- Type: **Apex** | Reference: `PreAuthUpdateAction.updateCaseDecision`
- Label: `Update Pre-Auth Case Decision` | API Name: `UpdatePreAuthCase`
- Instructions:
  > Call AFTER fraud score and benefits check complete. Pass the caseId returned by Create MRI Pre-Auth Case. Pass decision="Working" with a generated authNumber in format AUTH-NNNN when fraud risk < 0.3 AND eligible AND in-network. Otherwise pass decision="Escalated" and put the fraud/benefits reasoning in rationale. NEVER auto-deny.
- Inputs: `caseId` (Required), `decision` (Required), `rationale` (not required), `authNumber` (not required).
- Outputs: `caseId`, `status`.
- Finish.

### Step D — Attach all 5 Actions to the MRI Pre-Authorization topic

Back in **Agent Builder** (tab showing Meridian Pre-Auth Agent):

1. **Topics** panel on the left → click **MRI Pre-Authorization** to open it.
2. In the center, find the **Actions** section (currently "0 Actions").
3. Click **+ New / Add Action** → pick **This Agent's Action** → select one of the 5 → **Finish**.
4. Repeat for all 5.
5. **Save** the topic.

Verify the topic header now reads **Actions: 5**.

### Step E — Retest in Preview

Click the refresh icon on the Conversation Preview to start a fresh session. Then paste:

> I need to submit an MRI pre-auth for my knee. My Member ID is M-10047.

Agent should ask for CPT / NPI / indication. Reply:

> CPT 73721, NPI 1234567890, torn meniscus confirmed by imaging referral from Dr. Smith

Expected Reasoning flow:
1. `CreatePreAuthCase` (you'll see the Case appear in the Case list tab)
2. `CheckEligibility` **and** `ScoreFraudRisk` in parallel
3. (optional) `GetCoverage`
4. `UpdatePreAuthCase` with decision="Working" + AUTH-NNNN

Expected member-facing response: "Approved. Authorization AUTH-NNNN. 80% coverage, $250 copay..."

Denial-path script — fresh session, same flow but use `M-10099` with CPT `70553`. Expected: `UpdatePreAuthCase` called with decision="Escalated".

---

**If an action fires but errors out**: Setup → Agents → **Event Logs** (or Agent Builder → the specific Reasoning panel step) shows the callout error. The most likely culprits are (a) the Named Credential URL (already patched — should be fine), or (b) a required Apex input the planner didn't populate — edit the Action and relax the "Required" flag, or improve the Action Instructions to tell the planner to collect that input.

**If actions still show 0 after Step D**: take a screenshot of the topic editor showing the Actions area + any save errors, and paste here.

---

## Step 4 — Create the Agent (3 min)

Setup → **Agents** → **New Agent** → choose **Service Agent** (Einstein Service Agent).

- **Name**: Meridian Pre-Auth Agent
- **API Name**: Meridian_PreAuth_Agent
- **Company**: Meridian Health
- **Role**:
  > You are a pre-authorization specialist for Meridian Health, a US health payer. You help members submit MRI pre-authorization requests quickly and compliantly. You operate under HIPAA minimum-necessary — never expose more PHI than the member already provided.
- **Description**: Handles MRI pre-auth requests with parallel fraud + benefits verification.
- When asked which Topics to include, **select "MRI Pre-Authorization"** (already deployed).
- When asked which Planner to use, **select "Meridian Pre-Auth Planner"** (already deployed as `MRIPreAuthPlanner`).
- (Optional: add the OOB "General" topic as a fallback for case-status questions.)

**Leave the agent Inactive for now** — activate in Step 7 after testing.

> Why can't this be metadata? The `Bot` metadata type only accepts `BotType=Bot` or `ExternalCopilot`, both of which require a legacy `entryDialog` + dialog tree that conflicts with planner-based Agentforce agents. The Agent Builder UI generates the correct shape automatically — this is a 30-second click.

---

## Step 5 — Test in Agent Preview (5 min)

In Agent Builder, open **Preview / Conversation Preview**.

Happy-path script:
```
I need to submit an MRI pre-auth.
```
Agent asks for Member ID → reply `M-10047`.
Agent asks for CPT / body part → reply `73721` or "knee MRI".
Agent asks for ordering provider NPI → reply `1234567890`.
Agent asks for clinical indication → reply `knee pain 3 months, failed PT`.

Expect: Case created (you'll see it in the Case tab), parallel fraud + eligibility calls, decision returned ("Approved" + auth number).

Denial-path script: same but use `M-10099` and CPT `70553`. Expect: routed to clinical review ("Escalated").

If any action errors — check Setup → Agents → **Event Logs** for the specific call. Most common issue: a required input isn't marked required on the Agent Action; edit the action and fix.

---

## Step 6 — Data 360 External Data Source (10 min, optional but strong for the demo)

This is what powers the "unified case view" demo flow (Demo Flow 1 in `slides/talk-track.md`).

Data Cloud → **Data Streams** → **New**.
- Source: **External Data Source** (or "Other" → HTTP/JSON depending on UI variant)
- Name: ServiceNow Cases
- URL: `https://tmart2322.github.io/interview/servicenow-cases.json`
- Format: JSON
- Array path: `$`

Map fields onto a DLO (Data Lake Object) named `ServiceNow_Case__dlm`:
- `sys_id` → Id (Primary Key)
- `number` → CaseNumber
- `member_id` → MemberId
- `short_description` → Subject
- `state` → Status
- `opened_at` → CreatedDate (DateTime)

Then Data Cloud → **Data Model** → map `ServiceNow_Case__dlm` into the standard **Case** DMO (or create a unified Case DMO).

**If D360 HTTP JSON source type isn't available in your dev org**, fallback: use the **Ingestion API** — I can generate a one-line `curl` that POSTs the JSON payload to Data Cloud's ingest endpoint. Say the word.

Also create Identity Resolution:
- **Match rule**: MemberId__c (exact match) across Case DMO sources.
- Run ruleset once so the unified profile is queryable.

---

## Step 7 — Embedded Messaging deployment (10 min)

Setup → **Embedded Service Deployments** → **New Deployment**.
- Type: **Messaging for In-App and Web**
- Name: Meridian Chat
- Messaging Channel: create new "Meridian Web Chat" (type: Custom Client)
- **Assign the Meridian Pre-Auth Agent** to the deployment (this is what connects the agent to the chat widget).
- Site Endpoint: `https://tmart2322.github.io` (allowed origin)
- **Publish** → copy the `<script>` snippet.

Paste the snippet into `/Users/tristan/projects/interview/site/index.html` immediately before the `</body>` tag, replacing the HTML comment marker `<!-- AGENTFORCE_EMBEDDED_MESSAGING_SNIPPET -->`.

Commit + push:
```
cd /Users/tristan/projects/interview
git add site/index.html
git commit -m "Wire Agentforce embedded messaging snippet"
git push
```

GitHub Actions redeploys Pages in ~1 min. Then open `https://tmart2322.github.io/interview/` in an incognito window — the chat bubble should appear bottom-right.

---

## Step 8 — Activate the Agent (30 sec)

Back to Setup → Agents → Meridian Pre-Auth Agent → **Activate**.

---

## Pre-Demo Warm-Up (5 min before panel)

```bash
# Warm both Cloud Run services
curl -sS https://fraud-agent-re72ei6qxa-uc.a.run.app/.well-known/agent.json > /dev/null
curl -sS -X POST https://benefits-mcp-re72ei6qxa-uc.a.run.app/mcp/tools/check_eligibility \
  -H "Content-Type: application/json" \
  -d '{"member_id":"M-10047","cpt":"73721"}'

# Fire the agent once in preview to warm Agentforce + LLM cache
# Then open all 7 demo tabs (see slides/talk-track.md § 1)
```

---

## If something breaks mid-demo

| Symptom | Fix |
|---|---|
| Chat widget doesn't load | Open Agent Builder → Preview tab directly; narrate "this is the embedded view but I'll drive from the preview panel." |
| Fraud action errors | Show Cloud Run logs in a pre-opened tab — narrate "Vertex is live, you can see it received the call." Re-prompt the user. |
| Case doesn't appear in SF | Refresh the Case tab manually; narrate "Platform Events land in <1s normally." |
| Whole thing is offline | Cut to 90-second Loom backup (pre-recorded). |

---

## Open items (not deployable via MDAPI in this shape)

- **Bot wrapper for the Agentforce Service Agent**: `BotType` enum rejects Agentforce-specific values; legacy `Bot`/`ExternalCopilot` types require `entryDialog` + dialog trees that don't apply to planner-based agents. Step 4 (Agent Builder UI, 3 min) is the path.
- **Data Cloud Data Streams**: deployable only via Data Kits (2GP packaging), not hand-written XML. Step 6 is the UI path.

Everything else is metadata-managed and reproducible across orgs from `sf project deploy start --source-dir force-app`.
