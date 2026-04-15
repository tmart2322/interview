# MRI Pre-Auth Agentic Demo — Panel Plan

> Interview: 2026-04-16. Build budget: **4-6 hours**. Mode: **fully live**. Backup recording: **build one anyway** as a 60-second insurance policy (Loom, 10 min to make — non-negotiable).

---

## STATUS (keep current — fresh sessions rely on this)

**Last updated:** 2026-04-15, wave-1-complete

### Wave 1 — parallel code generation (files only, no deploys)
- [x] Vertex AI Fraud Agent (`/gcp/fraud-agent/` — Dockerfile, app/, deploy.sh, openapi.yaml, README)
- [x] Slide deck + talk track (`/slides/deck.md`, `/slides/talk-track.md`)
- [x] Mock data (`/data/sf-cases.json`, `servicenow-cases.json`, `cpt-codes.json`) — 30+30 cases, 21 CPTs; M-10047 wired for demo flow
- [x] Benefits MCP server (`/gcp/benefits-mcp/` — Node/Express, REST + JSON-RPC, Dockerfile, deploy.sh, openapi.yaml, README)
- [x] Meridian Health site (`/site/index.html` + `.github/workflows/pages.yml`) — single-page, snippet marker in place
- [x] SF metadata scaffold (`/force-app/main/default/` — Case.MemberId__c, MRIPreAuthAgentPerms, 2 Named Credentials, 3 invocable Apex classes + test, `manifest/package.xml`)

### Deployments (wave 2 — needs wave 1 done + user creds)
- [ ] GCP: create fresh project, enable Vertex AI + Cloud Run APIs *(user action)*
- [ ] Deploy Vertex Fraud Agent to Cloud Run (us-central1, min-instances=1)
- [ ] Deploy Benefits MCP to Cloud Run (us-central1, min-instances=1)
- [ ] GitHub: create repo `tmart2322/interview` (public), push /site/, enable Pages
- [ ] Deploy SF metadata: `sf project deploy start --source-dir force-app --target-org interview`
- [ ] Update SF Named Credential URLs to real Cloud Run URLs + redeploy

### Salesforce UI work (requires Tristan clicks)
- [ ] Register External Services for FraudAgent + BenefitsMCP via Setup UI
- [ ] Assign `MRIPreAuthAgentPerms` to integration user
- [ ] D360: create External Data Source → GitHub Pages servicenow-cases.json
- [ ] D360: ingest + map to unified Case DMO + identity resolution ruleset
- [ ] Agentforce: build Service Agent + 3 topics (Identity, Case Status, MRI Pre-Auth) + wire 4 actions
- [ ] Agentforce: activate agent, test in preview
- [ ] Embedded Messaging: create Embedded Service deployment, publish, grab snippet
- [ ] Paste snippet into `/site/index.html` at `<!-- AGENTFORCE_EMBEDDED_MESSAGING_SNIPPET -->` marker
- [ ] Redeploy site (git push triggers GH Actions)

### Rehearsal + backup
- [ ] End-to-end dry run #1 — fix what breaks
- [ ] End-to-end dry run #2 — time the full 60-min talk track
- [ ] Warm Cloud Run services (ping both 2x right before panel)
- [ ] Record 90-second backup Loom video
- [ ] Export slide deck to PDF as deeper backup

### Confirmed decisions (do not re-debate)
- Use case: HLS payer MRI pre-authorization, fictional "Meridian Health"
- Stack: Agentforce (orchestrator) + D360 (semantic) + Vertex AI Gemini (A2A) + custom MCP server
- MAF skipped — open-standards narrative (A2A + MCP) is the deliberate choice
- GitHub: `tmart2322/interview`
- GCP: fresh project (TBD ID)
- SF org alias: `interview` (Data Cloud + Agentforce visible in App Launcher)
- Demo mode: fully live with Loom backup

### Known friction
- gh CLI just installed via brew — auth status unverified
- SF org: user confirmed D360 + Agentforce visible; `MRIPreAuthAgentPerms` does NOT exist yet (our deploy creates it)
- User has gcloud authed as tristan@martindev.io; fresh project needs creation

