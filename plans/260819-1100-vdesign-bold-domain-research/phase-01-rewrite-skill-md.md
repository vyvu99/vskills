---
phase: 1
title: Rewrite SKILL.md
status: completed
effort: 1h
---

# Phase 1: Rewrite SKILL.md

## Overview

Edit `skills/vdesign/SKILL.md`: insert a new "Domain Research" step in Phase 0 (before Vibe Commitment, `--bold`-only), wire its output into Vibe Commitment and Phase 3 Pattern-pull, bump version, add anti-pattern guards.

## Requirements

- Functional:
  - Domain Research only triggers when `--bold` is set (not plain L2/L3)
  - Domain slug derives from Project Profile domain (step 4) + target feature/page name (step 1) — no extra question to the user
  - Cache lookup by domain-slug against `plans/reports/researcher-vdesign-bold-<slug>*.md` created this session/day before spawning a new researcher agent
  - Researcher agent runs via delegation (Task/Agent tool), not inline `WebSearch`/`mimo__search` calls in the skill's own flow
  - Static catalog (`premium-design-patterns.md`) stays the baseline — domain research output is additive, never a replacement
  - Silent fallback to static-catalog-only if research/agent fails, with a one-line note surfaced in the Phase 4 short report
- Non-functional: keep single-file skill convention (no new `references/` file); keep existing table/checklist formatting style intact

## Architecture

Insertion point is `### Phase 0: Determine scope`, current step 6 (line ~74 as of this plan's writing — re-locate by content match, not by line number, since the file may have shifted). Current step 6 becomes step 7; new step 6 is Domain Research.

```
Phase 0
  ...
  4. Resolve Project Profile
  5. Ask if input empty
  6. [NEW] Domain Research (--bold only)
       → domain-slug, cache check, spawn researcher agent OR reuse cache OR fallback
  7. [was 6] Vibe Commitment — now also informed by step 6's report if present
```

Phase 3 Pattern-pull paragraph gets one clause added: pull from static catalog **plus** the domain research report (merge, don't replace) when one exists for this run.

Phase 4 short report gets a one-line addition: note when domain research was used vs. unavailable.

## Related Code Files

- Modify: `skills/vdesign/SKILL.md`

## Implementation Steps

1. Re-read the current `skills/vdesign/SKILL.md` in full immediately before editing (content may have shifted since this plan was written — this repo has edited this exact file same-day already).

2. In the frontmatter, bump `metadata.version` from `"5.0.0"` to `"5.1.0"` (additive minor feature, no breaking change to existing flags).

3. In `### Phase 0: Determine scope`, insert a new step between the current step 5 ("If empty → ask...") and step 6 ("If `--bold` is set → **Vibe Commitment**..."). Renumber the old step 6 to step 7. New step text (adapt wording to match the file's existing tone/terseness):

   ```
   6. If `--bold` is set → **Domain Research**, before Vibe Commitment:
      - Domain slug = the domain from the Project Profile's context (e.g. "B2B Healthcare") + the target feature/page name resolved in step 1 (e.g. "booking form") — slugify (e.g. `healthcare-booking-form`)
      - Cache check: look in `plans/reports/` for `researcher-vdesign-bold-<slug>*.md` created earlier this session/today — present → read and reuse, skip straight to Vibe Commitment
      - No cache → spawn 1 researcher agent (Task/Agent tool) to find current (2025-2026) UI/UX/animation/layout patterns specific to `<target feature>` in `<domain>` product context — must stay inside the B2B "clarity > impressiveness" bias (not pure Awwwards/portfolio inspiration); report concrete named patterns with sources. Save to `plans/reports/researcher-vdesign-bold-<slug>-<HHMMSS>.md`
      - Agent/search fails or unavailable → fall back silently to the static catalog only; note "domain research unavailable" in the Phase 4 short report
   ```

4. Update the old step 6 (now step 7, Vibe Commitment) to reference the domain research output: after "...propose the best-fit vibe for the project's domain and state it out loud before implementing", add a clause noting the pick may draw on step 6's domain research report when one exists, and that the run should state which source (static catalog vs. domain research) grounded the choice.

5. In Phase 3, in the **Pattern-pull, not audit-fix.** paragraph, after the existing catalog-reference sentence, add: pull 3-5 patterns from the static catalog **plus** any domain-specific patterns/insights from this run's domain research report (if one exists) — merge, don't replace.

6. In Phase 4, step 5 (short report), add a line: if `--bold` ran, note briefly whether domain research was used or fell back to the static catalog only.

7. Add 1 new bullet to `## Anti-Patterns`: skipping the cache check and re-researching the same domain within the same session/day.

## Success Criteria

- [ ] `metadata.version` is `5.1.0`
- [ ] Phase 0 has a new numbered step for Domain Research, gated on `--bold`, positioned before Vibe Commitment
- [ ] Domain Research step specifies: slug derivation (Project Profile + target feature), cache check against `plans/reports/`, researcher-agent delegation (not inline WebSearch), and a silent fallback path
- [ ] Vibe Commitment step references the domain research output as an optional additional input, static catalog remains the default/baseline
- [ ] Phase 3 Pattern-pull explicitly merges domain research findings on top of the static catalog
- [ ] Phase 4 short report template includes a domain-research status note
- [ ] No existing Phase 0-4 content, hard rules, or anti-patterns were removed or contradicted
- [ ] File remains single-file (no new `references/*.md` created for vdesign)

## Risk Assessment

- Risk: inserted step reads as bloating an already-dense Phase 0 → mitigate by keeping the new step as terse as the existing steps (bullet sub-list, no prose padding).
- Risk: domain-slug derivation is under-specified for edge cases (e.g. no Project Profile resolved, ambiguous target) → acceptable per approved design; if it proves too vague in practice, that's a follow-up fix, not a blocker for this phase (per `level-cut-5-to-3` journal's usage-data lesson — don't over-design before a real run tests it).
