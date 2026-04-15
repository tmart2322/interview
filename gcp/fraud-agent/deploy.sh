#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy.sh — Build and deploy the Meridian Fraud Risk Agent to Cloud Run
#
# Prerequisites:
#   1. gcloud CLI installed and authenticated  (`gcloud auth login`)
#   2. Application Default Credentials set up  (`gcloud auth application-default login`)
#   3. $GCP_PROJECT environment variable pointing to your GCP project ID
#   4. Cloud Run, Cloud Build, and Artifact Registry APIs enabled in the project
#
# Usage:
#   export GCP_PROJECT=my-gcp-project-id
#   bash deploy.sh
# ---------------------------------------------------------------------------

set -euo pipefail

# ---------------------------------------------------------------------------
# Validate required environment variable
# ---------------------------------------------------------------------------
if [[ -z "${GCP_PROJECT:-}" ]]; then
  echo "ERROR: GCP_PROJECT environment variable is not set." >&2
  echo "       Run: export GCP_PROJECT=<your-gcp-project-id>" >&2
  exit 1
fi

REGION="us-central1"
SERVICE_NAME="fraud-agent"
IMAGE="gcr.io/${GCP_PROJECT}/${SERVICE_NAME}"

echo "==> Project  : ${GCP_PROJECT}"
echo "==> Region   : ${REGION}"
echo "==> Service  : ${SERVICE_NAME}"
echo "==> Image    : ${IMAGE}"
echo ""

# ---------------------------------------------------------------------------
# Step 1 — Build and push the container image via Cloud Build
# Cloud Build runs in GCP so no local Docker daemon is required.
# ---------------------------------------------------------------------------
echo "==> Building and pushing container image..."
gcloud builds submit \
  --tag "${IMAGE}" \
  --project "${GCP_PROJECT}" \
  .

# ---------------------------------------------------------------------------
# Step 2 — Deploy to Cloud Run
# ---------------------------------------------------------------------------
echo "==> Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --min-instances 1 \
  --max-instances 3 \
  --memory 1Gi \
  --timeout 120 \
  --set-env-vars "GEMINI_MODEL=gemini-2.5-pro" \
  --project "${GCP_PROJECT}" \
  # --allow-unauthenticated is intentional for this demo so Salesforce External
  # Services can call the endpoint without OAuth token management.
  # PRODUCTION NOTE: remove this flag and add proper authentication, such as
  # Cloud Run IAM invoker bindings + Salesforce Named Credentials with
  # JWT/OAuth 2.0, before handling real member PHI.
  --allow-unauthenticated

echo ""
echo "==> Deploy complete."
echo "    Service URL:"
gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --project "${GCP_PROJECT}" \
  --format "value(status.url)"
