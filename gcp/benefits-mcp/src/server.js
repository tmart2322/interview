const express = require('express');
const cors = require('cors');
const { lookup, defaultFor, load } = require('./fixtures');

const PORT = process.env.PORT || 8080;
const VERSION = '0.1.0';

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '1mb' }));

function log(obj) {
  process.stdout.write(JSON.stringify({ ts: new Date().toISOString(), ...obj }) + '\n');
}

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    log({
      level: 'info',
      event: 'http',
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration_ms: Date.now() - start
    });
  });
  next();
});

// ---------- Tool implementations ----------

function toolCheckEligibility({ member_id, cpt }) {
  if (!member_id || !cpt) {
    const err = new Error('member_id and cpt are required');
    err.code = 'INVALID_ARGUMENT';
    throw err;
  }
  const hit = lookup(member_id, cpt);
  const rec = hit || defaultFor(member_id, cpt);
  return {
    eligible: rec.eligible,
    network_status: rec.network_status,
    prior_auth_required: rec.prior_auth_required,
    reason_codes: rec.reason_codes || []
  };
}

function toolGetCoverage({ member_id, cpt }) {
  if (!member_id || !cpt) {
    const err = new Error('member_id and cpt are required');
    err.code = 'INVALID_ARGUMENT';
    throw err;
  }
  const hit = lookup(member_id, cpt);
  const rec = hit || defaultFor(member_id, cpt);
  return {
    coverage_pct: rec.coverage_pct,
    copay: rec.copay,
    plan_year_remaining_deductible: rec.plan_year_remaining_deductible,
    reason_codes: rec.reason_codes || []
  };
}

const TOOLS = {
  check_eligibility: {
    handler: toolCheckEligibility,
    schema: {
      name: 'check_eligibility',
      description: 'Check whether a member is eligible for a given CPT procedure, with network status and prior-auth flag.',
      inputSchema: {
        type: 'object',
        required: ['member_id', 'cpt'],
        properties: {
          member_id: { type: 'string', description: 'Meridian Health member id, e.g. M-10047' },
          cpt: { type: 'string', description: 'CPT/HCPCS procedure code, e.g. 73721 (MRI lower extremity)' }
        }
      },
      outputSchema: {
        type: 'object',
        properties: {
          eligible: { type: 'boolean' },
          network_status: { type: 'string', enum: ['in-network', 'out-of-network', 'not-covered'] },
          prior_auth_required: { type: 'boolean' },
          reason_codes: { type: 'array', items: { type: 'string' } }
        }
      }
    }
  },
  get_coverage: {
    handler: toolGetCoverage,
    schema: {
      name: 'get_coverage',
      description: 'Return the coverage percentage, copay, and remaining plan-year deductible for a member/CPT pair.',
      inputSchema: {
        type: 'object',
        required: ['member_id', 'cpt'],
        properties: {
          member_id: { type: 'string' },
          cpt: { type: 'string' }
        }
      },
      outputSchema: {
        type: 'object',
        properties: {
          coverage_pct: { type: 'number' },
          copay: { type: 'number' },
          plan_year_remaining_deductible: { type: 'number' },
          reason_codes: { type: 'array', items: { type: 'string' } }
        }
      }
    }
  }
};

// ---------- Routes ----------

app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/.well-known/mcp.json', (req, res) => {
  res.json({
    name: 'benefits-verification',
    version: VERSION,
    protocol: 'mcp/0.1',
    description: 'Meridian Health benefits eligibility & coverage MCP server.',
    transports: ['http+json-rpc', 'http+rest'],
    endpoints: {
      rpc: '/mcp/rpc',
      rest: {
        check_eligibility: '/mcp/tools/check_eligibility',
        get_coverage: '/mcp/tools/get_coverage'
      }
    },
    tools: Object.values(TOOLS).map((t) => t.schema)
  });
});

app.post('/mcp/tools/check_eligibility', (req, res) => {
  try {
    const out = toolCheckEligibility(req.body || {});
    res.json(out);
  } catch (e) {
    res.status(400).json({ error: e.code || 'ERROR', message: e.message });
  }
});

app.post('/mcp/tools/get_coverage', (req, res) => {
  try {
    const out = toolGetCoverage(req.body || {});
    res.json(out);
  } catch (e) {
    res.status(400).json({ error: e.code || 'ERROR', message: e.message });
  }
});

app.post('/mcp/rpc', (req, res) => {
  const { jsonrpc, id, method, params } = req.body || {};
  const reply = (body) => res.json({ jsonrpc: '2.0', id: id ?? null, ...body });

  if (jsonrpc !== '2.0') {
    return reply({ error: { code: -32600, message: 'Invalid Request: jsonrpc must be "2.0"' } });
  }

  try {
    if (method === 'tools/list') {
      return reply({ result: { tools: Object.values(TOOLS).map((t) => t.schema) } });
    }
    if (method === 'tools/call') {
      const name = params && params.name;
      const args = (params && params.arguments) || {};
      const tool = TOOLS[name];
      if (!tool) {
        return reply({ error: { code: -32601, message: `Unknown tool: ${name}` } });
      }
      const content = tool.handler(args);
      return reply({
        result: {
          content: [{ type: 'json', json: content }],
          isError: false
        }
      });
    }
    return reply({ error: { code: -32601, message: `Method not found: ${method}` } });
  } catch (e) {
    return reply({ error: { code: -32000, message: e.message, data: { code: e.code || 'ERROR' } } });
  }
});

app.use((err, req, res, next) => {
  log({ level: 'error', event: 'unhandled', message: err.message, stack: err.stack });
  res.status(500).json({ error: 'INTERNAL', message: err.message });
});

// Preload fixtures so failures surface at boot, not first request.
load();

app.listen(PORT, () => {
  log({ level: 'info', event: 'startup', port: PORT, version: VERSION });
});
