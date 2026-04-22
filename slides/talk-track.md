# Talk-Track Cheat Sheet
## Salesforce Data & AI Principal Architect Panel -- 2026-04-16

---

## Opener (say this verbatim, ~30 seconds)

"I'm Tristan. I've spent the last two years building Data 360 and Agentforce solutions for regulated-industry customers. Today I want to show you something I built for a fictional mid-sized US health payer -- Meridian Health. They cover about 2 million members across commercial group plans and Medicare Advantage. They offer the full range of managed care services -- medical, pharmacy, behavioral health, dental -- and they operate in about a dozen states, primarily in the South and Northeast.

Their CDO told me two things: they need to not fail a CMS audit in 2027, and they've already invested in a fraud detection agent on Google Cloud that they need to keep. That framing drove every decision in this architecture -- how do we put Agentforce at the center while meeting the customer where they already are? I'll show you the live system, walk the design, and then I want your sharpest questions. Can everyone see the shared screen?"

---

## Segment Timings (60 min total)

| Time | Segment | Slides |
|---|---|---|
| 0-5 | Intro + screen confirm | Slides 1-2 |
| 5-10 | What We Heard + Business Problem | Slides 3-4 |
| 10-15 | Current State Architecture | Slide 5 |
| 15-25 | Salesforce Approach + Target State | Slides 6-7 |
| 25-45 | Live Demo (2 flows) | Slide 8 (then switch to live) |
| 45-48 | Demo Summary | Slide 9 |
| 48-53 | Next Steps | Slide 10 |
| 53-55 | Customer Story | Slide 11 |
| 55-60 | Q&A | Open floor |

---

## Pre-demo setup check

- Tab 1: Slides (Google Slides, presenter mode)
- Tab 2: GitHub Pages site (Meridian Health member portal)
- Tab 3: Salesforce Case list view
- Tab 4: GCP Cloud Run console (both services)
- Tab 5: Salesforce Agent Builder (backup if embedded chat fails)

Ping both Cloud Run services 5 minutes before going live. Cold starts are your P99 enemy.

---

## Demo Script

### Flow 1 -- MRI Pre-Auth Happy Path (~12 min)

Narrate: "This is what a Meridian member sees. A standard web page with an embedded Agentforce chat widget -- zero custom UI code."

1. Open GitHub Pages site. Click chat icon.
2. Type: `I need to submit an MRI pre-auth for my knee.`
3. Agent collects info one at a time. Respond to each prompt:
   - Member ID: `M-10047`
   - CPT code: `73721`
   - NPI: `1234567890`
   - Indication: `Torn meniscus confirmed by imaging referral from Dr. Smith. Knee pain for 3 months, physical therapy didn't help.`
4. Agent runs checks. Narrate: "Two tool calls firing in parallel now -- A2A to Meridian's existing Vertex AI fraud agent on Google Cloud, MCP to the Benefits Verification server wrapping Facets."
5. **Switch to GCP Cloud Run logs.** Show both services receiving requests. Narrate: "This is Meridian's existing fraud agent -- Gemini 2.5 on Vertex AI, their team built this internally. We're not ripping it out and replacing it with Einstein. We're connecting to it via A2A protocol so Agentforce can orchestrate it alongside everything else. Benefits Verification is a typed MCP tool wrapping their Facets system -- deterministic response, no LLM involved."
6. **Back to chat.** Expect: Approved with AUTH-XXXX, 80% coverage in-network, $250 copay.
7. **Switch to Salesforce Case tab.** Show: Case with Pre-Auth Request section (Member ID, CPT, NPI, Auth Number) and Fraud Analysis section (risk score, classification, flags) populated.

Narrate: "End to end: under 60 seconds. The before-state was 3-7 days. That is the headline."

---

### Flow 2 -- Escalation Path (~5 min)

Narrate: "Now I'll show you what happens when the system should not auto-approve."

1. New chat session. Type: `I need an MRI pre-auth. Member ID M-10099.`
2. Respond to prompts:
   - CPT: `70553`
   - NPI: `1234567890`
   - Indication: `Severe headaches for 2 weeks.`
