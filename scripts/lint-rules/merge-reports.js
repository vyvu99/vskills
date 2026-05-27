#!/usr/bin/env node
// Reads TSV from stdin: RULE_ID\tFILE\tLINE\tMATCH
// Groups by rule, outputs JSON report
// Usage: bash run.sh <files...> | node merge-reports.js

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

const HISTORY_FILE = path.join(__dirname, 'violation-history.jsonl');

const registryPath = path.join(__dirname, 'config', 'rule-registry.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

function getBlame(file, line) {
  if (!line || line <= 0) return null;
  try {
    const out = execSync(`git blame --porcelain -L ${line},${line} "${file}" 2>/dev/null`, {
      encoding: 'utf8',
      cwd: process.cwd(),
    });
    const author = (out.match(/^author (.+)$/m) || [])[1];
    const ts = (out.match(/^author-time (\d+)$/m) || [])[1];
    if (!author || !ts) return null;
    const date = new Date(parseInt(ts, 10) * 1000).toLocaleString('vi-VN', {
      timeZone: 'Asia/Ho_Chi_Minh',
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit', hour12: false,
    });
    return { author, date };
  } catch {
    return null;
  }
}

const grouped = {};

const rl = readline.createInterface({ input: process.stdin, terminal: false });

rl.on('line', (line) => {
  if (!line.trim()) return;
  const parts = line.split('\t');
  if (parts.length < 4) return;

  const [ruleId, file, lineNum, ...matchParts] = parts;
  const match = matchParts.join('\t').trim();

  if (!grouped[ruleId]) grouped[ruleId] = [];
  const parsedLine = parseInt(lineNum, 10) || 0;
  grouped[ruleId].push({
    file,
    line: parsedLine,
    blame: getBlame(file, parsedLine),
    match: match.slice(0, 200), // cap length to avoid noise
  });
});

rl.on('close', () => {
  const allRuleIds = Object.keys(registry);
  const violatedRuleIds = Object.keys(grouped);
  const passedRuleIds = allRuleIds.filter((id) => !violatedRuleIds.includes(id));

  const violations = violatedRuleIds.map((ruleId) => {
    const meta = registry[ruleId] || { category: 'unknown', severity: 'warning', confidence: 'medium', message: ruleId };
    return {
      rule: ruleId,
      category: meta.category,
      severity: meta.severity,
      confidence: meta.confidence,
      message: meta.message,
      count: grouped[ruleId].length,
      violations: grouped[ruleId],
    };
  });

  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      total_violations: violations.reduce((sum, r) => sum + r.count, 0),
      rules_violated: violatedRuleIds.length,
      rules_passed: passedRuleIds.length,
    },
    violations,
    passed_rules: passedRuleIds,
  };

  process.stdout.write(JSON.stringify(report, null, 2) + '\n');

  // Append compact summary to violation-history.jsonl for trending
  const historyEntry = {
    timestamp: report.timestamp,
    total_violations: report.summary.total_violations,
    rules_violated: report.summary.rules_violated,
    top: violations
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map((v) => ({ rule: v.rule, count: v.count, severity: v.severity })),
  };
  try {
    fs.appendFileSync(HISTORY_FILE, JSON.stringify(historyEntry) + '\n');
  } catch {
    // history write failure must not block the scan output
  }
});
