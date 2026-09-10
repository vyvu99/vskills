#!/usr/bin/env node
// Deterministic lint over skills/*/SKILL.md (+ SKILL.vi.md) pairs — no Claude invocation.
// Plain Node built-ins only (no js-yaml dep) — frontmatter here is flat scalar
// `key: value` lines plus one nested `metadata:` block, so a hand-rolled
// line-based parser is sufficient (see phase-01-skill-structure-lint.md §Architecture).
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const SKILLS_DIR = path.join(ROOT, 'skills');

// Source of truth: code.claude.com/docs/en/skills + /slash-commands, verified
// against these exact 20 top-level fields on 2026-09-09 (batch2 phase1 report,
// re-verified 2026-09-10) — re-check this list if Claude Code adds new
// frontmatter fields upstream.
const ALLOWED_FIELDS = [
  'name', 'description', 'when_to_use', 'argument-hint', 'arguments',
  'disable-model-invocation', 'user-invocable', 'allowed-tools', 'disallowed-tools',
  'model', 'effort', 'context', 'agent', 'background', 'hooks', 'paths', 'shell',
  'metadata', 'license', 'compatibility',
];

const violations = []; // { skill, check, detail, advisory }

function addViolation(skill, check, detail, advisory = false) {
  violations.push({ skill, check, detail, advisory });
}

function splitLines(content) {
  const lines = content.split('\n');
  if (lines.length && lines[lines.length - 1] === '') lines.pop();
  return lines;
}

function stripQuotes(s) {
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    return s.slice(1, -1);
  }
  return s;
}

// Returns { fields: Map<key,string>, bodyStartIndex } or null if no frontmatter.
function parseFrontmatter(lines) {
  if (lines[0] !== '---') return null;
  let closeIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') { closeIdx = i; break; }
  }
  if (closeIdx === -1) return null;

  const fmLines = lines.slice(1, closeIdx);
  const fields = new Map();

  let i = 0;
  while (i < fmLines.length) {
    const line = fmLines[i];
    if (line.trim() === '' || /^\s/.test(line)) { i++; continue; } // stray/indented — not a top-level key
    const m = line.match(/^([A-Za-z0-9_-]+):(.*)$/);
    if (!m) { i++; continue; }
    const key = m[1];
    const rest = m[2].trim();

    // Collect continuation lines (blank or indented) that follow this key.
    const continuation = [];
    let j = i + 1;
    while (j < fmLines.length && (fmLines[j] === '' || /^\s/.test(fmLines[j]))) {
      continuation.push(fmLines[j]);
      j++;
    }

    if (key !== 'metadata') {
      let value;
      if (rest === '' || /^[>|][+-]?\d*$/.test(rest)) {
        // Block scalar (`>` folded or `|` literal) — join continuation lines
        // before counting, per phase spec (real YAML folding rules not needed here).
        value = continuation.map((l) => l.trim()).filter((l) => l !== '').join(' ');
      } else {
        value = stripQuotes(rest);
      }
      fields.set(key, value);
    }
    i = j;
  }

  return { fields, bodyStartIndex: closeIdx + 1 };
}