3. Expect: Routed to clinical review. Expected response within 72 hours (expedited) per CMS-0057 and NY Insurance Law § 4903.

Narrate: "The AI never denies. The fraud agent returned a risk score of 0.72 with rationale -- 6 prior authorizations reversed in 12 months, three different ordering providers across four facilities in six months, geographic mismatch. That context is attached to the Case for the human reviewer. A medical director makes the adverse determination -- and under CMS-0057, that denial has to include a specific clinical reason. The AI's rationale feeds directly into that required documentation."

4. **Switch to Salesforce Case tab.** Show the Case with Fraud Analysis section -- risk score, classification, flags all populated for the reviewer.

---

## Architecture Deep-Dive (volunteer at ~45 min if time allows)

"Before we go to next steps, let me pull on one thing -- the compliance boundary around the Trust Layer, because I think it is the least obvious part of the design and the most important one for a regulated payer."

Walk: member context JSON -> Trust Layer tokenization -> masked prompt to Vertex -> response -> de-tokenization -> Case update. Point to the audit record. 3-4 minutes.

---

## Anticipated Probes

**1. "Why not MuleSoft Agent Fabric?"**
At 3 agents, Agentforce's planner handles orchestration cleanly -- MAF's governance overhead is not justified. At 10+ agents, with cross-cloud A2A routing and an agent registry requirement, MAF is the right answer. I prefer to defend a smaller architecture than fake depth on a larger one.

**2. "Why A2A to Google Cloud instead of building the fraud model in Einstein?"**
Because Meridian already invested in a fraud detection agent on Vertex AI -- their data science team built it, it's trained on their claims history, and it works. Our job as architects is to meet the customer where they are, not force a rip-and-replace. A2A gives Agentforce a standards-based interface to that agent. If they later want to bring the model into Einstein, the interface stays the same -- swap the endpoint, keep the contract.

**3. "Where does this break?"**
Tail latency. P99 hits 45 seconds when Vertex cold-starts and the clinical indication is long. Production fix: provisioned throughput on Vertex, Cloud Run min-instances=3 on both services. P50 is 12 seconds; that is the number I demoed.

**4. "How much does this cost to run?"**
$0.02 per pre-auth in Gemini tokens, roughly $50 per month Cloud Run at 10k pre-auths per day, plus Agentforce per-conversation licensing. On MRI pre-auths alone -- about 500K per year for a payer this size -- automating 65% at $50-75 manual cost per review saves roughly $2M annually. Apply the same pattern to CT, PET, and surgical pre-auths and that number multiplies.

**5. "The AI denied a claim -- who is liable?"**
The AI never denies. Auto-approval only on low-risk, in-network, clear-benefit cases -- all three conditions must pass. Everything else routes to a human reviewer with AI-generated rationale as context. The human makes the adverse determination. CMS-0057 requires that denials include a specific clinical reason -- the AI's structured rationale feeds directly into that documentation, while keeping the liability-bearing decision with a human reviewer. This matches how medical directors already work.

**6. "What about hallucinations?"**
Two defenses. First, grounding: the Fraud Agent receives member history as structured JSON, not free-text reasoning space -- it cannot invent a claims history that does not exist. Second, determinism: the authorization number comes from the Salesforce Case create action, not from the LLM. The LLM never generates a number it could hallucinate.

---

## Closer (say this verbatim, ~15 seconds)

"I built this in one day on top of standard Salesforce and open protocols. A 90-day pilot could have Meridian processing MRI pre-auths in under a minute -- and the January 2027 deadline means the clock is already ticking. Happy to go deep on any of it."

---

## Emergency Fallbacks

| What breaks | What to do |
|---|---|
| Vertex cold start adds 30s | Narrate it: "This is exactly the P99 scenario I described. In production this is a provisioned throughput configuration." |
| Agentforce misroutes intent | Type the exact phrasing from this script. If it still fails, show the Agent Builder config and narrate the expected flow. |
| Embedded Messaging doesn't load | Use Agent Builder Conversation Preview directly. Narrate: "Different deployment method, same agent." |
| Network drops | Open backup recording from local disk. Don't apologize; say: "I recorded this this morning -- let me show you the same flow." |
