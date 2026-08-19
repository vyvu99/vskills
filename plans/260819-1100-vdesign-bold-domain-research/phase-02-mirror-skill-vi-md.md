---
phase: 2
title: Mirror SKILL.vi.md
status: completed
effort: 30m
dependencies:
  - 1
---

# Phase 2: Mirror SKILL.vi.md

## Overview

Apply the same structural change from Phase 1 to `skills/vdesign/SKILL.vi.md` (the Vietnamese mirror of `SKILL.md`), in Vietnamese, matching that file's existing tone/terminology.

## Requirements

- Functional: `SKILL.vi.md` ends up structurally identical to the updated `SKILL.md` (same step numbering, same gating on `--bold`, same cache/fallback logic) — content in Vietnamese
- Non-functional: reuse whatever Vietnamese terms the file already uses for "Vibe Commitment", "Pattern-pull", "Project Profile" etc. — do not invent new translations if the file already has established ones

## Related Code Files

- Modify: `skills/vdesign/SKILL.vi.md`

## Implementation Steps

1. Read `skills/vdesign/SKILL.vi.md` in full (do not assume it's a literal line-for-line mirror of the English file — check current wording/terms first).
2. Read the final (post-Phase-1) `skills/vdesign/SKILL.md` to get the exact new English wording to translate.
3. Apply the equivalent edits to `SKILL.vi.md`:
   - Bump `metadata.version` to `5.1.0`
   - Insert the new Domain Research step (Phase 0) in Vietnamese, same position/gating as English
   - Renumber the old Vibe Commitment step, add the domain-research-informed clause
   - Update Phase 3 Pattern-pull paragraph
   - Update Phase 4 short report line
   - Add the new anti-pattern bullet
4. Cross-check both files' Phase 0/Phase 3/Phase 4/Anti-Patterns sections side by side for structural parity (same step count, same gating logic) — wording doesn't need to be a literal translation, but the *rules* must match exactly.

## Success Criteria

- [ ] `SKILL.vi.md` has the same new Domain Research step as `SKILL.md`, in Vietnamese, same position and `--bold` gating
- [ ] `SKILL.vi.md` Vibe Commitment, Pattern-pull, Phase 4 short report, and Anti-Patterns sections match `SKILL.md`'s updated logic
- [ ] `metadata.version` is `5.1.0` in both files
- [ ] No drift introduced between the two files beyond language

## Risk Assessment

- Risk: silent drift between EN/VI files if the translator paraphrases instead of matching rules 1:1 → mitigate via the explicit side-by-side cross-check step above.
