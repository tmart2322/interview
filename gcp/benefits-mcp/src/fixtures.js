const fs = require('fs');
const path = require('path');

const FIXTURES_PATH = path.join(__dirname, '..', 'data', 'benefits-fixtures.json');

let cache = null;

function load() {
  if (cache) return cache;
  const raw = fs.readFileSync(FIXTURES_PATH, 'utf8');
  cache = JSON.parse(raw);
  return cache;
}

function lookup(memberId, cpt) {
  const data = load();
  const key = `${memberId}|${cpt}`;
  return data[key] || null;
}

function defaultFor(memberId, cpt) {
  const isImaging = typeof cpt === 'string' && cpt.startsWith('7');
  return {
    eligible: true,
    coverage_pct: 80,
    copay: 200,
    prior_auth_required: isImaging,
    network_status: 'in-network',
    plan_year_remaining_deductible: 500,
    reason_codes: ['FIXTURE_DEFAULT']
  };
}

module.exports = { load, lookup, defaultFor };
