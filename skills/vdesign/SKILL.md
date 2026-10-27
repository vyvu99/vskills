---
name: vdesign
description: "Redesigns the UI/UX of an existing page, component, feature, or PR diff to a refined, harmonious, accessible standard. Reads the real user and task, runs current design research, self-decides 18 style and structure criteria (no upfront Q&A), then audits, fixes, and verifies at 375/768/1280px. API-layer changes are in scope; DB schema is not."
user-invocable: true
when_to_use: "Use when the user asks to redesign, upgrade, modernize, or make an existing page, component, feature, or PR look and feel better. Not for building a new UI from scratch, a read-only design critique, or a one-line CSS bug fix."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]]"
metadata:
  author: vyvu
  version: "10.0.0"
---

# vdesign — UI/UX Redesign

Upgrade an existing UI to a high execution standard: refined, harmonious, modern, elegant, accessible. The style itself (bold or restrained, close to the current system or a deliberate departure) is decided fresh each run from current research and the real user/task, so it is never asked and never copied from habit.

`vdesign <target>` is the only mode. It is audit-driven: it fixes whatever the audit finds, from spacing up to a visual-direction change. Phase 1 self-decides all 18 criteria in `references/aesthetic-customization.md` and commits them to a Design Brief before any code changes.

Boundaries: keep the tech stack, change only what the audit and the brief require (no unrequested features, tests, or docs), and never change the DB schema or run a migration. API/service-layer changes are in scope when the redesign needs them, because a better view often needs a field the API never returned.

---

## Input modes

| Input | Handling |
|-------|----------|
| _(empty)_ | Ask one question: "Which part do you want to redesign?" |
| URL or `localhost:PORT/path` | Screenshot first, then read the matching source files |
| Route path (e.g. `/clients/[id]?tab=notes`) | Resolve to the page and component files |
| Component or feature name | Grep for the file, then read its component tree |
| `[Image]` | Extract design gaps and apply fixes. A before/target pair (current state plus a mockup or competitor shot) makes the reference the bar to beat; see "Beating a reference image" in Phase 3 |
| `--pr` | `gh pr diff --name-only`, redesign every UI file in it. Needs gh (`repo-profile.md` §2); unavailable falls back to `--diff` |
| `--diff` | `git diff --name-only` for staged and unstaged UI files |

---

## Quality floor

These hold on every run whatever the Design Brief decides. They govern how well a choice is executed, not which choice is made.

| Keyword | Meaning in code |
|---------|-----------------|
| Refined | Consistent radius, even icon sizes, text overflow handled, no off-scale spacing |
| Harmonious | The committed direction is applied everywhere with no one-off islands; type, spacing, and sizes follow one modular scale |
| Modern | No dated patterns (bordered tables, stateless flat buttons); whitespace used well |
| Elegant | Clear hierarchy, low noise, a visible primary/ghost/link button hierarchy |
| Deep | Clear elevation tiers with a consistent light source; flat only when the Elevation decision chose flat |
| True to the brief | A half-committed version of either direction reads as sloppy, so execute the brief fully |
| Accessible | Labels clear, important icons have tooltips, empty/loading/error states present |
| Efficient | Fewer clicks: bulk actions, inline edit, safe smart defaults |

The Design Brief is the contract. Do not make the result bolder or more conservative than it committed to, because drifting toward personal habit is the main way output turns generic.

---

## Workflow: Scope → Brief → Audit → Fix → Verify

### Phase 0: Scope and read

