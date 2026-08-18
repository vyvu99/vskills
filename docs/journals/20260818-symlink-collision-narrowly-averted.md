# Symlink Collision Almost Destroyed Neighboring Infrastructure

**Date**: 2026-08-18 15:56
**Severity**: High
**Component**: repo-profile detection layer, skill installation system
**Status**: Resolved

## What Happened

During the cook phase of generalizing 6 vskills across different stacks, a critical design decision emerged: where to place the new shared detection layer (`repo-profile.md`). The initial plan named it `~/.claude/skills/_shared/repo-profile.md` — directly mirroring the existing infra folder structure. Git-less than one hour into implementation, the dry-run revealed catastrophe: `~/.claude/skills/_shared/` already existed and contained core infrastructure for the **ck: ecosystem** (cook, review, other shared skill utilities). Running `install.sh` as written would have issued `rm -rf ~/.claude/skills/_shared/` first, nuking that entire dependency tree.

## The Brutal Truth

This is absolutely unacceptable. If install.sh had been run for real (not dry-run), we would have silently deleted infrastructure belonging to a completely separate subsystem because of a naming collision we didn't bother to check. No error would fire. No confirmation. No recovery. Just gone. That's the kind of cascading failure that breaks trust in automation — someone runs a setup script for their local skill and suddenly their entire ck: environment is trashed.

The infuriating part is how preventable this was: a 30-second `ls ~/.claude/skills/` before picking a folder name would have caught it. We didn't do that. We wrote a plan, trusted it without probing the actual filesystem state, and nearly shipped a destructive bug wrapped in what looks like a feature branch.

## Technical Details

**Collision discovered at**: Phase 1 cook, symlink wiring step.
**Conflict paths**:
- Plan named layer: `~/.claude/skills/_shared/repo-profile.md`
- Existing ck: infrastructure: `~/.claude/skills/_shared/` (contains core utilities for cook, review, and test skills)

**install.sh logic** (as initially written):
```bash
rm -rf ~/.claude/skills/_shared/  # DESTRUCTIVE: wipes entire ck: infrastructure
mkdir -p ~/.claude/skills/_shared/
ln -s ~/.claude/skills/vskills/_vskills-shared ~/.claude/skills/_shared/
```

**Actual damage if run**: Loss of `~/.claude/skills/_shared/{cook,review,utils,…}` — every ck: skill that depends on `_shared` would break immediately with "module not found" errors across the entire Claude Code skill ecosystem for this user's machine.

**Detection method**: Fork agent ran install.sh with `--dry-run` flag and traced symlink targets before committing. Caught in time.

## What We Tried

1. **Plan review phase**: Listed treestructure for `~/.claude/skills/` but didn't actually grep the live filesystem — planning assumed empty namespace.
2. **Validate phase**: Fact-checked plan against actual code syntax and file counts, but did NOT validate against external dependencies (`~/.claude` state).
3. **Dry-run catch**: Fork agent executed install script with `--dry-run`, which printed target paths before symlinking. Spotted collision immediately.
4. **Fix applied**: Renamed layer to `_vskills-shared`, updated all 6 skill reference pointers, patched install.sh symlink source, re-validated.

## Root Cause Analysis

Two layers of assumption failure:

1. **Namespace assumption**: Plan assumed `~/.claude/skills/_shared/` was "project-scoped" because it felt foundational to the vskills repo. Didn't cross-check that `_shared` is a **shared namespace across multiple unrelated skill trees** in the same `~/.claude` directory.

2. **Validation scope creep**: Validate phase checked plan internally (syntax, file references, line counts) but defined "validation" narrowly — didn't expand to "validate against external state that install.sh touches." Detection layer pointed to a real FS path outside repo; that path has external dependencies.

3. **Fork agent sloppiness** (2 prior instances): Earlier in the sequence, fork agents replied "doing X" without actually invoking any tools — burned time waiting for fictional progress. This created scheduling pressure that may have rushed the namespace check.

## Lessons Learned

**1. External boundary checks are validation checks, not just code review.**
When a script touches `~/.` or any path outside the repo, validate that path exists and is not a collision target. Grep the live filesystem before picking a name:
```bash
ls ~/.claude/skills/ | grep -E "^_"  # discovers _shared exists
```

**2. Namespace should be project-scoped, never generic.**
`_shared` sounds foundational and reusable. That's exactly why it collided. Pick `_vskills-shared` even if it feels verbose — the specificity prevents accidental reuse by unrelated systems. Generic names are namespace pollution; project-prefixed names are isolation.

**3. Dry-run must precede actual install for scripts touching ~/.**
This saved us. `install.sh --dry-run` printed symlink targets instead of executing; that one step caught the destruction before it happened. Make this a hard gate: no external-path modification without confirmed dry-run output.

**4. Validate phase must expand when dependency tree leaves the repo.**
Detect when a task touches `~/.`, `/opt`, system packages, or other machines. Expand validation scope: don't just check internal syntax, check external state collisions. This is as critical as type-checking.

## Next Steps

1. **Immediate**: Verify `install.sh` in commit `4e2565640bbf3b7` correctly uses `_vskills-shared` in symlink target (already done, but stamp confirmation).
2. **Document the pattern**: Add a comment in `install.sh` explaining why `_vskills-shared` (not `_shared`) and reference this journal entry.
3. **Validate hooks for future skill installations**: Before any new skill installation script is merged, add validation rule: **"If script modifies `~/`, must run `script --dry-run` and inspect printed paths for collisions against `ls ~/.claude/skills/`"**
4. **Apply to CLAUDE.md**: Add to code review checklist (Backend section, already there but underspecified): "External path modifications (~/., /opt, /usr/local) require dry-run validation against existing namespace."

---

**Commit that closed this**: `4e2565640bbf3b7db695bbbe6143c968cc97a46a` — feat: add shared repo-profile detection layer for cross-stack skill compatibility (with `_vskills-shared` collision-free, commit message re-checked to reflect actual scope).

**Related findings fixed before ship**:
- Validate phase: 2 fact-check errors in original plan (sloppy line numbers, gh CLI count off-by-one) — corrected before cook.
- Code review: 1 Medium finding (missing fallback clause) — fixed before commit.
- git-manager initial commit message ("GitHub/GitLab/Gitea") incorrect scope; amend to reflect plan's actual VC support — done before this journal.
