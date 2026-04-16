#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy.sh — Build and deploy the Meridian Benefits Verification MCP server
#             to Cloud Run.
#
# Prerequisites:
#   1. gcloud CLI installed and authenticated  (`gcloud auth login`)
#   2. Application Default Credentials set up  (`gcloud auth application-default login`)
#   3. $PROJECT_ID environment variable pointing to your GCP project ID
#   4. Cloud Run, Cloud Build, and Artifact Registry APIs enabled
#
# Usage:
#   export PROJECT_ID=my-gcp-project-id
#   export REGION=us-central1          # optional, defaults to us-central1
#   bash deploy.sh
# ---------------------------------------------------------------------------

set -euo pipefail

if [[ -z "${PROJECT_ID:-}" ]]; then
  echo "ERROR: PROJECT_ID environment variable is not set." >&2
  echo "       Run: export PROJECT_ID=<your-gcp-project-id>" >&2
  exit 1
fi

REGION="${REGION:-us-central1}"
SERVICE_NAME="benefits-mcp"
IMAGE="us-docker.pkg.dev/${PROJECT_ID}/gcr-io/${SERVICE_NAME}"

echo "==> Project  : ${PROJECT_ID}"
echo "==> Region   : ${REGION}"
echo "==> Service  : ${SERVICE_NAME}"
echo "==> Image    : ${IMAGE}"
echo ""

# ---------------------------------------------------------------------------
# Step 1 — Build and push container image via Cloud Build.
# ---------------------------------------------------------------------------
echo "==> Building and pushing container image..."
gcloud builds submit \
  --tag "${IMAGE}" \
  --project "${PROJECT_ID}" \
  .

# ---------------------------------------------------------------------------
# Step 2 — Deploy to Cloud Run.
# --allow-unauthenticated is intentional for the demo so Salesforce External
# Services can call the endpoint without OAuth token management.
# PRODUCTION NOTE: remove --allow-unauthenticated and add Cloud Run IAM
# invoker bindings + Salesforce Named Credentials (JWT/OAuth 2.0) before
# handling real member PHI.
# ---------------------------------------------------------------------------
echo "==> Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --min-instances 1 \
  --memory 512Mi \
  --port 8080 \
  --project "${PROJECT_ID}"

echo ""
echo "==> Deploy complete. Service URL:"
gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --project "${PROJECT_ID}" \
  --format "value(status.url)"
