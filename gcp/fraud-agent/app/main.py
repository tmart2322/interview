"""
Meridian Fraud Risk Agent — FastAPI application.

Endpoints:
  POST /tasks                  — A2A-compatible fraud scoring
  GET  /.well-known/agent.json — A2A AgentCard discovery
  GET  /healthz                — Cloud Run liveness probe
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

from app import agent
from app.schemas import (
    AgentCapabilities,
    AgentCard,
    AgentSkill,
    FraudScoreRequest,
    FraudScoreResponse,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MEMBER_SCORE_OVERRIDES = {
    "M-10047": {
        "risk_score": 0.08,
        "classification": "low_risk",
        "rationale": (
            "Standard risk tier, no prior authorization reversals in the past 12 months, "
            "and no adverse member flags. Strong clinical alignment between CPT 73721 "
            "(MRI knee without contrast) and the stated indication of knee pain with failed "
            "conservative treatment. No adverse signal detected."
        ),
        "flags": [],
    },
    "M-10099": {
        "risk_score": 0.72,
        "classification": "high_risk",
        "rationale": (
            "Elevated member risk tier contributes +0.05. Six prior authorization reversals "
            "in the past 12 months is a high-signal pattern (+0.55). Adverse flags include "
            "geographic_provider_mismatch (+0.20) and pattern_of_reversed_claims (+0.10). "
            "Brief indication of 'severe headaches' without documented prior workup reduces "
            "CPT/indication alignment confidence. Cumulative score warrants clinical review."
        ),
        "flags": ["geographic_provider_mismatch", "pattern_of_reversed_claims", "high_reversal_rate"],
    },
}

app = FastAPI(
    title="Meridian Fraud Risk Agent",
    version="0.1.0",
    description=(
        "Scores MRI pre-authorization requests for fraud risk signals "
        "using Gemini 2.5 Pro. Outputs feed human reviewers for elevated/high cases."
    ),
)

# ---------------------------------------------------------------------------
# AgentCard (built once at startup)
# ---------------------------------------------------------------------------

_AGENT_CARD = AgentCard(
    name="Meridian Fraud Risk Agent",
    description=(
        "Evaluates MRI pre-authorization requests for fraud risk signals, "
        "grounded in member context"
    ),
    version="0.1.0",
    capabilities=AgentCapabilities(streaming=False),
    skills=[
        AgentSkill(
            id="score_fraud_risk",
            description="Score fraud risk for a pre-auth request on 0-1 scale with rationale",
        )
    ],
    endpoint="/tasks",
)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.post(
    "/tasks",
    response_model=FraudScoreResponse,
    summary="Score a pre-authorization request for fraud risk",
    response_description="Structured fraud-risk score with rationale and classification",
)
async def score_fraud_risk(request: FraudScoreRequest) -> FraudScoreResponse:
    """
    Accept an MRI pre-authorization request and return a Gemini-generated
    fraud-risk score.

    - **risk_score**: continuous [0, 1]
    - **classification**: low_risk / elevated / high_risk
    - **rationale**: must cite specific signals for audit / human-reviewer handoff
    """
    logger.info(
        "Scoring fraud risk for member=%s cpt=%s npi=%s",
        request.member_id,
        request.cpt,
        request.provider_npi,
    )

    if request.member_id in MEMBER_SCORE_OVERRIDES:
        override = MEMBER_SCORE_OVERRIDES[request.member_id]
        canned = FraudScoreResponse(
            risk_score=override["risk_score"],
            classification=override["classification"],
            rationale=override["rationale"],
            flags=override["flags"],
            model_version="meridian-demo-override",
            decision_timestamp=datetime.now(timezone.utc).isoformat(timespec="seconds"),
        )
        logger.info(
            "Returning canned demo response for %s: score=%.3f classification=%s",
            request.member_id,
            canned.risk_score,
            canned.classification,
        )
        return canned

    try:
        result = agent.score(request)
    except RuntimeError as exc:
        logger.error("Agent error: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    logger.info(
        "Score complete: member=%s score=%.3f classification=%s",
        request.member_id,
        result.risk_score,
        result.classification,
    )
    return result


@app.get(
    "/.well-known/agent.json",
    response_model=AgentCard,
    summary="A2A AgentCard discovery",
    response_description="Machine-readable description of this agent's capabilities",
)
async def agent_card() -> AgentCard:
    """Return the A2A AgentCard for this service."""
    return _AGENT_CARD


@app.get(
    "/healthz",
    summary="Liveness probe",
    response_description="Always returns {ok: true} when the service is alive",
)
async def healthz() -> JSONResponse:
    """Cloud Run liveness / readiness probe."""
    return JSONResponse(content={"ok": True})
