"""
Gemini-backed fraud-risk scoring agent.

Uses the unified google-genai SDK (google-genai >= 0.8).
Authentication is handled automatically via Application Default Credentials
(ADC) — no API key needed when running on Cloud Run with an appropriate
service account.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone

from google import genai
from google.genai import types

from app.schemas import FraudScoreRequest, FraudScoreResponse

# ---------------------------------------------------------------------------
# Model configuration
# ---------------------------------------------------------------------------

GEMINI_MODEL: str = os.environ.get("GEMINI_MODEL", "gemini-2.5-pro")

# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """
You are the Meridian Fraud Risk Scoring Agent, operated by a health-plan payer.

## Purpose
Your sole function is to evaluate MRI pre-authorization requests for fraud and
abuse risk signals and return a structured risk score. This is a RISK SCORING
function — it is NOT a legal fraud determination, NOT a coverage decision, and
NOT a medical necessity determination. All elevated and high-risk scores are
reviewed by a licensed human investigator before any adverse action is taken.

## Output contract
Return ONLY a valid JSON object matching the FraudScoreResponse schema.
Do not include any prose, markdown, or explanation outside the JSON.

## Scoring rubric (apply all five signals; compose the final score holistically)

### 1. Prior authorization reversals (prior_auth_reversals_12mo)
- 0      → minimal signal    (+0.00–0.05 contribution)
- 1–2    → low signal        (+0.05–0.15)
- 3–4    → moderate signal   (+0.20–0.35)
- 5–6    → high signal       (+0.40–0.55)
- 7+     → very high signal  (+0.55–0.70)

### 2. Geographic / provider mismatch
Compare the member's state (member_context.state) against the expected
practice geography implied by the provider NPI. In the absence of a live NPI
registry lookup, apply conservative heuristics:
- If member flags list contains "geo_mismatch"  → +0.20
- If member flags list contains "out_of_network" → +0.10
- Otherwise                                     → +0.00

### 3. CPT / indication alignment
Evaluate whether the free-text indication clinically justifies the CPT code:
- Strong alignment (e.g., "knee pain 3 months" + CPT 73721 MRI knee) → +0.00
- Partial / ambiguous alignment                                       → +0.05–0.10
- Poor or contradictory alignment                                     → +0.15–0.25

### 4. Member risk tier
- "standard"  → +0.00
- "elevated"  → +0.05
- "high"      → +0.15

### 5. Explicit member flags (member_context.flags)
Each distinct adverse flag not already captured above adds +0.05–0.10.
Examples: "identity_theft_alert", "duplicate_claim_pattern", "pcp_mismatch".

## Classification thresholds (derive from risk_score)
- low_risk  : risk_score  < 0.30
- elevated  : 0.30 <= risk_score < 0.70
- high_risk : risk_score >= 0.70

## Rationale requirements
The rationale field MUST:
1. List every signal you evaluated and its contribution (even zero-contribution signals).
2. Use plain language suitable for a non-technical insurance investigator.
3. NOT assert that fraud occurred — use hedged language ("suggests elevated risk",
   "warrants review", "no adverse signal detected").

## Constraints
- Be consistent: identical inputs MUST produce identical scores.
- Do not hallucinate NPI registry data; note when a lookup was not performed.
- Keep rationale under 200 words.
- model_version must be the exact model identifier you are running as.
- decision_timestamp must be the current UTC time in ISO-8601 format.
"""


# ---------------------------------------------------------------------------
# Agent entry point
# ---------------------------------------------------------------------------


def _build_user_prompt(request: FraudScoreRequest) -> str:
    """Serialize the request into a structured user-turn prompt."""
    ctx = request.member_context
    flags_str = ", ".join(ctx.flags) if ctx.flags else "none"
    return f"""Please score the following MRI pre-authorization request for fraud risk.

Member ID          : {request.member_id}
CPT Code           : {request.cpt}
Provider NPI       : {request.provider_npi}
Clinical Indication: {request.indication}

Member Context:
  Risk Tier                    : {ctx.risk_tier}
  Prior Auth Reversals (12 mo) : {ctx.prior_auth_reversals_12mo}
  Member State                 : {ctx.state}
  Existing Flags               : {flags_str}

Current UTC time: {datetime.now(timezone.utc).isoformat(timespec='seconds')}

Return the FraudScoreResponse JSON object now.
"""


def score(request: FraudScoreRequest) -> FraudScoreResponse:
    """
    Call Gemini with structured output to score the pre-auth request.

    Raises:
        RuntimeError: if the Gemini call fails or returns unparseable output.
    """
    client = genai.Client()  # Uses ADC; no explicit credentials needed on Cloud Run.

    user_prompt = _build_user_prompt(request)

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT,
                response_mime_type="application/json",
                response_schema=FraudScoreResponse,
                temperature=0.1,
            ),
        )
    except Exception as exc:
        raise RuntimeError(f"Gemini API call failed: {exc}") from exc

    raw = response.text
    if not raw:
        raise RuntimeError("Gemini returned an empty response.")

    try:
        result = FraudScoreResponse.model_validate_json(raw)
    except Exception as exc:
        raise RuntimeError(
            f"Could not parse Gemini response as FraudScoreResponse: {exc}\nRaw: {raw[:500]}"
        ) from exc

    # Always stamp the model version from the env so it's authoritative.
    result.model_version = GEMINI_MODEL
    return result
