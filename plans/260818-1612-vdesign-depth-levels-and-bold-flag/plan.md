---
title: 'vdesign: redesign depth levels (L1-L5) + bold flag + project profile'
description: ''
status: completed
priority: P2
branch: main
tags: []
blockedBy: []
blocks: []
created: '2026-08-18T09:13:04.290Z'
createdBy: 'ck:plan'
source: skill
---

# vdesign: redesign depth levels (L1-L5) + bold flag + project profile

## Overview

Replace vdesign's binary `--uplift`/`--redesign` flags with a 5-level depth ladder (`--L1`..`--L5`), add an independent `--bold` flag for Awwwards-tier ambition (requires `--L4`/`--L5`), and generalize the hardcoded "Constraints for eTARO" section into a reusable Project Profile mechanism. Full design rationale: `plans/reports/brainstorm-20260818-vdesign-depth-levels.md`. Content-only change — single-file skill convention preserved, no `references/` split, no `install.sh` changes.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Rewrite SKILL.md](./phase-01-rewrite-skill-md.md) | Completed |
| 2 | [Mirror SKILL.vi.md](./phase-02-mirror-skill-vi-md.md) | Completed |

## Dependencies

<!-- Cross-plan dependencies -->