### Resume instructions for a fresh Claude Code session
1. Read this file top-to-bottom (especially this STATUS block)
2. Read `/Users/tristan/projects/interview/CLAUDE.md`
3. `ls` each of `/data /gcp /site /slides /force-app/main/default` to see what's on disk
4. Work the next unchecked box in STATUS; update this file as you complete tasks
5. If Wave 1 agents are still stuck, re-fire them with the prompt `"NOT in plan mode, execute immediately"` as the first line

---

## 0. Reality Check

**Holes I poked (all resolved by scope cuts):**
- Original scope (MAF live + 2 flows + ServiceNow federation + custom MCP + Vertex AI + 2 Agentforce agents) = 8-10 hrs. Not happening.
- MAF cut. Replaced with **A2A (Agentforce → Vertex AI) + MCP (Agentforce → Benefits Verification)**. Stronger story: "open standards over proprietary orchestrator."
- "Identity verification" on a static site is fake. Redesigned as **D360-backed Member ID lookup** (honest: the agent confirms known attributes).
- Recording backup is required even in "live" mode. We'll build it last, in 10 min.

**What this demo proves to the panel:**
1. **Agentforce as the orchestrator**, not a chatbot — multi-tool, multi-agent reasoning with HIPAA guardrails.
2. **D360 as the semantic layer** — federates SF Cases + external "ServiceNow" cases via DMO, resolves member identity.
3. **Open-standard interop** — A2A for Vertex AI, MCP for Benefits Verification. No vendor lock-in.
4. **HIPAA-aware architecture** — PHI handling, Einstein Trust Layer masking, audit trail via Platform Events.
5. **Measurable business value** — MRI pre-auth collapses from 3-7 days (NCQA/URAC median) to <60 seconds.

---

## 1. Business Narrative (for slide 1-3 and the opener)

**Customer persona**: Chief Data & AI Officer at a mid-sized US health payer (~2M members, commercial + Medicare Advantage).

