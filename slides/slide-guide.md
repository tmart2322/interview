# Slide-by-Slide Guide

Reference: FY27 Data+AI TA Regs Panel Template (Google Slides link from Sandeep's email)

---

## Slide 1 — Title
**Template ref**: Page 1

- Meridian Health: AI-Powered MRI Pre-Authorization
- Salesforce Data 360 + Agentforce | Health & Life Sciences
- Tristan Martin | April 2026

## Slide 2 — Agenda
**Template ref**: Page 2

1. Introductions (3-5 min)
2. What We Heard (5 min)
3. Salesforce Approach to Data & AI (5 min)
4. Solution Architecture (10 min)
5. Live Demo (20 min)
6. Questions / Next Steps (5-10 min)

## Slide 3 — What We Heard
**Template ref**: Page 3

**Project Goals**:
Automate MRI pre-authorization end-to-end, reducing turnaround from 3-7 days to under 60 seconds. Unify member data across clinical, benefits, and case management systems to meet federal prior authorization deadlines by January 2027.

**Current Challenges**:
- Each pre-auth request touches 3 separate systems (EHR, benefits admin, case management) staffed by 3 different teams
- No shared member identity across systems — manual cross-referencing for every request
- Fraud detection runs on Google Cloud but isn't connected to the Salesforce workflow
- Member satisfaction scores declining due to authorization delays
- Current manual process can't scale to meet upcoming federal compliance deadlines

## Slide 4 — Business Problem
**Template ref**: Page 4 (three-column layout)

**The Problem**:
3-7 day pre-auth across 3 siloed systems. Non-compliant with upcoming federal mandates.

**The Customer**:
Meridian Health — 2M-member US health payer (commercial + Medicare Advantage). VP of Utilization Management.

**Success Metrics**:
3-7 days → <60s turnaround. 65% fewer manual reviews. ~$2M/yr savings on MRI pre-auths alone.

## Slide 5 — Current State Architecture
**Template ref**: Page 5

Your "before" diagram (Meridian - Current State.png). Key callouts:
- Service rep manually bridges all systems
- Fraud agent on Google Cloud is siloed — not connected to Salesforce
- No unified member view
- No automation between systems

## Slide 6 — Salesforce Approach
**Template ref**: Page 6

Use the template's D360 + Agentforce diagram. Label:
- D360: pulls clinical history from EHR into a unified member profile
- Agentforce: orchestrates the entire pre-auth workflow in one conversation
- A2A protocol: connects to Meridian's existing Google Cloud fraud agent
- MCP protocol: wraps their Facets benefits system
- Einstein Trust Layer: protects patient data, creates audit trail

## Slide 7 — Future State Architecture
**Template ref**: Page 9

Your architecture diagram (Meridian - Target State v2.png). Label the protocols (A2A, MCP, Embedded Messaging) and the compliance boundary around the Trust Layer.

## Slide 8 — Demo
**Template ref**: Page 7

Section divider. Switch to live demo. See `demo-transcript.md`.

## Slide 9 — Demo Summary
**Template ref**: Page 8

**Capabilities** (left side, with product icons):
- Service Cloud — Agentforce orchestrates 5 actions in a single member conversation
- Data 360 — Unified member profile across EHR, benefits, and case data
- Health Cloud — Pre-auth Case with fraud analysis and clinical context
- Google Cloud — Existing Vertex AI fraud agent connected via A2A protocol

**Benefits** (right side, title + one-liner each):
- **Faster Decisions** | Pre-auth in under 60 seconds vs. 3-7 days today
- **Fewer Manual Reviews** | 65% of low-risk cases auto-approved, freeing clinical staff
- **Compliance Ready** | Full audit trail meeting federal prior auth timelines

## Slide 10 — Next Steps
**Template ref**: Page 10

1. **Confirm the Use Case**
   Align internally on MRI pre-auth as the starting point. We need that decision to size the right Agentforce and Data 360 package.

2. **Send Us Your Volumes**
   Annual pre-auth requests and number of UM staff involved. We'll come back with a sized licensing proposal and ROI model specific to Meridian.

3. **Partner Introductions**
   We'll introduce you to certified Salesforce partners with payer experience in Health Cloud, Agentforce, and Data 360 deployments.

4. **Lock In the Timeline**
   January 2027 compliance deadline is 9 months out. A 90-day pilot means we need to kick off by end of Q2 to leave room for production rollout.

## Slide 11 — Customer Story
**Template ref**: Page 12 (use the layout, replace the content)

**Problem**:
Meridian processed 500K+ MRI pre-auth requests annually across three disconnected systems — Epic, Facets, and a manual fraud review — resulting in 3-7 day turnaround and growing non-compliance risk with federal prior authorization mandates.

**Solution**:
Data 360 unifies clinical encounter data from Epic with benefits and case history into a single member profile. Agentforce orchestrates the pre-auth workflow, connecting to Meridian's existing Vertex AI fraud agent via A2A and Facets via MCP for automated decisioning with human escalation.

**Outcome**:
Pre-auth turnaround reduced from 3-7 days to under 60 seconds for low-risk cases. Manual reviewer workload cut by 65%. Full compliance with federal timelines ahead of January 2027.

**Products used**: Data 360, Agentforce, Service Cloud, Health Cloud

**Data activated**: Epic EHR, Facets (Benefits)
