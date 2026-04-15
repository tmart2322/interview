# Salesforce Data & AI Architect — Final Panel Interview

## The Role
- **Title**: Principal AI Architect (pre-sales), Data 360 & Agentforce Practice, Regulated Industries
- **Employer**: Salesforce
- **Recruiter**: Sandeep Aulakh (Director, Global Technical Architects — Data + AI)
- **Trail guide**: Greg (30-min clarifying session available; will NOT help build the demo)

## The Interview
- **Date**: 2026-04-16 (ONE DAY from 2026-04-15 — prep started late, scope aggressively)
- **Format**: 60-minute live panel, screen-shared
- **Audience**: 2–4 Salesforce panelists — Senior/Distinguished Architects, a Sales or Technical leader, a Specialist. They have seen every vendor demo. Present as if to a **Chief Data Officer / Chief AI Officer** at a prospective customer.
- **Structure**:
  1. Intro & Setup (brief self-intro, confirm screen share)
  2. Demo & Walkthrough (live working build + architecture narration)
  3. Architecture Deep-Dive (panelists probe trade-offs, scalability, security, D360/Agentforce depth)
  4. Q&A & Hypotheticals (e.g., "what if data volume is 100x?", "where does this break under a GDPR audit?")

## The Take-Home Build (the centerpiece)
Tristan must demo a **working data pipeline and/or AI-powered application**. Slides alone are disqualifying. Live demo strongly preferred; screen recording as backup.

### Non-negotiable requirements
1. **Platform**: Salesforce **Data 360** and/or **Agentforce** must be a meaningful component — NOT a default/out-of-the-box config. Must show integration depth (e.g., Snowflake → zero-copy → Data 360; Agentforce API exposed to an external app; external data sources or custom tools wired into Agentforce).
2. **Business use case**: Grounded in a real **Financial Services** or **Health & Life Sciences** problem with regulatory complexity. Must be specific — name the problem, the persona, the metric, the mechanism. NOT "improve customer experience."
3. **Technical depth**: Real engineering decisions (data modeling, pipeline design, AI/ML architecture, infra, security). Tristan must understand every line, even if AI-generated.
4. **Regulatory awareness**: Compliance must be woven into the architecture, not bolted on. Know the frameworks (HIPAA/HITECH, FDA 21 CFR Part 11, SEC/FINRA Reg BI, GLBA, SOX, NYDFS, state insurance regs).
5. **CDO/CAIO lens**: Every technology choice must map to a business reason. Quantify value. Tie cost to ROI.

### Illustrative FINS/HLS use cases from the briefing
- **FINS Wealth**: AI-driven portfolio risk monitoring + suitability-aware rebalancing (Reg BI)
- **FINS Insurance**: Intelligent claims triage + fraud detection (state insurance regs, bias monitoring)
- **HLS Provider**: AI-assisted care coordination / readmission risk (HIPAA, FHIR, clinician-in-the-loop)
- **HLS MedTech**: Predictive device maintenance + field service (21 CFR Part 11, UDI traceability)

### External tech is encouraged
Snowflake, Databricks, dbt, Fivetran, Kafka, AWS/GCP/Azure, Pinecone/Weaviate/pgvector, LangChain/LlamaIndex, Claude/GPT/Gemini APIs. AI coding assistants (Claude Code, Cursor, Copilot) are explicitly welcomed — Tristan must still understand and defend every output.

## What the Panel Must Cover (rubric-aligned)
- Business context (open with the problem, not tech)
- Architecture diagram (end-to-end: ingestion → transform → storage → AI layer → activation)
- **Why Salesforce D360/Agentforce is the right anchor** vs. alternatives (will be asked)
- Data model & identity resolution
- Tech decisions (for every component: why this, why not X)
- AI/LLM design (model choice, prompts, RAG strategy, guardrails, eval)
- Business value — quantified KPI impact, cost to build/operate, ROI
- Trade-offs (compute cost, latency, scale limits, build-vs-buy)
- Security & trust (access controls, PII/PHI, prompt injection, trust boundaries)
- Scale story (what changes at 10x / 100x?)

## Compliance Deep-Dive (probed as a standalone dimension)
- Data access controls (RBAC/ABAC/field-level)
- PII/PHI handling (de-identification, encryption, minimum-necessary)
- Audit trail (immutable, queryable — regulators expect this)
- AI trust boundaries (prompt injection, output validation, hallucination detection, human-in-loop)
- Data residency / sovereignty (GDPR, FINRA books-and-records, cross-border)
- Name the specific regulations and how the architecture satisfies them

## Evaluation Rubric (1–5 per dimension)
1. Technical Depth & Correctness
2. Architecture Quality & Judgment
3. Data & AI Technology Depth
4. Communication & Executive Presence
5. Business Value & Commercial Acumen
6. Regulatory & Compliance Awareness

## What Panelists Will REJECT (from the brief, verbatim intent)
- Default product demos (clicking OOB features)
- Vague use cases ("improve CX with AI")
- Polished UI with shallow architecture
- Slides as substitute for a working build
- Technology for its own sake
- "The LLM wrote it" as a defense
- Compliance slapped on at the end

## Time Constraint (CRITICAL)
Interview is tomorrow. Scope must be ruthlessly small but defensible. Prioritize:
1. **One** specific FINS or HLS use case with a quantified business metric
2. **One** credible D360 or Agentforce integration that is clearly non-default
3. **One** end-to-end architecture diagram
4. A **live demo path** that works 100% of the time (rehearsed, with a recording backup)
5. Compliance woven into the narrative from slide 1

Over-scoping and failing to demo beats under-scoping and nailing it. A rough-but-deep build > polished-but-shallow.

## Working Directory
`/Users/tristan/projects/interview` — empty SF DX project scaffold (API v66.0, `force-app/`, no namespace). Expect to add metadata, scripts, external integration code, and demo docs here.

## Next Decisions (awaiting Tristan)
- Which use case (FINS Wealth / FINS Insurance / HLS Provider / HLS MedTech / custom)?
- Which platform anchor (Data 360 zero-copy? Agentforce external tool-calling? Both?)
- What external stack (if any) does he already have accounts for?
- What's the demo format (live org + script, recorded backup, external app calling Agentforce)?