**Business problem**:
- MRI pre-authorization takes 3-7 days on average (CMS/AHIP industry data).
- Delays cause member abrasion, CAHPS score degradation, provider friction.
- Regulatory exposure: several states (TX, CA, NY, WA) have prompt pre-auth statutes with 48-72 hour maximums. CMS Interoperability & Prior Authorization Final Rule (CMS-0057-F) mandates <7 days standard, <72 hours expedited — **in production by Jan 2027**.
- Manual review: fraud, benefits verification, medical necessity each handled in separate systems by separate teams.
- AI sprawl risk: teams spinning up point-solution agents with no governance (exactly what Salesforce's "agentic enterprise" story addresses).

**Measurable outcome**:
- Target: **<60s pre-auth decision for 70% of MRI requests** (low-risk, in-network, clear benefits).
- Member SLA compliance rate: 99% within state-mandated windows.
- Human utilization reviewer volume ↓ 60% → redeployed to complex/appealed cases.
- Estimated payer value: **$8-12 per member per month** operating savings + CAHPS uplift (Star Rating revenue impact for MA plans = material).

**Why Salesforce specifically** (the unavoidable panel question):
- D360 already has 200+ connectors and zero-copy — nobody else has this breadth for healthcare payers.
- Agentforce + Einstein Trust Layer gives compliance-by-design; rolling this on OpenAI/GPT means rebuilding PII masking, audit, and feedback RAG.
- Agentforce is where the CSR and utilization-review workflows already live. Adding an agent here means zero change-management overhead.

---

## 2. Architecture (revised — no MAF)

```
┌──────────────────────────────────────────────────────────────────────┐
│  PATIENT EXPERIENCE LAYER                                            │
│  GitHub Pages static site ──embed──▶ Agentforce Messaging-in-App    │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│  AGENTIC LAYER — Salesforce "interview" org                         │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │  Agentforce Service Agent                                   │     │
│  │  ├─ Topic: Identity Verification (D360 lookup)              │     │
│  │  ├─ Topic: Case Status (unified SF + ServiceNow view)       │     │
│  │  └─ Topic: MRI Pre-Auth Submission                          │     │
│  │       └─ Action: Create Case                                │     │
│  │       └─ Action [A2A] → Vertex AI Fraud Agent               │     │
│  │       └─ Action [MCP] → Benefits Verification Server        │     │
│  │       └─ Action: Synthesize Decision + Update Case          │     │
│  └────────────────────────────────────────────────────────────┘     │
│  Einstein Trust Layer: PII masking, prompt defense, toxicity, audit │
└──────────────────────────────────────────────────────────────────────┘
       │                   │                                │
       │ A2A/HTTPS          │ MCP/HTTPS                     │
       ▼                   ▼                                │
┌─────────────────┐ ┌──────────────────────┐               │
│ Vertex AI Agent │ │ Benefits Verification│               │
│ (Gemini 2.5)    │ │ MCP Server           │               │
│ on Cloud Run    │ │ (Node on Cloud Run)  │               │
│ Fraud scoring + │ │ Returns eligibility, │               │
│ rationale       │ │ CPT coverage, copay  │               │
└─────────────────┘ └──────────────────────┘               │
                                                            ▼
                                      ┌──────────────────────────────┐
                                      │  SEMANTIC LAYER — Data 360   │
                                      │  ┌────────────────────────┐  │
                                      │  │ Member DMO (unified)   │  │
                                      │  │ Case DMO               │  │
                                      │  │   ├─ SF Case (native)  │  │
                                      │  │   └─ ServiceNow Case   │  │
                                      │  │      (External Data    │  │
                                      │  │       Source via HTTP) │  │
                                      │  └────────────────────────┘  │
                                      │  Identity Resolution Ruleset │
                                      └──────────────────────────────┘
```

**Data flow for the "MRI Pre-Auth" demo path**:
1. User types "I need to submit an MRI pre-auth for my knee" in chat widget on GitHub Pages site.
2. Agentforce Service Agent recognizes intent → routes to "MRI Pre-Auth" topic.
3. Agent asks for Member ID (if not already verified) → looks up in D360 → confirms known attributes (name, DOB suffix) → verified.
4. Agent collects: CPT code (or body part → inferred CPT), ordering provider NPI, clinical indication (free text).
5. Agent creates SF Case (type="MRI Pre-Auth", status="In Review").
6. Agent fires **two parallel tool calls**:
   - **A2A → Vertex AI Fraud Agent**: sends {member_id, cpt, provider_npi, indication}. Returns {risk_score: 0-1, rationale, flags[]}.
   - **MCP → Benefits Verification Server**: sends {member_id, cpt}. Returns {eligible: bool, coverage_pct, copay, prior_auth_required, network_status}.
7. Agent synthesizes: if fraud risk < 0.3 AND eligible AND in-network AND medical-necessity-clear → auto-approve. Else → route to human reviewer queue.
8. Agent updates Case with decision + rationale (visible in SF). Trust Layer audit record captures prompt, tool calls, response, masked PHI.
9. Agent responds to user with decision + authorization number (if approved) or expected reviewer SLA (if queued).

**Compliance overlay** (address on one slide, mention throughout):
- **HIPAA Privacy Rule** — minimum-necessary via Agentforce permission sets; only Member ID + clinical context sent to external agents; SSN/address never leave the Trust Layer.
- **HIPAA Security Rule** — TLS 1.3 everywhere; Vertex AI in a BAA-covered GCP project; Cloud Run within VPC-SC perimeter (in production).
- **Einstein Trust Layer** — data masking (PHI tokenized in prompts), zero-retention with Gemini via Vertex, toxicity check, prompt injection defense, audit trail to Data Cloud.
- **CMS-0057-F readiness** — API-first, FHIR-aligned data model (Case → Claim mapping pre-stubbed), audit-ready.
- **State prompt-pay statutes** — architecture hits <60s well within any state cap; scale path discussed in Q&A.
- **Explainability** — every denial includes Vertex AI rationale + benefits reason codes; CMS requires this.

---

## 3. Build Plan — 5 hours, parallelizable where noted

Legend: **[Claude]** = I do it autonomously (you just approve), **[Tristan]** = UI clicks you do, **[Both]** = I prep, you execute.

### Hour 1 — Foundation (parallel tracks)

| Task | Owner | Time | Output |
|---|---|---|---|
| A. Scaffold repo structure (sites/, gcp/, sf-metadata/, slides/, recording/) | [Claude] | 5m | Dirs created |
| B. Generate mock data: 50 members, 120 cases (60 SF + 60 ServiceNow), 20 CPT codes | [Claude] | 15m | JSON fixtures |
| C. Verify `sf` CLI authed to `interview` org; confirm D360 + Agentforce licenses | [Tristan] | 10m | `sf org display` output |
| D. GCP: create/confirm project, enable Vertex AI + Cloud Run APIs | [Tristan] | 15m | Project ID, credentials JSON path |
| E. MuleSoft: confirm we're NOT using it (cut). No action. | — | 0m | — |

### Hour 2 — Data 360 + External Case Source

| Task | Owner | Time | Output |
|---|---|---|---|
| F. Build tiny static JSON endpoint serving "ServiceNow" cases (hosted GitHub Pages) | [Claude] | 20m | `https://<user>.github.io/snow-mock/cases.json` |
| G. D360: set up External Data Source (HTTP JSON) pointing to F | [Tristan] | 20m | ServiceNow_Case__dlm visible |
| H. D360: create unified Case DMO + map both SF and SNOW sources | [Tristan + Claude YAML] | 20m | Unified case view queryable |

**Fallback if D360 External Data Source is fiddly**: load ServiceNow cases directly into D360 via Ingestion API (I script this); narrative becomes "demonstrating the pattern; in prod we'd federate via DataSource connector."

### Hour 3 — External Agents (parallel)

| Task | Owner | Time | Output |
|---|---|---|---|
| I. Vertex AI Fraud Agent: Cloud Run service wrapping Gemini 2.5 with a fraud-scoring system prompt + few-shot examples, A2A-compatible endpoint (`/.well-known/agent.json` + POST `/tasks`) | [Claude] | 45m | `https://fraud-agent-xxx.run.app/` |
| J. Benefits Verification MCP server: Node/Express app speaking MCP over HTTP, tools=`check_eligibility`, `get_coverage` | [Claude] | 30m | `https://benefits-mcp-xxx.run.app/` |

### Hour 4 — Agentforce

| Task | Owner | Time | Output |
|---|---|---|---|
| K. Create External Services in SF pointing to Vertex + Benefits endpoints (OpenAPI specs I generate) | [Claude + Tristan import] | 15m | 2 External Services |
| L. Create 3 Agent Actions (Flows) wrapping External Services + Case create/update | [Claude] | 30m | Metadata deployed via sf CLI |
| M. Build Agentforce Service Agent in Builder: add 3 topics (Identity, Case Status, MRI Pre-Auth) with instructions + actions | [Tristan] | 40m | Agent active in builder |
| N. Publish Embedded Messaging deployment; grab code snippet | [Tristan] | 15m | Snippet to paste into GH Pages |

### Hour 5 — Site + Rehearsal + Recording

| Task | Owner | Time | Output |
|---|---|---|---|
| O. Build GitHub Pages site (1 page: fake payer brand, hero, "Chat with us" button opens Agentforce) | [Claude] | 20m | Deployed to `https://<user>.github.io/healthpayer-demo/` |
| P. End-to-end dry run #1 — fix what breaks | [Both] | 30m | Known-good path |
| Q. End-to-end dry run #2 — rehearse talk track with the demo running | [Tristan] | 30m | Timing confirmed |
| R. Record 90s backup video with Loom while dry run #2 is running | [Tristan] | 10m | `demo-backup.mp4` |

**Buffer: 30-60 min** for the thing that will definitely break.

---

## 4. Talk Track — 60 minutes

Your briefing's 4-segment structure. Times are targets; buy/sell based on panel energy.

### Segment 1 — Intro & Setup (5 min)

> "I'm Tristan, pre-sales architect background, been building Data 360 + Agentforce + MuleSoft for 2 years. Today I want to walk you through a build I did for a fictional mid-sized US health payer — call them Meridian Health — who asked us to compress MRI pre-authorization from 3-7 days down to under a minute, without violating CMS-0057 or any state prompt-pay statute. I'll show you the live system, walk the architecture, and then I want your sharpest questions. Can everyone see the shared screen?"

**Confirm screen share, mic, browser tabs open:**
- Tab 1: Slides
- Tab 2: GitHub Pages site (the patient experience)
- Tab 3: Salesforce Agentforce Builder (showing the agent config)
- Tab 4: Salesforce Case list (to show Case creation live)
- Tab 5: Data 360 DMO view
- Tab 6: GCP Cloud Run console (Vertex + Benefits services)
- Tab 7: Backup video (don't open; only if needed)

### Segment 2 — Business Context (5 min, slides 1-3)

- **Slide 1 — Title**: "Compressing MRI Pre-Authorization from Days to Seconds"
- **Slide 2 — The problem**: 3-7 day SLA, member abrasion, CAHPS impact, CMS-0057-F compliance deadline Jan 2027. Cite specific state statutes (TX Insurance Code §4201.355, CA Health & Safety §1367.01).
- **Slide 3 — The target**: <60s for 70% of requests, 99% state SLA compliance, $8-12 PMPM savings, Star Rating uplift. *"A Meridian CDO told us: 'I don't need another chatbot. I need to not fail a CMS audit in 2027.' That framing drove the architecture."*

### Segment 3 — Architecture Walkthrough (10 min, slides 4-6)

- **Slide 4 — Three-layer Salesforce agentic pattern**: Experience (GH Pages + Embedded Messaging), Agentic (Agentforce + Trust Layer), Semantic (D360 with ServiceNow federation). *"I intentionally left MuleSoft Agent Fabric out today. Our panel question is 'why or why not MAF' — my answer is MAF is the right production choice at 25+ agents, but at 3 agents the orchestration lives well inside Agentforce's planner, and I didn't want to over-engineer for a demo."*
- **Slide 5 — Open-standards integration**: A2A to Vertex AI, MCP to Benefits Verification. *"Two different protocols because they solve two different problems — A2A is about agent-to-agent reasoning handoff, MCP is about giving an agent a well-typed tool. Using both signals that you understand when each applies."*
- **Slide 6 — Compliance-by-design overlay**: Trust Layer masking, BAA-scoped Vertex, audit trail, CMS-0057 readiness, explainability. *"PHI never leaves the Trust Layer unmasked. Vertex AI sees 'PATIENT_1234' not 'Jane Doe.' The unmask happens on response inside the Trust Layer."*

### Segment 4 — Live Demo (20 min)

**Demo flow 1 (6 min) — Unified case view proves D360 value**:
1. Open GH Pages site. Click chat icon.
2. "Hi, I'm a Meridian member and I want to check my recent cases." Agent asks for Member ID.
3. Give Member ID `M-10047`. Agent verifies via D360 attribute match.
4. "Show me my cases." Agent returns 3 cases: 2 from Salesforce (billing + appeal), 1 from ServiceNow (IT password reset for member portal). *"That third case lives in ServiceNow. D360's External Data Source federates it through a zero-copy pattern. Your CDO cares about this because: one request, one semantic model, multiple systems of record. This is the 'unified profile' story with teeth."*

**Demo flow 2 (12 min) — MRI pre-auth orchestration**:
1. Same chat: "I need to submit an MRI pre-auth for my knee."
2. Agent asks: reason (knee pain 3 months), ordering provider (NPI 1234567890), CPT (73721 — MRI lower extremity joint).
3. Agent: "Submitting now..."
4. **Switch to SF Case tab** — Case appears in real time.
5. Agent (in chat): "Running fraud and benefits checks in parallel..." *(narrate: "Two tool calls firing simultaneously — A2A to Vertex, MCP to Benefits")*
6. **Switch to GCP Cloud Run logs briefly** — show the two services receiving requests. *"The Fraud Agent on Vertex is Gemini 2.5 with a grounded system prompt. The Benefits server is a mock today but in production would federate to the payer's claims engine."*
7. Back to chat — agent returns: "Approved. Authorization number AUTH-7731. Your fraud risk was 0.08, benefits covered at 80% in-network, $250 copay. Expected clinical review: none required."
8. **Back to SF Case tab** — Case status = Approved, full audit trail visible including Trust Layer masking log.
9. *"End-to-end: 12 seconds. The before-state was 3-7 days. That's the headline."*

**Demo flow 3 (2 min) — Show what happens when it should deny**:
1. New chat session. Member ID `M-10099` (flagged high-risk in mock data — history of reversed claims).
2. Agent: "Submitting pre-auth for MRI brain (CPT 70553)..."
3. Orchestration runs; Fraud Agent returns risk 0.72 with rationale "6 prior authorizations reversed in 12 months; geographic mismatch between ordering provider and member."
4. Agent: "Routed to clinical review queue. Expected response: 48 hours per Texas §4201.355."
5. Case created with status "In Review" and all context attached for the reviewer. *"A human makes the denial call. That's deliberate — auto-denial on AI is a CMS compliance non-starter."*

### Segment 5 — Architecture Deep-Dive (10 min)

Be ready to volunteer — don't wait to be asked:
- **Why Agentforce as orchestrator, not MAF / LangGraph / Mule flow?** At this scale, Agentforce's planner is sufficient and sits where the work lives. MAF becomes the right answer at 10+ agents or cross-cloud A2A routing. I chose simplicity.
- **Why A2A AND MCP?** Different jobs. A2A is agent-to-agent conversation (stateful task handoff). MCP is tool registration (typed, discoverable actions). Fraud is reasoning, benefits is a deterministic lookup.
- **Why Vertex AI not an AWS Bedrock agent or OpenAI?** Pre-existing BAA in place. Gemini 2.5's native safety + zero-retention policy matter for PHI. Also: open. We could swap providers without changing Agentforce.
- **Why D360 federation instead of copy?** Data residency. ServiceNow data stays in ServiceNow — CMS-0057 likes this; state laws like NYDFS Part 500 require we justify every cross-system copy.
- **What breaks at 100x volume?** (prepare): Embedded Messaging connections scale fine (Salesforce handles). Vertex rate limits get hit — move to provisioned throughput. Cloud Run scales to thousands of concurrent requests. D360 DMO query perf is the real watchpoint — we'd add calculated insights / materialized segments.
- **What breaks under a GDPR / state privacy audit?** Data minimization is OK. We have data residency for EU by running Vertex in europe-west regions. BAA equivalence in EU = DPA. The weak spot: cross-border prompt logging in the Trust Layer — production build needs regional deployment.

### Segment 6 — Q&A (10 min)

**Anticipated probes + your crisp answers:**

| Probe | Answer |
|---|---|
| "What would you do differently with more time?" | "Two things. One: actual MAF integration so we'd have Agent Registry governance at 10+ agents. Two: FHIR-native case model instead of SF Case, to hit CMS-0057 dataflow directly. I stubbed the FHIR mapping but didn't implement it." |
| "Where does this break?" | "Latency tail. P50 is 12s; P99 could be 45s if Vertex is cold or the clinical indication is long. In production: Vertex provisioned throughput + Cloud Run min-instances=3." |
| "How much would this cost to run?" | "Agentforce licensing per conversation + Gemini token costs (~$0.02/pre-auth) + Cloud Run (~$50/mo at 10k pre-auths/day). At $8-12 PMPM savings on 2M members that's $16-24M/yr. ROI ratio ~400x at a payer of this size." |
| "AI denied a claim — who's liable?" | "The AI never denies. Auto-approval only on low-risk, in-network, clear-benefit cases. Denials go to human reviewers with AI-generated rationale as a starting point. That's CMS-0057 compliant and matches medical director workflows." |
| "Show me the Trust Layer logs" | *(Have the Data Cloud audit tab ready to open)*. Point to tokenization event. "Jane Doe → PATIENT_M10047 in prompt, de-tokenized on response." |
| "What if we're using Epic / Cerner not ServiceNow?" | "ServiceNow was my mock. D360 has native FHIR ingestion now — Epic / Cerner hits it via the HL7 FHIR R4 connector. Same pattern, different source." |
| "What about hallucinations?" | "Two defenses. One: grounding — Fraud Agent gets member history JSON, not free-text reasoning space. Two: the agent never generates the authorization number; that's deterministic, generated by the Case create action." |

---

## 5. Slide Deck Outline (12 slides, max)

> Use Keynote or Google Slides, not PowerPoint. Minimal brand. Dark text on white. One idea per slide.

1. **Title** — "Compressing MRI Pre-Auth from Days to Seconds | Meridian Health | Tristan Martin"
2. **The Problem** — 3 stats: "3-7 days avg", "48-72hr state caps", "CMS-0057-F deadline: Jan 2027"
3. **The Target** — <60s decision, 99% SLA, $8-12 PMPM, measurable Star rating impact
4. **Architecture — Three-Layer Pattern** — your diagram: Experience / Agentic / Semantic, Salesforce anchored
5. **Architecture — Open-Standards Integration** — A2A and MCP callout
6. **Compliance Overlay** — HIPAA, Trust Layer, CMS-0057, state prompt-pay. One line each.
7. **Demo** — (placeholder slide, deck goes fullscreen while you demo)
8. **Why Salesforce Anchors This** — D360 breadth, Agentforce Trust Layer, Embedded Messaging. Single sentence per bullet.
9. **What I Cut (and Why)** — "I left MAF out. Here's when to put it back." Candor scores with architects.
10. **Cost & ROI** — Gemini $0.02/auth, Agentforce per-convo, Cloud Run $50/mo. $16-24M/yr saving on 2M lives. 400x ROI.
11. **Scale Story** — What changes at 10x, 100x. Vertex provisioned throughput, D360 calculated insights, MAF introduction.
12. **What's Next** — If I owned this roadmap: FHIR-native case model, MAF integration, clinical RAG for medical necessity, appeals agent.

**Don't include**: team bios, customer logos, pricing pages, anything NeuraFlash-branded, "Thank you" slide (waste).

---

## 6. Pre-Interview Checklist (morning of)

- [ ] 2 browser tabs tested in incognito
- [ ] Cloud Run services pinged to warm them (min 2x each)
- [ ] Agentforce agent tested with 3 happy-path scenarios
- [ ] Backup Loom recording watchable locally (don't rely on network)
- [ ] Slides exported to PDF as deeper backup
- [ ] Calendar invite confirmed; Zoom / whatever tested for screen share
- [ ] Phone on silent
- [ ] Water nearby
- [ ] Laptop charged, charger plugged in

---

## 7. Risks & Fallbacks

| Risk | Likelihood | Mitigation |
|---|---|---|
| D360 External Data Source fiddly in dev org | Medium | Swap to Ingestion API load, same story |
| Vertex AI cold start adds 30s | High | Cloud Run min-instances=1; warm both services before panel |
| Agentforce topic misroutes the intent | Medium | Tight examples in topic config; rehearse exact phrasing |
| Embedded Messaging domain mismatch / CORS | Medium | Use Agentforce-hosted chat URL (not iframe) as fallback |
| Network fails during panel | Low | Backup Loom recording ready |
| Panelist asks about MAF in detail | High | Answer ready: "chose Agentforce planner at this scale; MAF at 10+ agents" |
| Panelist asks to see Trust Layer masking in action | Medium | Have the audit tab pre-loaded; point to a real masked prompt |

---

## 8. Blockers — What I Need From Tristan Before I Start Building

1. **SF org auth**: confirm `sf org display --target-org interview` returns a valid session.
2. **Agentforce license**: confirm Einstein / Agentforce is enabled in that org (Setup → Einstein Setup → toggles).
3. **D360 provisioned**: confirm Data Cloud home appears in App Launcher.
4. **GCP project**: project ID + region preference (recommend us-central1).
5. **GitHub username** for Pages domain.
6. **Domain for the fake payer** (want to register `meridian-health.dev` or use `<user>.github.io/meridian`?).
7. **Branding OK**: using "Meridian Health" fictional payer — any preferred name instead?

Once I have these 7 answers, I can start and run mostly hands-off until Hour 4 (Agentforce Builder clicks).

---

## 9. What I Will NOT Build (explicit scope cuts)

- MuleSoft Agent Fabric (live) — cut per your call
- Real A2A client SDK integration — we'll use HTTPS with an `/.well-known/agent.json` AgentCard and POST /tasks, which is A2A-compatible without the full SDK. If asked, I can defend this as "A2A wire-compatible".
- Real MCP Python/TS SDK — Node HTTP endpoint speaking MCP schema. Same defensibility as above.
- True ServiceNow federation — mock JSON on GH Pages, loaded into D360 as External Data Source.
- FHIR resource model — mentioned as roadmap, not built.
- Einstein Trust Layer custom config beyond defaults — demo uses defaults; narrate the policy.
- Custom Experience Cloud site — plain GitHub Pages is simpler and convincing.
