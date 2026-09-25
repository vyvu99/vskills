import { createServer as createHttpServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const SERVICE_NAME = 'vskills-webapp';
export const DEFAULT_STEP_TIMEOUT_MS = 30 * 60 * 1000;
const PUBLIC_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), 'public');

function sendJson(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
}

const CONTENT_TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css' };

async function serveStaticFile(res, url) {
  const relativePath = url === '/' ? '/index.html' : url;
  const filePath = path.join(PUBLIC_DIR, path.normalize(relativePath));
  if (!filePath.startsWith(PUBLIC_DIR)) return false;
  try {
    const body = await readFile(filePath);
    const contentType = CONTENT_TYPES[path.extname(filePath)] || 'application/octet-stream';
    res.writeHead(200, { 'content-type': contentType });
    res.end(body);
    return true;
  } catch {
    return false;
  }
}

export function createServer({ stepTimeoutMs = DEFAULT_STEP_TIMEOUT_MS } = {}) {
  let pending = null; // { id, template, resolve, timer }

  return createHttpServer(async (req, res) => {
    try {
      if (req.method === 'GET' && req.url === '/api/health') {
        return sendJson(res, 200, { service: SERVICE_NAME, ok: true });
      }

      if (req.method === 'GET' && req.url === '/api/current') {
        return sendJson(res, 200, pending ? { id: pending.id, ...pending.template } : null);
      }

      if (req.method === 'POST' && req.url === '/api/step') {
        if (pending) return sendJson(res, 409, { error: 'a step is already pending' });
        const template = await readJsonBody(req);
        const id = crypto.randomUUID();
        const result = await new Promise((resolve) => {
          const timer = setTimeout(() => {
            pending = null;
            resolve({ timedOut: true });
          }, stepTimeoutMs);
          pending = { id, template, resolve, timer };
        });
        if (result.timedOut) return sendJson(res, 504, { error: 'timed out waiting for answer' });
        return sendJson(res, 200, result.answer);
      }

      if (req.method === 'POST' && req.url === '/api/answer') {
        if (!pending) return sendJson(res, 404, { error: 'no step is pending' });
        const answer = await readJsonBody(req);
        clearTimeout(pending.timer);
        pending.resolve({ answer });
        pending = null;
        return sendJson(res, 200, { ok: true });
      }

      if (req.method === 'GET') {
        const served = await serveStaticFile(res, req.url);
        if (served) return;
      }

      res.writeHead(404, { 'content-type': 'text/plain' });
      res.end('not found');
    } catch (err) {
      sendJson(res, 400, { error: err.message });
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const port = Number(process.env.VSKILLS_WEBAPP_PORT || 4270);
  const stepTimeoutMs = Number(process.env.VSKILLS_WEBAPP_STEP_TIMEOUT_MS || DEFAULT_STEP_TIMEOUT_MS);
  createServer({ stepTimeoutMs }).listen(port, () => {
    console.log(`listening on :${port}`);
  });
}
