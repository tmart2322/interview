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

From either Setup → **Agent Actions** → **New Agent Action**, or from inside the MRI Pre-Authorization topic → "This Topic's Actions" tab → **New**.

The form has two screens:
1. **Screen 1 — Connect an existing action**: pick Reference Action Type + Reference Action Category + Reference Action.
2. **Screen 2 — Configure your action for Agent**: fill Label, Description, Loading Text, Inputs, Outputs.

**Exact checkbox names on Screen 2** (SF uses its own terminology):

| My label below | Actual SF checkbox | Meaning |
|---|---|---|
| **Required** (on input) | `Require input` | The LLM must have this value before calling the action |
| **Ask user** (on input) | `Collect data from user` | Agent will prompt the member for this in chat |
| **Hide** (on output) | `Filter from agent action` | Hide this field from the LLM's view (rarely used) |
| **Echo** (on output) | `Show in conversation` | Render this field inline in the chat as a structured chip |

**Every Input AND Output has a required Description field** (red asterisk). Fill all of them — blank Descriptions are the most common "Finish button stays greyed out" cause.

Exact copy-paste values for each of the 5 actions follow.

---

#### Action 1 — Score MRI Pre-Auth Fraud Risk

**Screen 1**:
- Reference Action Type: **Apex**
- Reference Action Category: **Invocable Method**
- Reference Action: **Score Pre-Auth Fraud Risk** *(this is the `@InvocableMethod label` from `FraudAgentAction.scoreRisk`)*
- Click **Next**

**Screen 2**:
- **Agent Action Label**: `Score MRI Pre-Auth Fraud Risk`
- **Agent Action API Name**: `ScoreFraudRisk` *(if prompted)*
- **Agent Action Description** *(this is the "instructions" — tells the LLM when to call the action)*:
  > Score a submitted MRI pre-authorization request for fraud risk on a 0–1 scale using the Vertex AI agent. Call AFTER creating the Case, with memberId, cpt, providerNpi, and indication collected from the member. Returns riskScore (0–1), classification (low_risk/elevated/high_risk), rationale, and flags.
- **Show loading text for this action**: leave checked
- **Loading Text**: `Running fraud risk analysis...`
- **Inputs** (auto-populated from Apex @InvocableVariable):
  | Field | Description to enter | Require input | Collect data from user |
  |---|---|---|---|
  | memberId | Meridian member ID, e.g. M-10047 | ✔ | ✔ |
  | cpt | CPT procedure code being requested, e.g. 73721 | ✔ | ✔ |
  | providerNpi | 10-digit NPI of the ordering provider | ☐ | ✔ |
  | indication | Clinical indication / free-text reason | ☐ | ✔ |
  | riskTier | Payer-assigned risk tier; default standard if unknown | ☐ | ☐ |
  | priorAuthReversals12mo | Reversals in last 12 months; default 0 if unknown | ☐ | ☐ |
  | state | Two-letter state code for member residence | ☐ | ☐ |
- **Outputs** (fill Description for each; leave both checkboxes unchecked):
  | Field | Description |
  |---|---|
  | riskScore | Continuous fraud-risk score between 0 and 1 |
  | classification | low_risk, elevated, or high_risk |
  | rationale | Human-readable explanation citing specific signals |
  | flags | List of explicit risk flags found |
- Click **Finish**.

---

#### Action 2 — Check Member Benefits Eligibility

**Screen 1**:
- Reference Action Type: **Apex**
- Reference Action Category: **Invocable Method**
- Reference Action: **Check Member Eligibility**
- Next.

**Screen 2**:
- **Agent Action Label**: `Check Member Benefits Eligibility`
- **Agent Action API Name**: `CheckEligibility`
- **Agent Action Description**:
  > Verify whether the member is eligible for the requested CPT and whether prior authorization is required. Call in parallel with Score MRI Pre-Auth Fraud Risk after the Case is created. Returns eligible (bool), networkStatus, priorAuthRequired (bool), and reason codes.
