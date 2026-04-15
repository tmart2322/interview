# Talk-Track Cheat Sheet
## Salesforce Data & AI Principal Architect Panel -- 2026-04-16

---

## Opener (say this verbatim, ~30 seconds)

"I'm Tristan. I've spent the last two years building Data 360 and Agentforce solutions for regulated-industry customers. Today I want to show you something I built for a fictional mid-sized US health payer -- Meridian Health, 2 million lives, commercial plus Medicare Advantage. Their CDO told me they don't need another chatbot; they need to not fail a CMS audit in 2027. That framing drove every decision in this architecture. I'll show you the live system, walk the design, and then I want your sharpest questions. Can everyone see the shared screen?"

---

## Segment Timings (60 min total)

| Time | Segment | What you are doing |
|---|---|---|
| 0-5 | Intro + screen confirm | Opener above; confirm tabs visible; briefly name the 3 demo flows |
| 5-10 | Business context | Slides 2-3: problem stats, target metrics |
| 10-20 | Architecture walkthrough | Slides 4-6: three layers, A2A vs MCP, compliance overlay |
| 20-40 | Live demo | 3 flows (detail below); narrate while navigating |
| 40-50 | Architecture deep-dive | Volunteer it -- "Let me go deeper on one thing before Q&A..." |
| 50-60 | Q&A | Probes answered below; close with the closer |

---

## Demo Script

### Pre-demo setup check
- Tab 1: Slides (fullscreen on slide 7)
- Tab 2: GitHub Pages site (Meridian Health patient portal)
- Tab 3: Salesforce Case list view
- Tab 4: GCP Cloud Run console (both services)
- Tab 5: Backup Loom (local only -- do not open unless live breaks)

Ping both Cloud Run services in the 5 minutes before going live. Cold starts are your P99 enemy.

---

### Flow 1 -- Unified Case View (6 min)

Narrate: "This is what a Meridian member sees. A standard web page with an embedded Agentforce chat widget -- zero custom UI code."

1. Open GitHub Pages site. Click chat icon.
2. Type: `Hi, I'd like to check my cases.`
3. Agent asks for Member ID. Type: `M-10047`
4. Agent confirms attributes. Type: `Yes that's me` (or `Confirmed` if the agent is waiting for a token)
5. Type: `Show me all my cases.`
6. Expect 3 cases returned: 2 Salesforce (billing dispute + prior appeal), 1 ServiceNow.

Narrate on case 3: "That third case lives in ServiceNow. Data Cloud's External Data Source federates it through a zero-copy pattern -- no ETL, no duplicate record, no residency issue. Your CDO cares about this because CMS-0057 and state privacy laws require you to justify every cross-system data copy. Here there is none."

---

### Flow 2 -- MRI Pre-Auth Happy Path (12 min)

Narrate: "Same session. Now the member needs to submit a pre-authorization."

1. Type: `I need to submit an MRI pre-auth for my knee.`
2. Agent collects clinical details. Respond to each prompt:
   - CPT code: `73721`
   - NPI: `1234567890`
   - Indication: `Knee pain for 3 months, conservative treatment failed, MRI of left knee ordered by ortho.`
3. Type: `Submit it.`
4. **Switch to Salesforce Case tab.** Narrate: "Case is created in real time -- status In Review, all context attached."
5. Back to chat. Narrate: "Two tool calls firing in parallel now -- A2A to the Vertex AI Fraud Agent, MCP to the Benefits Verification server."
6. **Switch to GCP Cloud Run logs.** Show both services receiving requests. Narrate: "The Fraud Agent is Gemini 2.5 with a grounded system prompt and member history JSON. Benefits Verification is a typed MCP tool -- deterministic response, no LLM involved."
7. **Back to chat.** Expect: `Approved. AUTH-XXXX. 80% coverage in-network, $250 copay.`
8. **Back to Salesforce Case tab.** Show: Case status = Approved, rationale field populated, Trust Layer audit row visible.

Narrate: "End to end: 12 seconds. The before-state was 3-7 days. That is the headline."