function checkSkill(skillName, skillDir) {
  const mdPath = path.join(skillDir, 'SKILL.md');
  const lines = splitLines(fs.readFileSync(mdPath, 'utf8'));

  const fm = parseFrontmatter(lines);
  if (!fm) {
    addViolation(skillName, 'frontmatter-missing', 'SKILL.md không có frontmatter hợp lệ (thiếu cặp --- mở đầu)');
    return;
  }

  const bodyLineCount = lines.length - fm.bodyStartIndex;
  if (bodyLineCount >= 500) {
    addViolation(skillName, 'body-length', `${bodyLineCount} dòng (>= 500)`);
  }

  for (const key of fm.fields.keys()) {
    if (!ALLOWED_FIELDS.includes(key)) {
      addViolation(skillName, 'frontmatter-field', `field "${key}" không nằm trong allowlist`);
    }
  }

  const description = fm.fields.get('description');
  const whenToUse = fm.fields.get('when_to_use') || '';

  if (description !== undefined) {
    if (description.length > 1024) {
      addViolation(skillName, 'description-length', `${description.length} ký tự (> 1024)`);
    }
    const combinedLength = description.length + whenToUse.length;
    if (combinedLength > 1536) {
      addViolation(skillName, 'description-combined-length', `description+when_to_use ${combinedLength} ký tự (> 1536)`);
    }
    // Block scalars normally collapse to a single line during parsing above —
    // a literal "\n" surviving in the joined value means it was hardcoded raw.
    if (description.includes('\\n')) {
      addViolation(skillName, 'description-format', 'description chứa "\\n" literal thay vì text single-line thực sự');
    }
    // Advisory only — regex-based first-person detection is unreliable.
    if (/^(you\b|i\s|we\s)/i.test(description.trim())) {
      addViolation(skillName, 'description-person', 'description có thể đang viết ở ngôi thứ nhất/thứ hai (you/I/we) thay vì ngôi thứ ba', true);
    }
  }

  const viPath = path.join(skillDir, 'SKILL.vi.md');
  if (fs.existsSync(viPath)) {
    const viLines = splitLines(fs.readFileSync(viPath, 'utf8'));
    if (viLines.length !== lines.length) {
      addViolation(
        skillName,
        'en-vi-parity',
        `SKILL.md ${lines.length} dòng vs SKILL.vi.md ${viLines.length} dòng (lệch ${Math.abs(lines.length - viLines.length)})`,
      );
    }
  }
}

function checkLintRules() {
  const rulesDir = path.join(ROOT, 'scripts', 'lint-rules', 'rules');
  const registryPath = path.join(ROOT, 'scripts', 'lint-rules', 'config', 'rule-registry.json');
  if (!fs.existsSync(rulesDir) || !fs.existsSync(registryPath)) return;

  const registryIds = new Set(Object.keys(JSON.parse(fs.readFileSync(registryPath, 'utf8'))));
  const scriptIds = new Set();

  for (const entry of fs.readdirSync(rulesDir)) {
    if (!entry.endsWith('.sh')) continue;
    const fullPath = path.join(rulesDir, entry);
    const id = entry.slice(0, -'.sh'.length);
    scriptIds.add(id);

    if (!(fs.statSync(fullPath).mode & 0o111)) {
      addViolation('lint-rules', 'rule-executable', `"${entry}" thiếu quyền thực thi (chmod +x)`);
    }
    if (!registryIds.has(id)) {
      addViolation('lint-rules', 'rule-registry-mismatch', `script "${id}" không có entry trong rule-registry.json`);
    }
  }

  for (const id of registryIds) {
    if (!scriptIds.has(id)) {
      addViolation('lint-rules', 'rule-registry-mismatch', `registry entry "${id}" không có script tương ứng trong rules/`);
    }
  }
}

function main() {
  const skillNames = fs.readdirSync(SKILLS_DIR).filter((name) => {
    if (name === '_vskills-shared') return false; // no frontmatter, not a skill
    const full = path.join(SKILLS_DIR, name);
    return fs.statSync(full).isDirectory() && fs.existsSync(path.join(full, 'SKILL.md'));
  });

  for (const name of skillNames) {
    checkSkill(name, path.join(SKILLS_DIR, name));
  }
  checkLintRules();

  const skillsSeen = new Set(violations.map((v) => v.skill));
  for (const v of violations) {
    console.log(`${v.skill}: ${v.check}${v.advisory ? ' [advisory]' : ''} — ${v.detail}`);
  }
  console.log(`${violations.length} violations across ${skillsSeen.size} skills`);

  const blockingCount = violations.filter((v) => !v.advisory).length;
  process.exit(blockingCount > 0 ? 1 : 0);
}

main();