- **Loading Text**: `Checking your benefits...`
- **Inputs**:
  | Field | Description | Require input | Collect data from user |
  |---|---|---|---|
  | memberId | Meridian member ID | ✔ | ✔ |
  | cpt | CPT procedure code | ✔ | ✔ |
- **Outputs** (fill Description for each; both checkboxes unchecked):
  | Field | Description |
  |---|---|
  | eligible | Whether the member is eligible for this CPT |
  | networkStatus | in-network, out-of-network, or not-covered |
  | priorAuthRequired | True if prior authorization is required |
  | reasonCodes | Eligibility reason codes |
  | errorMessage | Populated only if the callout failed |
- Finish.

---

#### Action 3 — Get Member Coverage Details

**Screen 1**:
- Type: **Apex** | Category: **Invocable Method** | Reference: **Get Member Coverage**
- Next.

**Screen 2**:
- **Label**: `Get Member Coverage Details`
- **API Name**: `GetCoverage`
- **Description**:
  > Call AFTER eligibility is confirmed to retrieve coverage %, copay, and remaining deductible. Include these numbers in the member's approval message so they know what they will owe.
- **Loading Text**: `Fetching coverage details...`
- **Inputs**:
  | Field | Description | Require input | Collect data from user |
  |---|---|---|---|
  | memberId | Meridian member ID | ✔ | ✔ |
  | cpt | CPT procedure code | ✔ | ✔ |
- **Outputs** (fill Description for each; both checkboxes unchecked):
  | Field | Description |
  |---|---|
  | coveragePct | Percent of cost covered by the plan (0-100) |
  | copay | Member copay in USD |
  | planYearRemainingDeductible | Remaining deductible this plan year in USD |
  | reasonCodes | Coverage reason codes |
  | errorMessage | Populated only if the callout failed |
- Finish.

---

#### Action 4 — Create MRI Pre-Auth Case

**Screen 1**:
- Type: **Apex** | Category: **Invocable Method** | Reference: **Create MRI Pre-Auth Case**
- Next.

**Screen 2**:
- **Label**: `Create MRI Pre-Auth Case`
- **API Name**: `CreatePreAuthCase`
- **Description**:
  > Create a Salesforce Case immediately after collecting memberId, cpt, providerNpi, and indication. SAVE the returned caseId — Update Pre-Auth Case Decision needs it later to record the decision. Do not call any other action before this one.
- **Loading Text**: `Creating your pre-auth case...`
- **Inputs**:
  | Field | Description | Require input | Collect data from user |
  |---|---|---|---|
  | memberId | Meridian member ID | ✔ | ✔ |
  | cpt | CPT procedure code being pre-authorized | ✔ | ✔ |
  | providerNpi | 10-digit NPI of ordering provider | ☐ | ✔ |
  | indication | Clinical indication / reason | ☐ | ✔ |
- **Outputs** (fill Description for each; both checkboxes unchecked):
  | Field | Description |
  |---|---|
  | caseId | Salesforce 18-char Case Id |
  | caseNumber | Human-readable Case number |
- Finish.

---

#### Action 5 — Update Pre-Auth Case Decision

**Screen 1**:
- Type: **Apex** | Category: **Invocable Method** | Reference: **Update Pre-Auth Case Decision**
- Next.

**Screen 2**:
- **Label**: `Update Pre-Auth Case Decision`
- **API Name**: `UpdatePreAuthCase`
- **Description**:
  > Call AFTER fraud score AND benefits eligibility complete. Pass the caseId returned by Create MRI Pre-Auth Case. Set decision="Working" with a generated authNumber in format AUTH-NNNN when riskScore < 0.3 AND eligible AND networkStatus="in-network". Otherwise set decision="Escalated" and put the combined fraud + benefits reasoning in rationale. NEVER auto-deny — denials always route to a human reviewer.