---

### Flow 3 -- Denial Routing Path (2 min)

Narrate: "Now I'll show you what happens when the system should not auto-approve. New session."

1. New chat session. Type Member ID: `M-10099`
2. Type: `Submit MRI pre-auth for my head, CPT 70553, NPI 1234567890, indication: severe headaches 2 weeks.`
3. Expect: `Routed to clinical review queue. Expected response within 48 hours per NY state requirements.`

Narrate: "The AI never denies. The fraud agent returned a risk score of 0.72 with rationale -- 6 prior authorizations reversed in 12 months, geographic mismatch on the ordering provider. That context is attached to the Case. A human utilization reviewer makes the adverse determination. That is CMS-0057 compliant and it maps to how medical directors actually work."

---

## Architecture Deep-Dive Volunteer (say this at the 40-min mark)

"Before we open Q&A, let me pull on one thing -- the compliance boundary around the Trust Layer, because I think it is the least obvious part of the design and the most important one for a regulated payer."

Then walk: member context JSON -> Trust Layer tokenization -> masked prompt to Vertex -> response -> de-tokenization -> Case update. Point to the audit record. This takes 3-4 minutes and signals depth without being asked.

---

## 5 Anticipated Probes

**1. "Why not MuleSoft Agent Fabric?"**
At 3 agents, Agentforce's planner handles orchestration cleanly -- MAF's governance overhead is not justified. At 10+ agents, with cross-cloud A2A routing and an agent registry requirement, MAF is the right answer. I prefer to defend a smaller architecture than fake depth on a larger one.

**2. "Where does this break?"**
Tail latency. P99 hits 45 seconds when Vertex cold-starts and the clinical indication is long. Production fix: provisioned throughput on Vertex, Cloud Run min-instances=3 on both services. P50 is 12 seconds; that is the number I demoed.

**3. "How much does this cost to run?"**
$0.02 per pre-auth in Gemini tokens, roughly $50 per month Cloud Run at 10k pre-auths per day, plus Agentforce per-conversation licensing that most payers of this size already have. At $8-12 PMPM savings on 2M lives that is $16-24M per year. ROI is approximately 400x.

**4. "The AI denied a claim -- who is liable?"**
The AI never denies. Auto-approval only on low-risk, in-network, clear-benefit cases -- all three conditions must pass. Everything else routes to a human reviewer with AI-generated rationale as context. The human makes the adverse determination. That is how CMS-0057 requires it to work and it matches medical director workflow.

**5. "What about hallucinations?"**
Two defenses. First, grounding: the Fraud Agent receives member history as structured JSON, not free-text reasoning space -- it cannot invent a claims history that does not exist. Second, determinism: the authorization number comes from the Salesforce Case create action, not from the LLM. The LLM never generates a number it could hallucinate.

---

## Closer (say this verbatim, ~30 seconds)

"I built this in one day on top of standard Salesforce and open protocols. A payer could have a production version of this live in 90 days. The three things I would work on next: a FHIR-native case model to hit CMS-0057 data flow requirements directly; MuleSoft Agent Fabric governance when the agent fleet grows past 10; and a clinical RAG layer that grounds the medical necessity evaluation against the payer's own policy library. Happy to go deep on any of it."

---

## Emergency Fallbacks

| What breaks | What to do |
|---|---|
| Vertex cold start adds 30s | Narrate it: "This is exactly the P99 scenario I described. In production this is a provisioned throughput configuration." |
| D360 federation not working | Switch to fallback: cases loaded via Ingestion API. Narrate: "The pattern is the same; in prod we federate live." |
| Agentforce misroutes intent | Type the exact phrasing from this script. If it still fails, show the Agent Builder config and narrate the expected flow. |
| Embedded Messaging CORS / domain issue | Use Agentforce-hosted chat URL directly. Narrate: "Different deployment method, same agent." |
| Network drops | Open backup Loom from local disk. Do not apologize; say: "I recorded this this morning -- let me show you the same flow." |
