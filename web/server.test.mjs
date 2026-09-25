import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from './server.mjs';

async function withServer(opts, run) {
  const server = createServer(opts);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  try {
    await run(`http://localhost:${port}`);
  } finally {
    server.close();
  }
}

function postJson(base, path, body) {
  return fetch(`${base}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

test('GET /api/health identifies the service', async () => {
  await withServer({}, async (base) => {
    const res = await fetch(`${base}/api/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { service: 'vskills-webapp', ok: true });
  });
});

test('GET /api/current is null when nothing is pending', async () => {
  await withServer({}, async (base) => {
    const res = await fetch(`${base}/api/current`);
    assert.equal(await res.json(), null);
  });
});

const VALID_FIELD = { id: 'notes', type: 'text', label: 'Notes' };

test('POST /api/step blocks until a matching POST /api/answer resolves it', async () => {
  await withServer({}, async (base) => {
    const stepPromise = postJson(base, '/api/step', { title: 't', fields: [VALID_FIELD] });

    await new Promise((r) => setTimeout(r, 20));
    const current = await (await fetch(`${base}/api/current`)).json();
    assert.equal(current.title, 't');
    assert.ok(current.id);

    const answerPromise = postJson(base, '/api/answer', { pick: 'yes' });
    const [stepRes, answerRes] = await Promise.all([stepPromise, answerPromise]);

    assert.equal(answerRes.status, 200);
    assert.equal(stepRes.status, 200);
    assert.deepEqual(await stepRes.json(), { pick: 'yes' });

    const after = await (await fetch(`${base}/api/current`)).json();
    assert.equal(after, null);
  });
});

test('POST /api/step returns 409 when a step is already pending', async () => {
  await withServer({}, async (base) => {
    const firstStep = postJson(base, '/api/step', { title: 'first', fields: [VALID_FIELD] });
    await new Promise((r) => setTimeout(r, 20));

    const secondRes = await postJson(base, '/api/step', { title: 'second', fields: [VALID_FIELD] });
    assert.equal(secondRes.status, 409);

    await postJson(base, '/api/answer', { done: true });
    await firstStep;
  });
});

test('POST /api/answer returns 404 when nothing is pending', async () => {
  await withServer({}, async (base) => {
    const res = await postJson(base, '/api/answer', { pick: 'yes' });
    assert.equal(res.status, 404);
  });
});

test('POST /api/step times out and returns 504 when no answer arrives in time', async () => {
  await withServer({ stepTimeoutMs: 20 }, async (base) => {
    const res = await postJson(base, '/api/step', { title: 't', fields: [VALID_FIELD] });
    assert.equal(res.status, 504);

    const after = await (await fetch(`${base}/api/current`)).json();
    assert.equal(after, null);
  });
});

test('POST /api/step rejects a malformed template with 400 and does not block', async () => {
  const cases = [
    { name: 'missing title', body: { fields: [VALID_FIELD] } },
    { name: 'fields not an array', body: { title: 't', fields: 'nope' } },
    { name: 'empty fields array', body: { title: 't', fields: [] } },
    { name: 'field missing id', body: { title: 't', fields: [{ type: 'text', label: 'x' }] } },
    { name: 'field missing label', body: { title: 't', fields: [{ id: 'a', type: 'text' }] } },
    { name: 'field unknown type', body: { title: 't', fields: [{ id: 'a', type: 'checkbox', label: 'x' }] } },
    {
      name: 'select with no options',
      body: { title: 't', fields: [{ id: 'a', type: 'select', label: 'x', options: [] }] },
    },
    {
      name: 'select option missing value',
      body: { title: 't', fields: [{ id: 'a', type: 'select', label: 'x', options: [{ label: 'A' }] }] },
    },
    {
      name: 'select renderHint invalid enum',
      body: {
        title: 't',
        fields: [{ id: 'a', type: 'select', label: 'x', options: [{ label: 'A', value: 'v', renderHint: 'bold' }] }],
      },
    },
    {
      name: 'swatch value is not a color',
      body: {
        title: 't',
        fields: [
          { id: 'a', type: 'select', label: 'x', options: [{ label: 'A', value: 'Trend-forward', renderHint: 'swatch' }] },
        ],
      },
    },
    {
      name: 'diff-review-list with no items',
      body: { title: 't', fields: [{ id: 'a', type: 'diff-review-list', label: 'x', items: [] }] },
    },
    {
      name: 'diff-review-list item missing actions',
      body: {
        title: 't',
        fields: [{ id: 'a', type: 'diff-review-list', label: 'x', items: [{ id: 'i1', before: 'b', after: 'a' }] }],
      },
    },
    {
      name: 'duplicate field ids',
      body: { title: 't', fields: [VALID_FIELD, VALID_FIELD] },
    },
  ];

  await withServer({}, async (base) => {
    for (const { name, body } of cases) {
      const res = await postJson(base, '/api/step', body);
      assert.equal(res.status, 400, `expected 400 for: ${name}`);
      const payload = await res.json();
      assert.ok(Array.isArray(payload.details) && payload.details.length > 0, `expected details for: ${name}`);

      const current = await (await fetch(`${base}/api/current`)).json();
      assert.equal(current, null, `rejected template must not become pending: ${name}`);
    }
  });
});

test('GET / serves the static frontend page', async () => {
  await withServer({}, async (base) => {
    const res = await fetch(`${base}/`);
    assert.equal(res.status, 200);
    const body = await res.text();
    assert.match(body, /<!doctype html>/i);
  });
});
