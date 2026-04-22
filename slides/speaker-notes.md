# Speaker Notes (copy into Google Slides speaker notes per slide)

---

## Slide 1 — Title

"I'm Tristan. I've spent the last two years building Data 360 and Agentforce solutions for regulated-industry customers. Today I want to show you something I built for a fictional mid-sized US health payer — Meridian Health. They cover about 2 million members across commercial group plans and Medicare Advantage. They offer the full range of managed care services — medical, pharmacy, behavioral health, dental — and they operate in about a dozen states, primarily in the South and Northeast.

Their CDO told me two things: they need to not fail a CMS audit in 2027, and they've already invested in a fraud detection agent on Google Cloud that they need to keep. That framing drove every decision in this architecture — how do we put Agentforce at the center while meeting the customer where they already are? I'll show you the live system, walk the design, and then I want your sharpest questions."

---

## Slide 2 — Agenda

"Quick roadmap for the hour. I'll set up the business problem first — who Meridian is and why this matters now. Then I'll walk the architecture end-to-end before we go live. The demo is the centerpiece — about 20 minutes of live system. I want plenty of time for your questions at the end."

---

## Slide 3 — What We Heard

"MRI pre-authorization at a mid-sized payer today takes 3 to 7 days. That's the industry average from CMS and AHIP data. Each request touches three separate systems — benefits verification, fraud detection, and case management — staffed by three different teams with manual handoffs between them.

The regulatory environment is tightening. **CMS-0057** — the Interoperability and Prior Authorization Final Rule, finalized by CMS in January 2024 — applies to Medicare Advantage plans, Medicaid Managed Care, and Qualified Health Plans on the federal exchange. Meridian hits three of those. The rule rolls out in stages: FHIR-based Patient Access, Provider Access, and Payer-to-Payer APIs by January 2026, and then the hard one — starting January 2027, prior authorization decisions must be returned within **72 hours for expedited requests and 7 calendar days for standard requests**. Denials have to include a specific reason, and payers have to publicly report their prior auth metrics.

Several states already have prior auth turnaround laws in the same range — New York, Texas, California, Washington — so for a multi-state payer like Meridian, this is already a patchwork they're failing to meet. CMS-0057 just puts a federal floor under it.

And the stakes aren't hypothetical. CMS runs Program Audits on Medicare Advantage plans every 1 to 3 years, and prior authorization falls under what they call ODAG — Organizational Determinations, Appeals, and Grievances. Audit failures mean corrective action plans, civil money penalties, and Star Rating hits that directly affect reimbursement.

There's one more wrinkle. Meridian's data science team has already built a fraud detection agent on Google Cloud — Vertex AI, Gemini 2.5 Pro, trained on their claims history. It works. They're not going to throw it away, and we shouldn't ask them to. So the architecture question becomes: how do we put Agentforce at the center of the workflow while preserving that existing investment?

Bottom line: this isn't a nice-to-have automation project. It's a compliance and revenue problem with a January 2027 deadline."

---

## Slide 4 — Business Problem

"Let me make this concrete. The problem is that manual pre-auth is too slow, too fragmented, and non-compliant with where regulation is heading. Each request crosses three system boundaries with no shared member identity.

The persona who owns this is the VP of Utilization Management. They report to the CMO. They're accountable for authorization turnaround times, denial rates, and CMS compliance.

The metrics that matter: we're targeting auto-approval in under 60 seconds for clean cases — that's the 70-80% that are low-risk, in-network, clearly eligible. That cuts manual reviewer workload by 65%. On MRI pre-auths alone — about 500,000 a year for a payer this size — that's roughly $2 million in annual savings. Apply the same pattern across all procedure types and it scales from there."

---

## Slide 5 — Current State Architecture

"This is the before state. Member portal on the left — no self-service pre-auth capability today. Chat goes to a service rep who manually bridges everything.

The rep looks up benefits eligibility in Facets. Checks the fraud system separately. Pulls clinical history from Epic. Each step is a separate system, separate login, separate data silo. And the fraud agent on Google Cloud? It works — but it's completely disconnected from the Salesforce workflow. The rep can't trigger it from a Case.

