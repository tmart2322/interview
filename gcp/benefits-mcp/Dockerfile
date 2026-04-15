# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Meridian Benefits Verification MCP Server — Cloud Run container
# ---------------------------------------------------------------------------
# Node 20 slim base. PORT is injected by Cloud Run at runtime (default 8080).
# ---------------------------------------------------------------------------

FROM node:20-slim

ENV NODE_ENV=production \
    PORT=8080

WORKDIR /app

# Install dependencies first so Docker layer caching works when only app
# code changes.
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

# Copy application source and fixtures.
COPY src/ ./src/
COPY data/ ./data/

EXPOSE 8080

CMD ["node", "src/server.js"]
