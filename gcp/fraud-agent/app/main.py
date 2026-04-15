"""
Meridian Fraud Risk Agent — FastAPI application.

Endpoints:
  POST /tasks                  — A2A-compatible fraud scoring
  GET  /.well-known/agent.json — A2A AgentCard discovery
  GET  /healthz                — Cloud Run liveness probe
"""

from __future__ import annotations

import logging

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
