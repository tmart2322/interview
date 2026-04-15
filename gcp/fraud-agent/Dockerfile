# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Meridian Fraud Risk Agent — Cloud Run container
# ---------------------------------------------------------------------------
# Uses python:3.12-slim to keep the image small.
# gunicorn manages the process lifecycle; uvicorn workers handle async I/O.
# PORT env var is injected by Cloud Run at runtime (default 8080).
# ---------------------------------------------------------------------------

FROM python:3.12-slim

# Prevent Python from writing .pyc files and buffer stdout/stderr so logs
# appear immediately in Cloud Logging.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first so Docker layer caching works when only app
# code changes.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source.
COPY app/ ./app/

# Cloud Run injects $PORT (usually 8080). We expose 8080 as documentation;
# the actual binding is controlled by the CMD below.
EXPOSE 8080

# Use 2 uvicorn workers per the Cloud Run 1-vCPU default.
# Adjust --workers if you scale to a higher CPU tier.
ENV PORT=8080

CMD gunicorn app.main:app \
    --worker-class uvicorn.workers.UvicornWorker \
    --workers 2 \
    --bind "0.0.0.0:${PORT}" \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
