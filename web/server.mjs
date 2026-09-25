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

const FIELD_TYPES = ['select', 'text', 'diff-review-list'];
const RENDER_HINTS = ['plain', 'swatch', 'font-sample'];
const CSS_COLOR_RE = /^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$|^(rgb|rgba|hsl|hsla)\(/i;

function isNonEmptyString(value) {
  return typeof value === 'string' && value.length > 0;
}

function validateSelectField(field, prefix, errors) {
  if (!Array.isArray(field.options) || field.options.length === 0) {
    errors.push(`${prefix}.options phải là 1 mảng không rỗng`);
    return;
  }
  field.options.forEach((option, i) => {
    const p = `${prefix}.options[${i}]`;
    if (!isNonEmptyString(option?.label)) errors.push(`${p}.label phải là string không rỗng`);
    if (!isNonEmptyString(option?.value)) errors.push(`${p}.value phải là string không rỗng`);
    if (option?.renderHint !== undefined && !RENDER_HINTS.includes(option.renderHint)) {
      errors.push(`${p}.renderHint phải là 1 trong ${RENDER_HINTS.join('/')}, nhận "${option.renderHint}"`);
    }
    if (option?.renderHint === 'swatch' && isNonEmptyString(option.value) && !CSS_COLOR_RE.test(option.value)) {
      errors.push(`${p}.value phải là màu CSS thật (hex/rgb/hsl) khi renderHint là "swatch", nhận "${option.value}"`);
    }
  });
}

function validateDiffReviewListField(field, prefix, errors) {
  if (!Array.isArray(field.items) || field.items.length === 0) {
    errors.push(`${prefix}.items phải là 1 mảng không rỗng`);
    return;
  }
  field.items.forEach((item, i) => {
    const p = `${prefix}.items[${i}]`;
    if (!isNonEmptyString(item?.id)) errors.push(`${p}.id phải là string không rỗng`);
    if (typeof item?.before !== 'string') errors.push(`${p}.before phải là string`);
    if (typeof item?.after !== 'string') errors.push(`${p}.after phải là string`);
    if (!Array.isArray(item?.actions) || item.actions.length === 0) errors.push(`${p}.actions phải là 1 mảng không rỗng`);
  });
}

function validateTemplate(template) {
  const errors = [];
  if (typeof template !== 'object' || template === null) {
    return ['template phải là 1 object'];
  }
  if (!isNonEmptyString(template.title)) errors.push('title phải là string không rỗng');
  if (!Array.isArray(template.fields) || template.fields.length === 0) {
    errors.push('fields phải là 1 mảng không rỗng');
    return errors;
  }

  const seenIds = new Set();
  template.fields.forEach((field, i) => {
    const prefix = `fields[${i}]`;
    if (!isNonEmptyString(field?.id)) {
      errors.push(`${prefix}.id phải là string không rỗng`);
    } else if (seenIds.has(field.id)) {
      errors.push(`${prefix}.id "${field.id}" bị trùng với 1 field khác`);
    } else {
      seenIds.add(field.id);
    }
    if (!isNonEmptyString(field?.label)) errors.push(`${prefix}.label phải là string không rỗng`);
    if (!FIELD_TYPES.includes(field?.type)) {
      errors.push(`${prefix}.type phải là 1 trong ${FIELD_TYPES.join('/')}, nhận "${field?.type}"`);
      return;
    }
    if (field.type === 'select') validateSelectField(field, prefix, errors);
    if (field.type === 'diff-review-list') validateDiffReviewListField(field, prefix, errors);
  });

  return errors;
}

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
        const validationErrors = validateTemplate(template);
        if (validationErrors.length > 0) {
          return sendJson(res, 400, { error: 'invalid template', details: validationErrors });
        }
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
