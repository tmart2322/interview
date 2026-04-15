"""
Pydantic models for the Meridian Fraud Risk Agent.

FraudScoreResponse is also used as the response_schema passed to Gemini,
so Pydantic v2 field definitions here drive the structured output contract.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Literal

from pydantic import BaseModel, Field


class MemberContext(BaseModel):
    """Contextual signals about the requesting member."""

    risk_tier: str = Field(
        description="Payer-assigned risk tier for this member (e.g. 'standard', 'elevated', 'high')."
    )
    prior_auth_reversals_12mo: int = Field(
        ge=0,
        description="Number of prior-authorization reversals in the past 12 months.",
    )
    state: str = Field(
        description="Two-letter US state code for the member's primary residence."
    )
    flags: List[str] = Field(
        default_factory=list,
        description="Explicit risk flags already recorded against this member.",
    )


class FraudScoreRequest(BaseModel):
    """Payload for a single MRI pre-authorization fraud-risk scoring request."""

    member_id: str = Field(description="Unique member identifier.")
    cpt: str = Field(description="CPT procedure code being requested.")
    provider_npi: str = Field(description="10-digit NPI of the ordering provider.")
    indication: str = Field(
        description="Free-text clinical indication supplied by the ordering provider."
    )
    member_context: MemberContext


class FraudScoreResponse(BaseModel):
    """
    Structured fraud-risk score returned by the agent.

    This model is also passed directly as response_schema to the Gemini API
    to enforce deterministic JSON output.
    """

    risk_score: float = Field(
        ge=0.0,
        le=1.0,
        description="Continuous fraud-risk score between 0 (no risk) and 1 (highest risk).",
    )
    classification: Literal["low_risk", "elevated", "high_risk"] = Field(
        description=(
            "Categorical classification derived from risk_score: "
            "low_risk (<0.30), elevated (0.30–0.69), high_risk (>=0.70)."
        )
    )
    rationale: str = Field(
        description=(
            "Human-readable explanation citing the specific signals that drove the score. "
            "Required for audit and human-reviewer handoff."
        )
    )
    flags: List[str] = Field(
        default_factory=list,
        description="Zero or more short labels for signals that contributed to the score.",
    )
    model_version: str = Field(
        description="Gemini model identifier used to produce this score."
    )
    decision_timestamp: str = Field(
        description="ISO-8601 UTC timestamp of when the score was produced."
    )


# ---------------------------------------------------------------------------
# A2A AgentCard schema
# ---------------------------------------------------------------------------


class AgentSkill(BaseModel):
    id: str
    description: str


class AgentCapabilities(BaseModel):
    streaming: bool = False


class AgentCard(BaseModel):
    name: str
    description: str
    version: str
    capabilities: AgentCapabilities
    skills: List[AgentSkill]
    endpoint: str