- **Loading Text**: `Finalizing decision...`
- **Inputs**:
  | Field | Description | Require input | Collect data from user |
  |---|---|---|---|
  | caseId | Case Id returned by Create MRI Pre-Auth Case | ✔ | ☐ |
  | decision | "Working" for auto-approve, "Escalated" for human review | ✔ | ☐ |
  | rationale | Combined fraud + benefits reasoning | ☐ | ☐ |
  | authNumber | Format AUTH-NNNN; only set when decision=Working | ☐ | ☐ |
  | riskScore | Fraud risk score 0-1 from Score MRI Pre-Auth Fraud Risk | ☐ | ☐ |
  | fraudClassification | low_risk, elevated, or high_risk from fraud scoring | ☐ | ☐ |
  | fraudFlags | Comma-separated list of fraud flags from fraud scoring | ☐ | ☐ |
- **Outputs** (fill Description for each; both checkboxes unchecked):
  | Field | Description |
  |---|---|
  | caseId | Case Id that was updated |
  | status | New Case Status value |
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

## Step 6 — Data 360: Clinical Encounter History (10 min)

This powers the D360 portion of the demo — showing the agent has access to clinical encounter data from an EHR system (simulating Epic/Cerner) via Data 360's federated data layer.

**Data source**: `https://tmart2322.github.io/interview/clinical-encounters.json`

This JSON contains 10 clinical encounter records for demo members:
- **M-10047 (Jane Doe)**: 4 encounters showing knee pain progression — ortho visit → 12 PT sessions (failed) → ortho follow-up ordering MRI → follow-up awaiting pre-auth
- **M-10099 (Marcus Reyes)**: 4 encounters showing fraud-pattern signals — 3 imaging studies in 4 months, 3 different providers, 4 facilities, no continuity of care
- **M-10101 (Linda Nakamura)**: 2 routine encounters (cardiology, labs)

### Step A — Create the Data Stream (done)

Data Cloud → **Data Streams** → **New** → **File Upload** → upload `data/clinical-encounters.csv`.

The Data Stream auto-creates a DLO with all fields mapped. Confirm it ingested 10 records.

### Step B — Create the Salesforce CRM Data Stream

Data Cloud → **Data Streams** → **New** → **Salesforce CRM** → click **Next**.

1. Select the **Case** object
2. Click **Next** through field mapping — include at minimum: `Id`, `CaseNumber`, `Subject`, `Status`, `Type`, `Origin`, `Description`, `MemberId__c`, `CPTCode__c`, `ProviderNPI__c`, `AuthNumber__c`, `FraudRiskScore__c`, `FraudClassification__c`, `FraudFlags__c`, `CreatedDate`
3. Finish and deploy

This brings your Salesforce pre-auth Cases into Data Cloud alongside the clinical encounters.

### Step C — Data Model Mapping

Data Cloud → **Data Model**:

1. Find the clinical encounters DLO (created automatically in Step A)
2. Click on it → **Add to Data Model**
3. Map it as category **Other** (it's event data, not a person)
4. Create a **relationship** from the clinical encounters DLO to the **Individual** DMO using the `member_id` field
5. Do the same for the Case DLO — relate it to Individual via `MemberId__c`

This links both data sources to the same unified member profile.

### Step D — Identity Resolution

Data Cloud → **Identity Resolution** → **New Ruleset**:

1. Name: `Member Identity`
2. Add a **match rule**: exact match on `member_id` (from clinical encounters) and `MemberId__c` (from Case)
3. **Run** the ruleset once
4. Verify: open a unified profile and confirm you see both clinical encounters and Cases for the same member (e.g. M-10047)

### Demo narrative

"The agent has context about Jane's care history — three office visits showing knee pain progression, 12 sessions of PT with limited improvement, ortho referral. That data lives in the EHR. Data 360 federates it into the member's unified profile — no ETL, no data copy, no HIPAA residency risk."

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
