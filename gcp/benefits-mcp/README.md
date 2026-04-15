# Meridian Benefits Verification MCP Server

A minimal Model Context Protocol (MCP) server that exposes two typed tools
for the Meridian Health MRI pre-authorization demo:

- `check_eligibility(member_id, cpt)` — eligibility + network + prior-auth flag
- `get_coverage(member_id, cpt)` — coverage %, copay, remaining deductible

Implemented as a Node 20 / Express service, containerized, deployed to
Cloud Run. Tool data is backed by a small JSON fixture file (`data/benefits-fixtures.json`)
that simulates a payer eligibility system (a real deployment would front an
X12 270/271 gateway or a FHIR `CoverageEligibilityResponse` endpoint).

## Why MCP in the demo narrative

Agentforce agents do not need a Meridian-specific SDK. Because this service
speaks MCP (open standard, JSON-RPC over HTTP, self-describing tool schemas
at `/.well-known/mcp.json`), the same server is simultaneously callable by:

- **Agentforce** — imported via Salesforce External Services (OpenAPI) and
  surfaced as first-class Agent Actions.
- **Any MCP client** — Claude, Cursor, a custom LangGraph worker — via the
  JSON-RPC `/mcp/rpc` endpoint.

That open-standards posture is the architectural story: Salesforce Data 360
and Agentforce are the system of engagement and the system of record for the
patient 360; specialized tools live where they belong (a Cloud Run micro-
service here, a Vertex AI fraud agent in `../fraud-agent/`) and plug in
through typed contracts rather than custom glue.

## Endpoints

| Method | Path                                  | Purpose                                  |
| ------ | ------------------------------------- | ---------------------------------------- |
| GET    | `/healthz`                            | Liveness probe                           |
| GET    | `/.well-known/mcp.json`               | MCP server descriptor + tool schemas     |
| POST   | `/mcp/tools/check_eligibility`        | REST convenience (for External Services) |
| POST   | `/mcp/tools/get_coverage`             | REST convenience                         |
| POST   | `/mcp/rpc`                            | JSON-RPC 2.0 MCP entrypoint              |

## Run locally

```bash
cd gcp/benefits-mcp
npm install
npm start
# or: npm run dev     # node --watch
```

Then:

```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/.well-known/mcp.json | jq

curl -s -X POST http://localhost:8080/mcp/tools/check_eligibility \
  -H 'content-type: application/json' \
  -d '{"member_id":"M-10047","cpt":"73721"}' | jq

curl -s -X POST http://localhost:8080/mcp/tools/get_coverage \
  -H 'content-type: application/json' \
  -d '{"member_id":"M-10047","cpt":"73721"}' | jq

# JSON-RPC shape (canonical MCP-over-HTTP)
curl -s -X POST http://localhost:8080/mcp/rpc \
  -H 'content-type: application/json' \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"check_eligibility",
      "arguments":{"member_id":"M-10047","cpt":"73721"}
    }
  }' | jq
```

## Deploy to Cloud Run

```bash
export PROJECT_ID=your-gcp-project
export REGION=us-central1   # optional
./deploy.sh
```

The script runs `gcloud builds submit` then `gcloud run deploy` with
`--allow-unauthenticated --min-instances=1 --memory=512Mi --port=8080` and
echoes the final service URL.

## Wire into Salesforce

1. After deploy, edit `openapi.yaml` and replace the `servers[0].url`
   placeholder with the Cloud Run URL.
2. In Salesforce Setup, go to **External Services** → **Add an External
   Service** → **From API Specification** and paste `openapi.yaml`.
3. Save; Salesforce generates two invocable actions: `checkEligibility`
   and `getCoverage`.
4. In the Agentforce Agent Builder, add those as **Agent Actions** on the
   MRI Pre-Auth agent. The agent's system prompt already instructs it to
   call `check_eligibility` before proposing a pre-auth decision and
   `get_coverage` when the member asks about out-of-pocket cost.

## Security note (demo vs. production)

`deploy.sh` passes `--allow-unauthenticated` so the panel demo does not
need OAuth token management. For real PHI traffic, remove that flag, bind
the Cloud Run service to an invoker service account, and call it from
Salesforce via a Named Credential using JWT-bearer OAuth 2.0 against
Google's token endpoint. The OpenAPI spec does not need to change — only
the External Service's named credential binding.

## Layout

```
benefits-mcp/
  src/
    server.js        # Express app, routes, MCP JSON-RPC dispatch
    fixtures.js      # JSON fixture loader + default-response policy
  data/
    benefits-fixtures.json
  Dockerfile
  deploy.sh
  openapi.yaml
  package.json
  README.md
```
