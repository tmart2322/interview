---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'Helvetica Neue', Arial, sans-serif;
    font-size: 22px;
    color: #1a1a1a;
    background: #ffffff;
    padding: 48px 64px;
  }
  h1 { font-size: 2em; font-weight: 700; margin-bottom: 0.2em; }
  h2 { font-size: 1.4em; font-weight: 600; border-bottom: 2px solid #0070d2; padding-bottom: 0.2em; }
  ul { margin-top: 0.5em; }
  li { margin-bottom: 0.4em; }
  code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-size: 0.85em; }
  pre { background: #f4f4f4; padding: 16px; border-radius: 4px; font-size: 0.75em; }
  .label { font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.1em; color: #666; }
---

# Compressing MRI Pre-Authorization from Days to Seconds

**Meridian Health | Data & AI Architect Panel**

Tristan Martin | 2026-04-16

<!-- speaker notes
SAY: "Thanks for the time. I'll set context fast, walk the live system, then I want your sharpest questions."
Context sentence: Meridian Health, fictional US payer, 2M lives, commercial + Medicare Advantage.
Confirm screen share and that all panelists can hear before advancing.

DO NOT SAY: anything about job history or personal background yet -- that belongs in a 20-second intro sentence, not a slide read.

TRANSITION: "Let me start with the problem I was handed."
-->

---

## The Problem

- 3-7 day average pre-authorization turnaround (AHIP industry benchmark)
- State statutes cap at 48-72 hours: TX, CA, NY, WA already in force
- CMS-0057-F mandates &lt;7 days standard / &lt;72 hours expedited -- effective January 2027

<!-- speaker notes
SAY: "Meridian's CDO put it plainly: 'I don't need another chatbot. I need to not fail a CMS audit in 2027.' That line drove every architecture decision here."
Cite TX Insurance Code 4201.355, CA Health & Safety 1367.01 if asked -- don't volunteer the cite numbers unprompted.
Manual review today: fraud, benefits, and medical necessity each live in a separate system worked by separate teams. That's the toil we're replacing.

DO NOT SAY: vague statements about "improving member experience" -- panelists will dismiss it. Stay on the regulatory deadline as the forcing function.

TRANSITION: "So here is the specific target we designed to."
-->

---

## The Target

- **&lt;60 seconds** for 70% of MRI pre-auths (low-risk, in-network, clear benefits)
- **99%** state SLA compliance across TX, CA, NY, WA
- **$8-12 PMPM** operating savings (human reviewer volume down 60%)
- **Star Rating uplift** on MA plans via CAHPS improvement

<!-- speaker notes
SAY: "These are the four numbers that define success. Everything in the architecture traces back to one of them."
The 70% figure is deliberate -- the remaining 30% includes complex cases and appeals that should stay with human reviewers. That's not a gap in the system; it's correct clinical governance.
$8-12 PMPM at 2M lives = $16-24M/yr. That number comes up again on the ROI slide.

DO NOT SAY: "we could automate everything" -- panelists will immediately probe AI liability. Let the 70% number do the work.

TRANSITION: "Here is how the architecture delivers those numbers."
-->

---

## Three-Layer Architecture

```
EXPERIENCE LAYER
  GitHub Pages static site ---embed---> Agentforce Embedded Messaging

AGENTIC LAYER  (Salesforce)
  Agentforce Service Agent
    Topic: Identity Verification  (D360 member lookup)
    Topic: Case Status            (SF + ServiceNow unified view)
    Topic: MRI Pre-Auth           (orchestrates two parallel tool calls)
      Action [A2A]  ---> Vertex AI Fraud Agent (Gemini 2.5, Cloud Run)
      Action [MCP]  ---> Benefits Verification Server (Node, Cloud Run)
  Einstein Trust Layer: PHI masking | audit trail | prompt defense

SEMANTIC LAYER  (Data Cloud / D360)
  Member DMO   -- identity resolution across systems
  Case DMO     -- SF Cases (native) + ServiceNow Cases (External Data Source)
```

<!-- speaker notes
SAY: "Three layers, each with a single job. Experience: zero-friction for the member. Agentic: orchestration and compliance. Semantic: unified data without moving it."
Key phrase to use: "The Trust Layer sits between every external call. PHI never reaches Vertex unmasked."
Point to the A2A and MCP labels -- they come up on the next slide.

DO NOT SAY: "and we could easily add more agents" -- that invites the MAF question before you're ready. Address MAF on slide 9.

TRANSITION: "Two integration protocols in that architecture -- let me explain why I used both."
-->

---

## Open-Standards Integration

**A2A (Agent-to-Agent) -- Vertex AI Fraud Agent**
- Stateful task handoff: agent sends context, remote agent reasons and responds
- Wire-compatible: `/.well-known/agent.json` AgentCard + `POST /tasks`
- Right choice when the remote end needs to *reason*, not just look something up

**MCP (Model Context Protocol) -- Benefits Verification**
- Typed, discoverable tool registration
- `check_eligibility` and `get_coverage` tools; deterministic responses
- Right choice when the remote end returns structured data

> Two protocols because they solve two different problems.

<!-- speaker notes
SAY: "The distinction matters architecturally. A2A is about agent-to-agent conversation -- stateful, reasoning, potentially multi-turn. MCP is about giving an agent a well-typed tool with a known schema. Fraud scoring is a reasoning problem; benefits lookup is a deterministic one."
This slide signals you understand the protocols at the design level, not just the implementation level.

DO NOT SAY: "I could swap these out" as an opening -- it sounds defensive. Present the choice as deliberate.

TRANSITION: "Now, every call in that architecture crosses a compliance boundary. Here is how the design handles that."
-->

---

## Compliance by Design

| Requirement | Mechanism |
|---|---|
| HIPAA Privacy | Einstein Trust Layer -- PHI tokenized in prompts; only `PATIENT_M10047` reaches Vertex |
| HIPAA Security | TLS 1.3 everywhere; Vertex on BAA-covered GCP project; VPC-SC perimeter in prod |
| CMS-0057-F | FHIR-aligned Case model; API-first audit trail; auto-approve only, never auto-deny |
| State prompt-pay | Architecture resolves in &lt;60s -- well inside any state cap |
| Explainability | Every decision includes Vertex rationale + benefits reason codes in the Case record |

<!-- speaker notes
SAY: "I want to flag one design rule that CMS-0057 effectively mandates: the AI never denies. Auto-approval only on low-risk, in-network, clear-benefit cases. Everything else routes to a human reviewer with AI-generated rationale as context. The human makes the adverse determination."
This is the sentence that lands with a CDO/CAIO: it maps to medical director workflow and it's defensible under CMS.
Mention Trust Layer zero-retention: "Salesforce's BAA with Google Vertex includes a zero-retention clause. Prompts are not logged outside the Trust Layer."

DO NOT SAY: "we are fully HIPAA compliant" -- no system is fully compliant at demo stage. Say "designed to satisfy" or "aligned with."

TRANSITION: "I'll show you all of this live now."
-->

---

## Demo

<!-- Live demo -- deck goes fullscreen here -->

**Flow 1** -- Unified case view (D360 federation proof, ~6 min)

**Flow 2** -- MRI pre-auth happy path (end-to-end orchestration, ~12 min)

**Flow 3** -- Denial routing path (human-in-loop, ~2 min)

<!-- speaker notes
SAY: "Three flows. First proves D360 value -- you'll see a ServiceNow case federated into a unified member view with no data copy. Second is the full pre-auth path from chat to SF Case to Vertex to Benefits to decision. Third shows what happens when the system should not auto-approve."
Have all browser tabs pre-positioned. Narrate what you are switching to before you switch.
If something breaks: go to the backup Loom recording on local disk -- do not scramble live.

DO NOT SAY: "hopefully this works" -- say "let me walk you through this" with the assumption it will.

TRANSITION: After demo -- "Let me put that in context of why Salesforce is the right anchor for this architecture."
-->

---

## Why Salesforce Anchors This

- **Data 360 connector breadth** -- 200+ connectors, zero-copy federation; no other platform matches this for payer data sprawl
- **Agentforce + Einstein Trust Layer** -- compliance-by-design; rolling this on any other LLM platform means rebuilding PII masking, audit, and feedback RAG from scratch
- **Embedded Messaging** -- zero-lift deploy on any web property; channel where member service workflows already live

<!-- speaker notes
SAY: "A CDO considering this build has two alternatives: buy a point solution for pre-auth (expensive, narrow, no data layer) or build on a general AI platform (no healthcare compliance primitives). Salesforce gives you the data layer, the compliance layer, and the workflow layer in one. That is the argument."
D360 zero-copy stat is real -- cite it if asked.

DO NOT SAY: "Salesforce is the best platform for everything" -- that reads as a sales pitch. Anchor every bullet to a specific CDO concern.

TRANSITION: "I also want to be transparent about what I cut from this build, and why."
-->

---

## What I Cut and Why

**MuleSoft Agent Fabric -- deliberately left out**

- Correct answer at 10+ agents requiring cross-cloud governance and agent registry
- At 3 agents, Agentforce's built-in planner handles orchestration cleanly
- Adding MAF here would mean operating infrastructure I cannot defend in depth today

> I chose simplicity I could defend over features I could not.

<!-- speaker notes
SAY: "Architects respect candor about scope. I know MAF. I chose not to use it here because the complexity cost outweighed the benefit at this agent count. If Meridian scales to 10+ agents -- appeals agent, claims routing agent, provider credentialing agent -- MAF becomes the right answer and I would introduce it at that point."
This slide preempts the inevitable "why not MAF" probe and turns it into a demonstration of judgment.

DO NOT SAY: "MAF is overkill" -- that sounds dismissive. Say "correct choice at a different scale."

TRANSITION: "On cost and ROI -- let me give you the actual numbers."
-->

---

## Cost and ROI

**Per-transaction costs (at 10k pre-auths/day)**
- Gemini 2.5 tokens: ~$0.02 per pre-auth
- Agentforce: per-conversation licensing (existing contract)
- Cloud Run (2 services): ~$50/month

**Business case**
- $8-12 PMPM savings x 2M lives = **$16-24M/year**
- Human reviewer volume down 60% = staff redeployment to complex cases
- Star Rating improvement on MA plans: material revenue impact

> ROI ratio: approximately 400x at Meridian scale

<!-- speaker notes
SAY: "The $0.02 per pre-auth figure is based on actual Gemini 2.5 Pro pricing at average indication length. Cloud Run scales linearly. The Agentforce cost is already in the Salesforce contract for most payers of this size."
Be ready to defend the $8-12 PMPM figure -- it comes from human reviewer labor cost ($35-45/hr at 15-20 min per auth) plus rework and appeals reduction.

DO NOT SAY: "this is a rough estimate" without following immediately with the basis for the number. Estimates are fine; unexplained estimates are not.

TRANSITION: "What does this look like at 10x or 100x the volume?"
-->

---

## Scale Story

| Dimension | Today (demo) | 10x | 100x |
|---|---|---|---|
| Agentforce / Embedded Messaging | 1 org, shared tenant | Scale-out standard | No change -- Salesforce handles |
| Vertex AI throughput | On-demand | Provisioned throughput tiers | Provisioned + regional failover |
| D360 query performance | DMO queries | Calculated Insights + materialized segments | FHIR-native case model |
| Agent governance | Agentforce planner | Agentforce planner | Introduce MAF for agent registry |
| Benefits Verification | Mock service | Production claims-engine connector | Federated via D360 FHIR connector |

<!-- speaker notes
SAY: "The most interesting scale point is D360. At 10x volume, raw DMO queries start to show latency. The right move is Calculated Insights -- pre-computed segments that the agent queries instead of running joins at runtime. At 100x you probably also want a FHIR-native case model so the data layer speaks the same language as Epic and Cerner directly."
MAF introduction at 100x: "At that scale you likely have 10+ specialized agents. MAF gives you an agent registry, cross-platform A2A routing, and governance observability that Agentforce's planner was not designed for."

DO NOT SAY: "it would just scale automatically" -- that's the shallow answer. Show you have thought through each layer.

TRANSITION: "Finally -- if I owned this roadmap beyond the demo."
-->

---

## What's Next

If I owned this roadmap:

1. **FHIR-native Case model** -- replace SF Case with FHIR Claim/Prior Authorization resources; satisfies CMS-0057-F data flow requirements directly
2. **MAF for cross-platform agent governance** -- agent registry + observability when the fleet grows past 10 agents
3. **Clinical RAG for medical necessity** -- ground Vertex on payer's clinical policy library; removes reliance on free-text indication alone
4. **Appeals agent** -- automated first-level appeal review with same Trust Layer guarantees; closes the pre-auth lifecycle loop

<!-- speaker notes
SAY: "None of these require throwing out what's here. They are additive layers on the same foundation. The FHIR case model is the most important -- it is how you get to native CMS-0057 compliance rather than 'aligned with.' The appeals agent is where I would expect the ROI to compound: appeals are the highest-cost part of the pre-auth workflow."
Show that you have thought past the demo horizon. This is what distinguishes a Principal Architect answer from a senior engineer answer.

DO NOT SAY: anything that implies the current build is incomplete or a prototype -- position it as a deliberate MVP with a clear extension path.

TRANSITION: "I'm ready to go as deep as you want on any of this. What would you like to pull on first?"
-->
