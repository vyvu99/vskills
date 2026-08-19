# vdesign --bold: Domain Research Split into 4 Parallel Aspect Agents

**Date**: 2026-08-19
**Severity**: Low
**Component**: vdesign skill (`skills/vdesign/SKILL.md`, `SKILL.vi.md`)
**Status**: Resolved

## What Happened

Shipped `--L3 --bold` with single-agent domain research (commit `3970af9`, ~2 hours earlier today) per the morning brainstorm design (`brainstorm-105943-vdesign-bold-domain-research.md`). User tested it on a real `--bold` run and reported the domain research report came back too shallow/generic — not detailed enough to visibly inform the vibe or pattern choices.

Root cause: one agent tasked with researching all four aspects (UI/Visual, UX/Interaction, Animation/Motion, Layout/Responsive) for a domain+feature produced a report that tried to cover everything equally and ended up covering nothing deeply. The "single agent for simplicity" trade-off that was explicitly chosen and documented in the morning brainstorm was proven wrong by actual usage, not speculation.

## The Fix

Reversed the "1 agent" design. Phase 0 step 6 (Domain Research) now splits into **4 fixed parallel aspect-specific agents** (commit `ca1b1db`):

**Phase 0 step 6 (Domain Research)**
- Aspect list: fixed as `ui`, `ux`, `animation`, `layout`
- Cache check **per-aspect** (not bundled): look for `researcher-vdesign-bold-<slug>-<aspect>-*.md` files created today/session → cached aspects reuse, uncached spawn fresh agents
- Spawn all uncached aspects in parallel (single message, one Task/Agent call per aspect missing cache) — each agent researches only its assigned aspect, saves to `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
- **Partial fallback** (not all-or-nothing): if one aspect's agent fails, that aspect falls back silently to the static catalog; other aspects (cached or fresh) continue. Never fail the whole domain-research step because one aspect failed.

**Phase 0 step 7 (Vibe Commitment)**
- Reads all available aspect reports (up to 4: cached + fresh) instead of 1 combined file
- Explicitly states which aspects grounded the vibe pick and their status (cached/fresh/fallback-to-static)

**Phase 3 (Pattern-pull)**
- Merges patterns from all available aspect reports (up to 4) instead of 1

**Phase 4 (Short Report)**
- Changed from "1 line noting domain research fresh/cached/fallback" to "1 line per aspect" — e.g., `ui: fresh, ux: cached, animation: fallback (agent unavailable), layout: fresh`

**Anti-Patterns**
- Updated singleton anti-pattern bullet: "Re-run domain research for an aspect already cached this session/day for the same domain-slug — check `plans/reports/` per-aspect first, reuse instead of re-researching; only cache-missed aspects get a fresh agent"

Version bumped `5.1.0` → `5.2.0` in both `SKILL.md` and `SKILL.vi.md`, kept in lockstep (no EN/VI drift).

## Lessons Learned

**1. "1 agent did it yesterday, so 1 is the answer" breaks under real usage.** The morning brainstorm (8 hours ago in calendar time, ~2 hours in implementation time) made a legitimate choice: "1 agent for simplicity, no parallelism." That held up during design discussion. It broke 90 minutes after shipping because a single researcher tasked with 4 aspects produces a report where each aspect got ~25% of the depth, not the full depth. The reversal was legitimate because it was grounded in actual post-ship test feedback ("I ran it, it came back shallow"), not re-litigating the abstract trade-off.

**2. This is the 4th design change to `--bold` in 2 days.** 
   - Day 1 (commit `75216f5`): shipped `--L1`..`--L5` (5-level depth ladder)
   - Day 2 morning (commit `c69231b`): collapsed `--L1`..`--L5` to `--L1`..`--L3` (same-day gut-check, no usage data)
   - Day 2 morning (commit `ca1b1db` predecessor): added Vibe Commitment + Pattern-pull gates (v4.1.0, brainstorm-driven)
   - Day 2 afternoon (commit `ca1b1db` predecessor): added domain research phase, 1 agent (v5.1.0)
   - Day 2 afternoon (now): split domain research into 4 parallel agents (v5.2.0)
   
   First 3 were brainstorm-driven. This 4th one came from real usage. Worth watching: if the next feedback also comes from actual `--bold` runs (not worry), keep iterating. If it's back to pre-emptive "might not be good enough," that's a signal to let it stabilize instead of re-cutting again.

**3. Per-aspect cache granularity is the cost-control lever.** Splitting into 4 agents looks expensive (~4x domain-research cost per new domain). But per-aspect caching means re-running `--bold` on the same domain for a *different* target feature only pays the research cost for aspects that don't already have a same-day cache hit. E.g., researching a "dashboard redesign" for healthcare, then "form redesign" for the same healthcare domain: if the UI/Visual patterns are cached from the first run, the second run spawns only 3 agents (UX/Animation/Layout) and reuses UI. Without per-aspect granularity, it would re-spawn all 4.

**4. Reversing a same-day decision requires new evidence, and this had it.** The morning brainstorm decided "1 agent, simpler" was a good trade-off. Per the rules, that decision should only be reversed if new data justified it. "I tested it, too shallow" is new data (actual user test result), not the same "maybe 1 agent won't be detailed enough" worry that was already evaluated and accepted. The reversal is sticky because it came from usage, not speculation — but if the next feedback *is* speculation, the reversal doesn't re-open; that's the point of the sticky rule.

## Next Steps

No immediate action. Both `SKILL.md` and `SKILL.vi.md` updated, version locked, not pushed (pending user review). Follow-up only if the next real `--bold` run still underperforms on report depth, in which case the next suspect is not the research mechanism but the implementation of Vibe Commitment or Pattern-pull (e.g., maybe the vibe isn't being stated clearly enough, or patterns aren't being selected distinctively enough from the research findings).

---

**Related**: `plans/reports/brainstorm-105943-vdesign-bold-domain-research.md` (morning design: 1 agent), `plans/reports/brainstorm-143800-vdesign-bold-parallel-domain-research.md` (afternoon reversal: 4 agents, grounded in user test), `docs/journals/20260819-vdesign-bold-mode-awwwards-gap.md` (Vibe Commitment + Pattern-pull gates, same day), `docs/journals/20260819-vdesign-level-cut-5-to-3.md` (L5→L3 collapse, same day).
