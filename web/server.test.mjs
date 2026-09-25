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

test('POST /api/step blocks until a matching POST /api/answer resolves it', async () => {
  await withServer({}, async (base) => {
    const stepPromise = postJson(base, '/api/step', { title: 't', fields: [] });

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
    const firstStep = postJson(base, '/api/step', { title: 'first', fields: [] });
    await new Promise((r) => setTimeout(r, 20));

    const secondRes = await postJson(base, '/api/step', { title: 'second', fields: [] });
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
    const res = await postJson(base, '/api/step', { title: 't', fields: [] });
    assert.equal(res.status, 504);

    const after = await (await fetch(`${base}/api/current`)).json();
    assert.equal(after, null);
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