1. Parse the input mode. For a URL or localhost target, screenshot immediately with whatever browser tool exists; none available means ask the user to paste one.
2. `--pr`: resolve the VCS profile per `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (absent: assume full gh mode). Degraded mode: print the §2 message, then ask for a branch name or fall back to `--diff`.
3. Project Profile: use `.vdesign/profile.md` at the git root (`git rev-parse --show-toplevel`) if present. Otherwise infer the UI library and design tokens from `package.json`, `tailwind.config.*`, and the components folder. Still ambiguous: ask one question and offer to save the answer to `.vdesign/profile.md`.
4. **Real User & Purpose read.** Read the real data shape feeding the target: prop types, the query/hook/server action it calls, and the response type or Zod schema (read the type; rendered output hides unused fields). When the DB schema file is reachable, note fields that are never fetched; Phase 2's sparse check uses them. Then take the persona's view (role, task goal, time pressure, device, skill level) inferred from the route name and the profile context. State which field or action must stand out, what is noise, and whether the current structure (table, card grid, kanban, timeline, master-detail, bento, calendar, comparison matrix, tree, feed, or whatever the data and task call for) fits that persona.
5. This read is the only gate on structural freedom: restructure whenever it serves the real task, and trace every restructure to a concrete reason stated here. Record the persona, the task, and 2-3 information-architecture decisions in `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md`.

---

### Phase 1: Research, Brief, and scan

The Design Brief depends on Phase 0's read and on the research below, so both come first. Never pick patterns before the brief is written, because the result is a grab-bag instead of a design.

**Domain Research.** Slug = domain from the profile + target feature (e.g. `healthcare-booking-form`).

- Scale the aspects to the target, because broad fan-out on a small target costs far more than it returns:
  - Single component or a PR diff of 3 files or fewer: `ui`, `ux`.
  - One page or feature (default): add `animation`, `layout`, `text`.
  - Whole multi-cluster page or a whole flow: add `3d` (only if the brief might use spatial depth), `features`, `flow`. The last two are informational context and never expand the redesign scope.
- Reuse per aspect: a `plans/reports/researcher-vdesign-bold-<slug>-<aspect>*.md` from this session or today counts as a hit.
- Spawn one subagent per missed aspect, all in one message. Each brief must give: the aspect and target feature in its domain; the goal (current named patterns, not generic advice); the sources (curated or judged galleries and real studio case studies such as Awwwards, CSS Design Awards, Site Inspire, Behance/Dribbble Featured; for a Game-inspired brief, game-UI galleries instead); the output (named patterns with real source URLs, saved to `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`); and the boundary (research only, no code edits, no proposing scope for `features`/`flow`).
- Top-hit study, done by you because subagents have no browser: if browser automation exists, open the 1-3 best source URLs, screenshot for composition and hierarchy, and read `getComputedStyle()` on 1-2 standout elements (box-shadow, radius, color, transition). Computed values survive minified CSS. No browser tool means skip this; the text reports are the floor.
- A failed aspect retries once, then is marked "unavailable" in the brief and replaced by the profile plus the quality floor. It never falls back to a memorized pattern list.

**Design Brief.** Decide all 18 criteria using the priority order in `references/aesthetic-customization.md` (Domain Research, then Project Profile, then the Real User & Purpose read, then the quality floor). Then write a concrete 5-10 line brief: real typeface names, palette approach, motion timing, shape/icon/imagery direction, spacing scale, layout system, tone, boldness level. A one-word label per criterion is not a brief. Save the 18 decisions and the brief to the same `vdesign-brief-<slug>-<HHMMSS>.md`, with the status per aspect (cached, fresh, skipped by size, unavailable). Phase 3 re-reads this file instead of trusting conversation memory.

**Component tree.** Trace it, not just one file:

```
Target component/page
  └── local components (level 1) → read
        └── local sub-components (level 2) → read
              └── stop at UI library components (the project's own UI package, shadcn, MUI, Radix)
```

For each file note the classes in use, whether library components use the right variant, the layout pattern, existing motion, and which of loading, empty, error, hover, focus, active, disabled exist. Also read the design tokens (`tailwind.config`, `globals.css`) and a good reference component (the profile's "Good reference UI" entry, else the most polished component in the codebase).

When the user says "like X", read X first, because guessing its pattern produces a near-miss.

**Component Inventory** (only for a whole page or URL with 2 or more component clusters): list every visible instance as a numbered checkbox (three stat cards are three items) and group adjacent same-role instances into clusters. Append it to the brief file under `## Component Inventory`. Phase 3 picks its pilot from it and Phase 4 checks every box.

---

### Phase 2: Audit

Read `references/audit-checklist.md` in full and go through each category. Flag only issues that affect visual or UX quality. Append the findings (checked, flagged, and the content-density candidates) to the brief file under `## Audit Findings`; when an inventory exists, tag each finding with its cluster.

---

### Phase 3: Fix

Fix everything Phase 2 found. Spacing, states, component swaps, layout restructures, and full visual-direction changes are all in scope. Keep depth proportional: a spacing-only finding does not license a JSX rewrite. The exception is a generic layout where every section is the same box regardless of content; that is itself a structural finding, so restructure it to fit the content. Structural moves follow the Phase 0 read, not the proportional bound.

**Pilot first (only when an inventory exists).** A single component or PR diff skips this and is fixed once.
1. Take the cluster with the most findings (ties: first in the inventory) and redesign it at full depth.
2. Present it before touching anything else: URL targets get a before/after screenshot, others get a concrete description plus the pilot's diff. Ask via `AskUserQuestion`: approve, adjust, or try another direction. Cap at 3 cycles, then ask whether to approve with the noted disagreement or stop.
3. After approval, propagate the same design language (color, elevation, radius, spacing scale, motion; not literal values) to the rest, checking each box. A table stays a table, restyled, not forced into the pilot's shape.

**Execute the brief.** A bold brief (Experimental or Trend-forward) warrants bespoke typography scale, asymmetric layout, custom motion, and expressive completion moments; a restrained brief (Brand-centric or Functional) stays close to the existing system. Restrained still means the full audit drives restyling: a component with zero bugs can still fail hierarchy or depth checks. Usability principles (all states present, visible-choice limits, confirm only destructive actions) are a floor boldness must clear.

**One signature element.** When the brief is bold, commit to one move (a color discipline, a typeface, a motion language, an illustration style, or an asymmetric layout gesture) and keep the rest restrained around it. Boldness spread thin reads more generic than one committed move, and it must be structural (scale, contrast, motion that clarifies), never purely decorative. A CSS/SVG grain overlay under 10% opacity is a no-dependency texture option.

**Pull patterns only from this run's research reports** (`ui`, `ux`, `animation`, `layout`, `3d`, `text`). `features` and `flow` informed the brief and are not pattern sources.

**Beating a reference image.** Match its devices first (grouping, color tiers, iconography, layout moves), then exceed it where a static image cannot compete: consistency across the whole flow, real motion, measured spacing and contrast, and real responsiveness and accessibility.

**Mid-run revisit.** If execution shows one decision no longer fits (e.g. *Keep existing tokens* but a real gap needs an accent), re-decide just that criterion by the same priority, update its line in the brief file, continue, and list it in the final report.

**Dependencies.** Check `package.json` first. Motion libraries that are standard for this kind of work (GSAP with ScrollTrigger, Motion, Lenis, native scroll-driven animations and View Transitions, Rive, Lottie) fit an *Expressive* or *Balanced* motion decision. Three.js/React Three Fiber (650KB+), Barba.js, paid tools, and custom shaders need the user's approval because of their weight or cost. If the project's own instructions (e.g. its CLAUDE.md) require asking before any new dependency, that rule wins: ask once for the whole set.

**Anti-slop gate.** Applies on every run, because a restrained brief means restrained, not generic. Fail the run on: Inter/Roboto as the only typeface, a purple-to-blue gradient as the dominant look, 3 or more identical cards in a row, placeholder names or round numbers ("John Doe", 50%, $100), generic startup copy ("Elevate", "Seamless", "Next-Gen"), a pure `#000000` background, missing hover/focus states, and unmodified stock flat illustration (unDraw, Storyset, DrawKit, Blush, Icons8 Ouch, ManyPixels, Open Peeps). Illustration preference, best first: custom hand-drawn, line-art, isometric 3D, heavily customized flat, geometric/abstract, none. A single small (32px or less) custom line or duotone icon placed with intent is not slop.

**Hard rules**, each with its reason:
- Work in the existing stack; a framework migration is out of scope.
- DB schema and migrations stay off-limits. API/service changes are allowed when the redesign needs them.
- Content exposure gets one batched confirmation: compile the unrendered or never-fetched fields from Phase 0 and Phase 2 into one `AskUserQuestion` ("wire up these N fields: all / some / none"), then implement the accepted ones end to end. It is a data decision, not an aesthetic one, so it needs a yes even though style does not.
- Hide with opacity/visibility, not unmount, so component state survives.
- Use design tokens, not hardcoded hex, so theming keeps working. New brand colors only when the Color decision is *Accent only*, *Full palette*, or *Dynamic*, and never the library's default color (e.g. shadcn blue) when the project has its own primary.
- Use the profile's "Good reference UI" as the standard when the brief is Brand-centric.
- Write mobile-first and override with `sm:`/`lg:`; responsiveness is verified in Phase 4.
- Wrapper around a third-party styled component: the wrapper owns every visual state (border, ring, disabled opacity); null out the inner border and shadow with a CSS-variable override.
- Prefer native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) over ARIA. Add `role`/`aria-*` only when native cannot express it, and then the full role, state, and property set, because partial ARIA is worse than none.
- Animate only `transform` and `opacity` (never width, height, top, left), so motion stays GPU-composited and mobile LCP stays inside budget.
- Add a toast only when it is a deliberate completion moment; the bar is intent, not minimalism.
- Accessibility (contrast, focus rings, all states) is never traded for style.

