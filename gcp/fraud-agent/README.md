# Meridian Fraud Risk Agent

FastAPI service that scores MRI pre-authorization requests for fraud risk using
Gemini 2.5 Pro. Deploys to Google Cloud Run. Callable from Salesforce as an
External Service via the bundled `openapi.yaml`.

---

## Quick Start

### 1. Prerequisites

| Requirement | Notes |
|---|---|
| `gcloud` CLI | [Install guide](https://cloud.google.com/sdk/docs/install) |
| GCP project | With Cloud Run, Cloud Build, Artifact Registry APIs enabled |
| Vertex AI / Gemini API | Enabled in the project; service account must have `roles/aiplatform.user` |
| ADC configured | `gcloud auth application-default login` |

### 2. Set environment variable

```bash
export GCP_PROJECT=your-gcp-project-id
```

### 3. Deploy

```bash
cd /path/to/gcp/fraud-agent
bash deploy.sh
```

The script prints the Cloud Run service URL on completion. Copy it — you'll
need it for the Salesforce External Service registration.

### Exact deploy command (if you prefer to run it manually)

```bash
# Step 1 — build & push image
gcloud builds submit \
  --tag "gcr.io/${GCP_PROJECT}/fraud-agent" \
  --project "${GCP_PROJECT}" \
  .

# Step 2 — deploy
gcloud run deploy fraud-agent \
  --image "gcr.io/${GCP_PROJECT}/fraud-agent" \
  --region us-central1 \
  --platform managed \
  --min-instances 1 \
  --max-instances 3 \
  --memory 1Gi \
  --timeout 120 \
  --set-env-vars "GEMINI_MODEL=gemini-2.5-pro" \
  --project "${GCP_PROJECT}" \
  --allow-unauthenticated
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GEMINI_MODEL` | `gemini-2.5-pro` | Gemini model identifier |
| `PORT` | `8080` | Injected by Cloud Run; used by gunicorn |

No API keys are hardcoded. Authentication to the Gemini API uses Application
Default Credentials (ADC), which are automatically available on Cloud Run via
the attached service account.

---

## curl Examples

Replace `$SERVICE_URL` with the URL printed by `deploy.sh`.

### M-10047 — Expected: `low_risk`

Standard member, no prior reversals, indication matches CPT (73721 = MRI knee).

```bash
curl -s -X POST "${SERVICE_URL}/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "member_id": "M-10047",
    "cpt": "73721",
    "provider_npi": "1234567890",
    "indication": "knee pain 3 months, MRI knee ordered",
    "member_context": {
      "risk_tier": "standard",
      "prior_auth_reversals_12mo": 0,
      "state": "TX",
      "flags": []
    }
  }' | jq .
```

Expected response shape:
```json
{
  "risk_score": 0.05,
  "classification": "low_risk",
  "rationale": "No prior reversals in 12 months; indication matches CPT 73721; provider in expected geography; no adverse flags.",
  "flags": [],
  "model_version": "gemini-2.5-pro",
  "decision_timestamp": "2026-04-15T20:00:00Z"
}
```

---

### M-10099 — Expected: `high_risk`

High-risk tier, 6 prior reversals, geographic mismatch flag, duplicate claim
pattern flag, weak indication for MRI.

```bash
curl -s -X POST "${SERVICE_URL}/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "member_id": "M-10099",
    "cpt": "73721",
    "provider_npi": "9876543210",
    "indication": "routine screening",
    "member_context": {
      "risk_tier": "high",
      "prior_auth_reversals_12mo": 6,
      "state": "TX",
      "flags": ["geo_mismatch", "duplicate_claim_pattern"]
    }
  }' | jq .
```

Expected response shape:
```json
{
  "risk_score": 0.87,
  "classification": "high_risk",
  "rationale": "Six prior authorization reversals in 12 months (high signal); geo_mismatch flag present; duplicate_claim_pattern flag present; indication 'routine screening' weakly supports MRI knee (CPT 73721); member risk tier is high. Multiple compounding adverse signals warrant immediate human review.",
  "flags": ["high_reversal_rate", "geo_mismatch", "duplicate_claim_pattern", "weak_indication"],
  "model_version": "gemini-2.5-pro",
  "decision_timestamp": "2026-04-15T20:00:00Z"
}
```

---

### Other endpoints

```bash
# AgentCard
curl -s "${SERVICE_URL}/.well-known/agent.json" | jq .

# Health probe
curl -s "${SERVICE_URL}/healthz"
```

---

## Salesforce External Service Registration

1. In Salesforce Setup, go to **Integrations > External Services**.
2. Click **New External Service**.
3. Choose **From API Specification**.
4. Upload `openapi.yaml` from this directory (or paste its contents).
5. Set the **Base URL** to the Cloud Run service URL.
6. No Named Credential is required for this demo (`--allow-unauthenticated`).
7. After registration, the `scoreFraudRisk` operation is available as an
   **Invocable Action** in Flow Builder and Apex.

---

## Production Gaps

The following shortcuts are acceptable for a demo but MUST be addressed before
handling real member PHI or making any coverage/adverse action decisions:

| Gap | Remediation |
|---|---|
| `--allow-unauthenticated` | Remove flag; add Cloud Run IAM invoker binding; use Salesforce Named Credentials with OAuth 2.0 client credentials |
| No HIPAA BAA / data governance | Ensure GCP project is in a HIPAA-eligible configuration; sign BAA with Google |
| Gemini outputs are non-deterministic | Pin to a specific model version hash; add golden-set regression tests; gate deployments on score-distribution drift |
| No audit log | Emit structured logs per request to Cloud Logging; export to BigQuery for compliance audit trail |
| No rate limiting | Add Cloud Armor or API Gateway with quota policies per member/NPI |
| Secrets in env vars | Move `GEMINI_MODEL` and any future secrets to Secret Manager; reference via Cloud Run secret mounts |
| Single-region deployment | Add a second region + Cloud Load Balancing for HA |
| No PHI tokenization | Member IDs and indications should be tokenized before leaving the payer's trust boundary |
| No model explainability v2 | Integrate SHAP or Vertex Explainable AI for auditable feature-level attribution |
| NPI validation is heuristic-only | Integrate live NPI Registry API for authoritative provider geography validation |