There's no shared member identity across these systems. No audit trail that a CMS examiner could query. And the average cycle time — 3 to 7 days — is already non-compliant in four states."

---

## Slide 6 — Salesforce Approach

"Here's the Salesforce lens on this problem. Data 360 sits at the center as the unified data layer. It pulls clinical encounter data from Epic — member demographics, care history, and Salesforce Cases into a single member profile. No ETL pipeline, no data duplication, no HIPAA residency risk.

Agentforce sits on top as the orchestration layer. It's a Service Agent that runs the entire pre-auth workflow in one conversation: collects member information, calls the fraud agent via A2A, verifies benefits via MCP, creates and updates the Case.

Why Salesforce and not a custom agent framework? Three reasons. First, D360 gives the agent trusted context — the clinical history that grounds the decision. Second, the Einstein Trust Layer provides the compliance guardrails: PII masking, prompt injection prevention, and an immutable audit trail. Third — and this is the one that matters for Meridian specifically — Agentforce supports open protocols. A2A lets us connect to their existing Vertex AI fraud agent without ripping it out. MCP lets us wrap their Facets system with a typed interface. We're not asking them to re-platform anything. We're putting Agentforce at the center and connecting to what they already have."

---

## Slide 7 — Future State Architecture

"This is the architecture I built. Let me walk it left to right.

The member interacts through the Meridian Health portal with an embedded Agentforce chat widget. The agent has five tools. It calls Check Eligibility and Score Fraud Risk in parallel — eligibility goes to a Benefits MCP server wrapping Facets, deterministic, no LLM involved. The fraud score goes to Meridian's existing Vertex AI agent via A2A — this is the model their data science team already built. We're not replacing it. We're connecting to it through an open standard.

Then it gets coverage details, creates a Case in Salesforce with all the context attached, and makes the decision: auto-approve if risk score is under 0.3, eligible, and in-network. Everything else routes to a human UM reviewer with the AI's rationale attached.

Two things on compliance. The Einstein Trust Layer wraps every LLM call — PII is tokenized before it leaves Salesforce. And the AI never denies. It approves or escalates. A human medical director makes any adverse determination. That's how CMS-0057 requires it to work."

---

## Slide 8 — Demo

"Let me show you this live. I have the member portal open — this is what a Meridian Health member sees. I'll walk two scenarios: a clean approval and a flagged escalation."

(Switch to live demo — follow demo-transcript.md)

---

## Slide 9 — Demo Summary

"To recap what you just saw. Four products working together: Agentforce orchestrating the workflow, Data 360 unifying clinical data from the EHR, Service Cloud managing the Case with full fraud context, and Meridian's existing Vertex AI fraud agent on Google Cloud connected via A2A. The agent made five tool calls — two external, three internal — in under 60 seconds. The before-state was 3-7 days. And the escalation path showed that the system knows when not to auto-approve — the AI provides rationale, a human makes the call."

---

## Slide 10 — Next Steps

"Four things to move this forward.

First, confirm the use case. We've shown MRI pre-auth today — if that's the right starting point, we need that decision to size the right Agentforce and Data 360 package.

Second, send us your volumes. Annual pre-auth requests and number of UM staff involved. We'll come back with a sized licensing proposal and ROI model specific to Meridian.

Third, partner introductions. We'll connect you with certified Salesforce partners who have payer experience with Health Cloud, Agentforce, and Data 360.

Fourth, lock in the timeline. The January 2027 compliance deadline is 9 months out. A 90-day pilot means we need to kick off by end of Q2 to leave room for production rollout."

---

## Slide 11 — Customer Story

"This slide tells the Meridian story end-to-end. 500,000 MRI pre-auths a year across three disconnected systems. Data 360 unified the clinical and benefits data. Agentforce orchestrated the workflow and connected to their existing Google Cloud fraud agent via A2A. Result: under 60 seconds for low-risk cases, 65% fewer manual reviews, and full compliance ahead of January 2027.

As their CDO put it: 'We needed our clinical data and our AI investments to work together, not in silos. Data 360 and Agentforce gave us a single member view and cut our pre-auth turnaround from days to seconds.'"