---

### Phase 4: Verify

1. **Viewports (375, 768, 1280px).** For every layout change, load the route at each width (browser tool resize or `page.setViewportSize` in Playwright), screenshot, and run this check; any overflow or clipped content returns to Phase 3:
   ```js
   [...document.querySelectorAll('body *')].filter(e => e.getBoundingClientRect().right > innerWidth + 1).slice(0, 5)
   ```
   An empty list plus `document.documentElement.scrollWidth <= innerWidth` means no horizontal overflow; then check by eye that nothing is clipped, stacked wrongly, or below 44px as a touch target. A component target with no route: render it where the project previews components. No browser or runnable page: say that viewport verification was not done, name the widths, and do not report it as verified.
2. URL target: compare the before and after screenshots at 1280px. Image input: confirm the code matches the image's intent.
3. Run the project's format script and its typecheck or lint if it has them, and fix what the redesign broke.
4. **Accessibility.** If `@axe-core/playwright` or `axe-core` is present (or the user allows adding it), run it against the route and print violations. Otherwise print the manual-check steps for the user, since visual review alone does not verify accessibility.
5. **Adversarial verify**, only when the fix touched structure (component swap, layout restructure, direction change), the brief was bold, or UX-logic fixes touched interaction state. Spawn one fresh subagent with the diff, `references/audit-checklist.md`, and the anti-slop gate, read-only, and no access to your reasoning. It returns PASS or a list of remaining issues, over-reaching fixes, and slop violations. Save its report to `plans/reports/vdesign-adversarial-<slug>-<HHMMSS>.md`. Fix and re-run once if it finds issues.
6. **Self-check** (inline): fix depth was proportional; every applicable audit category was addressed or marked not applicable; the anti-slop gate was actually checked; the result matches the committed brief; every inventory box is checked or marked not applicable with one reason.
7. **Content-exposure confirmation**, only if candidates were flagged: ask the single batched question from the Hard rules, then wire the accepted fields through the API and UI before reporting.
8. **Short report**: "Redesigned [X]. Main changes:" with 3-5 bullets, then one line with the committed brief (boldness level and the 1-2 criteria that shaped it), the research status per aspect, the viewport result, and the adversarial outcome when it ran. List every mid-run revisit and anything not verified.

Next.js note: an image overwritten at the same path under `public/` may still show the old version because the optimizer caches by URL and size. Hard-refresh or clear `.next/cache/images` before editing again.

---

## Project Profile

Resolution order is in Phase 0. A profile is a short table of constraints; a typical shape:

| Constraint | Detail |
|------------|--------|
| UI library | The project's own UI package plus shadcn/ui; use it before raw HTML |
| Design tokens | CSS variables in `globals.css`; no new colors |
| Motion library | e.g. Framer Motion already installed |
| Context | e.g. B2B healthcare: clarity over impressiveness |
| Good reference UI | Two or three well-built screens to learn patterns from |
| Form fields | Use the project's form wrappers, not raw boilerplate |

## Pitfalls beyond the audit checklist

- Rewriting the whole layout when one part needed a tweak; it hides the real change and risks regressions.
- Line-clamping varied-length copy in parallel cards; rebalancing the copy is the root fix for uneven cards.
- Changing structure or adding a field with no link to the Phase 0 read; creative freedom is not license for arbitrariness.
- Writing code before the brief exists; patterns picked first produce a grab-bag.
- Re-running research for an aspect already cached for the same slug; it wastes subagents.
- Reporting done without a screenshot when a URL was available.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
