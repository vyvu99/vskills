---
name: vdesign
description: "Redesign existing UI/UX with high execution quality: refined, harmonious, modern, elegant, accessible. Every run opens by asking the user to pick 18 explicit style/structure criteria (typography, color, motion, layout, structural freedom, boldness, and more), instead of a flag deciding how bold or conservative the result is. Use when upgrading the UI of an existing page/component/feature/PR."
user-invocable: true
when_to_use: "Invoke when you want to redesign or upgrade the UI/UX of a page, component, feature, or an entire existing diff/PR."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]]"
metadata:
  author: vyvu
  version: "8.2.0"
---

# vdesign — Personal UI/UX Redesign Skill

Upgrade or redesign UI/UX to a high standard of execution quality — **refined · harmonious · modern · elegant · accessible** — while the actual style (bold or restrained, matching the existing system or deliberately departing from it) is picked explicitly by the user each run, not assumed.

No depth-level flags, no `--wow` toggle. `vdesign <target>` is the only mode — audit-driven: fixes everything Phase 2 finds, regardless of depth (spacing → structural → visual-direction change). Every run opens with Phase 0's Aesthetic Customization, where the user explicitly picks 18 style/structure criteria (typography, color, motion, shape, layout, structural freedom, boldness, and more — see `references/aesthetic-customization.md`) instead of a flag silently unlocking or restraining creativity. No artificial ceiling, no "found it but can't fix it, wrong level" outcome.

Do not change the tech stack. Do not break logic/state/API.

---

## Input Modes (7 types)

| Input | Handling |
|-------|------------|
| _(empty)_ | Ask the user 1 question: "Which part do you want to redesign?" |
| `localhost:PORT/path` or URL | Take a screenshot first → then read the corresponding source files |
| Route path (e.g. `/clients/[id]?tab=notes`) | Resolve to the corresponding pages/components files |
| Component/feature name (e.g. `TreatmentPlanWizard`) | Grep to find the file → read the entire component tree |
| `[Image]` / attached screenshot | Analyze the image → extract design gaps → apply fixes. If multiple images form a before/target pair (current state + an aspirational reference — a mockup, competitor screenshot, or AI-generated concept) → treat the reference as the bar to reach, not just inspiration; see "Beating a reference image" in Phase 3 |
| `--pr` | `gh pr diff` to get changed files → redesign all UI files in it (requires gh, §2 of `repo-profile.md`; unavailable → falls back to `--diff`) |
| `--diff` | `git diff --name-only` to get staged/unstaged → redesign UI files |

---

## Personal Aesthetic (Quality Floor)

This is the user's vocabulary for execution quality — **ALL** of these hold on every run, regardless of what Phase 0's Aesthetic Customization picks. They govern *how well* a choice is executed, not *which* choice gets made:

| Keyword | Practical meaning in code |
|---------|--------------------------|
| **Refined** | Micro-details in the right place: consistent border-radius, even icon sizes, text-overflow handled, no odd spacing scale values |
| **Harmonious** | Whatever direction Phase 0 committed to (matching the existing system or deliberately departing from it) is applied consistently — no "isolated island" of one-off styling within that direction; font-size/spacing/component-size follow a consistent modular scale/ratio, not arbitrary values |
| **Modern** | No outdated patterns (old-style bordered tables, old-style form labels, flat buttons with no state); makes good use of whitespace |
| **Elegant** | Clear hierarchy, low visual noise, no unnecessary decoration, clearly distinguished button hierarchy (primary/ghost/link) |
| **Deep** | Clear elevation tiers, consistent shadow/border/light-source — never flat-and-lifeless, never skeuomorphic (unless the Elevation & Shadow criterion explicitly picked flat/monochromatic — then consistently flat, not accidentally so) |
| **True to the Design Brief** | Matches whatever Phase 0's Aesthetic Customization committed to — design tokens and the project's existing visual language when that's what was picked, a deliberately new direction when that's what was picked. Executing a half-committed version of either reads as sloppy, not tasteful |
| **Accessible** | Information isn't hidden; labels are clear; important icons have tooltips; empty/loading/error states are all present |
| **Efficient** | Minimizes clicks/steps: bulk actions, inline-edit, smart defaults where safe |

**DO NOT** apply a bolder or more conservative aesthetic than Phase 0's Aesthetic Customization actually committed to — the Design Brief is the contract, not a suggestion to override toward personal habit in either direction.

---

## Workflow: Scan → Audit → Fix → Verify

### Phase 0: Determine scope

1. Parse the argument to determine the input mode (see table above)
2. URL/localhost → **take a screenshot immediately** using whatever screenshot tool is available (Playwright MCP, browser tool, etc.); none available → ask the user to paste a screenshot directly
3. `--pr` → resolve the VCS profile per `~/.claude/skills/_vskills-shared/repo-profile.md` §2 first (absent → assume full gh mode, today's default). Full gh mode → `gh pr diff --name-only` to get the file list. Degraded (no gh / non-GitHub) → print the §2 message and ask for a branch name, or fall back to `--diff` (`git diff --name-only`, needs no gh) — then continue into Phase 1 normally.
4. Resolve the Project Profile: check `.vdesign/profile.md` at the target project's git root (`git rev-parse --show-toplevel`). Present → read and use it. Absent → infer UI library/design tokens from `package.json` dependencies, `tailwind.config.*`, and the components folder. Still ambiguous → ask 1 question, then offer (don't force) to save the answer to `.vdesign/profile.md` for next time.
5. Empty → ask the user via `AskUserQuestion` — **exactly 1 question**
6. **Aesthetic Customization** — always, every run, no flag: read `references/aesthetic-customization.md` in full and run its 7 `AskUserQuestion` rounds (Round 0's structural freedom + Rounds 1-5's 17 style criteria — typography, color, motion, elevation, background, shape, icon, imagery, spacing, grid, layout columns, dark mode, brand tone, overall boldness, data/table density, form/input style, empty/loading/error state style — plus Round 6's closing catch-all question). The user picks explicitly, per run; the agent never infers a direction silently.
7. **Domain Research** — conditional, only when step 6's Aesthetic Boldness criterion answered *Trend-forward*, *Experimental/bold*, or *Game-inspired/Arcade*, or another answer explicitly invoked current real-world trends; *Brand-centric* and *Functional/minimalist* skip straight to step 8:
   - Domain slug = the domain from the Project Profile's context (e.g. "B2B Healthcare") + the target feature/page name resolved in step 1 (e.g. "booking form") — slugify (e.g. `healthcare-booking-form`)
   - Criterion 14 = *Game-inspired/Arcade* → shift source priority toward game-UI-specific galleries (Dribbble tag "game UI", GameUIDatabase.com, Behance HUD design) over Awwwards — its Game category is thin compared to its usual categories
   - Aspect list is fixed, always these 8: `ui` (UI/Visual), `ux` (UX/Interaction), `animation` (Animation/Motion), `layout` (Layout/Responsive), `3d` (3D/WebGL/spatial-depth patterns), `text` (Typography/microcopy/tone-of-voice patterns), `features` (competitor/domain feature patterns for the target feature — informational only, never expands redesign scope), `flow` (competitor/domain user-journey patterns for the target feature — informational only, never expands redesign scope)
   - Cache check per aspect, independently: look in `plans/reports/` for `researcher-vdesign-bold-<slug>-<aspect>*.md` created earlier this session/today — hit → reuse that aspect's report; miss → mark for fresh research
   - Spawn all cache-missed aspects in parallel — one Task/Agent call per aspect, up to 8, in the same message. Design-pattern aspects (`ui`/`ux`/`animation`/`layout`/`3d`/`text`) each find current (2025-2026) patterns specific to `<target feature>` in `<domain>` product context, scoped to their one assigned aspect — actively pull from real award-winning galleries (Awwwards Site/Mobile/Developer of the Day and Honorable Mentions, filtered by category matching `<domain>` where the gallery supports it; CSS Design Awards and Site Inspire as alternates when Awwwards has thin coverage for the domain) rather than only reciting abstract pattern descriptions; report concrete named patterns **with real source URLs** (the specific site/page studied, not just a pattern name). `features`/`flow` agents instead find current competitor/domain feature or flow patterns for `<target feature>` in `<domain>` — framed explicitly as context only, NOT scope to implement; the agent must not propose adding these to the redesign. Save each to `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
   - **Visual/technical study of top hits (orchestrator-level, not the research subagent — it has no browser tool):** after Domain Research reports back, browser automation (e.g. `claude-in-chrome`) available → open the 1-3 highest-value source URLs and (a) screenshot for overall gestalt (composition, color harmony, hierarchy — judgment a bullet list can't convey) and (b) run `getComputedStyle()` via the browser's JS-execution tool on 1-2 standout elements to extract real, exact design-token values (box-shadow, border-radius, color, transition-duration/easing) — computed values are unaffected by minified/obfuscated production CSS, unlike a site's raw downloaded stylesheet, usually illegible (hashed utility classes, no structure) and not worth fetching. Merge these values into Phase 3's pattern-pull. Browser automation unavailable → step skipped — Domain Research's text-based pattern-plus-source-URL reporting is still the floor, not optional.
   - An aspect whose agent fails or is unavailable: `ui`/`ux`/`animation`/`layout`/`text` fall back silently to their matching static catalog section (Cards and Containers / Micro-Interactions / Scroll Animations / Layout and Grids / Typography and Text in `premium-design-patterns.md` — or, when criterion 14 is *Game-inspired/Arcade*, the matching section of `references/game-inspired-arcade-patterns.md` instead); `3d`/`features`/`flow` have no static catalog to fall back to — simply absent from downstream steps, noted "unavailable" (not "fallback"). The other aspects (cached, freshly researched, or fallback) still proceed; never fail the whole domain-research step because one aspect failed
8. **Design Brief** — before touching any code: synthesize step 6's 18 answers plus its Round 6 catch-all note, plus step 7's findings when it ran, into a concrete 5-10 line brief (see `references/aesthetic-customization.md`'s Design Brief section) — actual typeface names, actual palette approach, actual motion timing, actual shape/icon/imagery direction, actual spacing scale, actual layout system, actual tone, actual boldness level. A one-word label per criterion is not a brief. State it out loud, write the 18 answers + the synthesized Design Brief to `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` before Phase 1 starts, noting step 7's status if it ran (cached/fresh/fallback/unavailable/skipped). Phase 3 re-reads this file before executing, rather than relying on conversation memory. An un-synthesized run (18 raw answers, no committed brief) is the single biggest reason output still reads as generic/safe.

---

### Phase 1: Scan

**Step 1 — Data & Purpose:** before tracing any component, read the actual data shape feeding this page/component — its prop types/interfaces, the query/hook/server action it calls, and that call's response type or Zod schema (read the type, don't infer field shape from what's currently rendered). From that plus the route/component name and surrounding context, state in 1-2 sentences: what task is the user accomplishing here, and which fields actually matter for it. This grounds every layout/IA call in Phase 2/3 — whether the current view type (table, card grid, list, detail panel, form, kanban board, timeline, masonry/bento grid, split master-detail, calendar/heatmap, comparison matrix, tree/outline, carousel/feed — and more, pick by what the data structure and task actually call for) structurally fits this data and task, not just whether it looks polished. An un-grounded audit still risks polishing the wrong structure.

**Step 2 — Component Tree Traversal:** trace the component tree — not just read 1 file:

```
Target component/page
  └── Import local components (level 1) → read
        └── Import local sub-components (level 2) → read
              └── Stop at UI library components (@etaro/ui, shadcn, MUI, Radix)
```

For each file read, identify:
- Tailwind classes currently used (spacing, color, typography)
- Components from the UI library: using the right variant? already customized?
- Layout pattern: flex/grid/absolute positioning
- Existing animation/transition
- Existing states: loading, empty, error, hover, focus, active, disabled

**Also gather:**
- `tailwind.config` or CSS vars (`globals.css`) → design tokens
- Find a component in the project that serves as a **good reference** — check the Project Profile's "Good reference UI" entry first (see Project Profile section below); absent → infer from the most polished/consistent-looking component in the codebase → read it to learn the pattern

**Step 3 — When the user says "like X" or "similar to X":**
→ MUST read component/page X first before implementing — do not guess the pattern

**Step 4 — Component Inventory (only when the target is a whole page/URL with 2+ component clusters; skip for a single-component or PR-diff target — those keep the existing single-pass Fix flow in Phase 3):** enumerate every visible component INSTANCE on the page as a numbered list — not just types (3 stat cards are 3 separate line items, not 1 "stat card" entry). Group instances adjacent in the render tree that share a visual/structural role into clusters (e.g. 3 stat cards in a row = 1 cluster; the data table below them = a separate cluster; the nav = its own cluster). Write this list, with a checkbox per instance, to `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` under a new `## Component Inventory` section — Phase 3 picks its pilot cluster from here, Phase 4 verifies every checkbox got addressed before reporting done.

---

### Phase 2: Audit

Read `references/audit-checklist.md` in full and go through each category — only flag issues that **actually affect visual/UX quality**. That file also covers the framework-conditional syntax note (Tailwind/React shorthand throughout is illustrative, translate to the project's actual stack).

<!-- The full ~100-item checklist (Typography through Sticky & Scroll Behavior) lives in references/audit-checklist.md — kept out of this file to keep the skill body lean. -->

Write the full findings list (checked/flagged items, plus the content-density candidate list) to the same `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` file (append a `## Audit Findings` section) before Phase 3 starts. When Phase 1's Component Inventory ran, tag each finding with the cluster(s) it belongs to (from the inventory list) so Phase 3 can identify which cluster carries the most findings.

---

### Phase 3: Fix

**Pilot cluster first, then propagate (only when Phase 1's Component Inventory ran — target is a whole page/URL with 2+ clusters). A single-component or PR-diff target has no Component Inventory — skip straight to "Fix everything Phase 2 found" below, applied once across the whole target, no pilot step.**

1. Pick the cluster tagged with the most Phase 2 findings as the pilot — ties broken by whichever appears first in the Component Inventory list.
2. Redesign the pilot cluster at full depth — everything below in this Phase 3 section (Design Brief execution, boldness patterns, hard rules, anti-slop gate) applies to it in full.
3. Present the pilot for approval before touching any other component in the inventory: URL/localhost target → screenshot, show before/after; otherwise describe the treatment in concrete terms (colors, spacing, motion) and show the code diff for the pilot cluster only. Ask via `AskUserQuestion`: approve / adjust (user describes what to change) / try a different direction.
4. On adjust or a different direction: redo the pilot with that feedback, re-present. Cap at 3 cycles (mirrors `vreview`'s review-cycle max) — past 3, ask "approve with the noted disagreement, or stop the run."
5. Once approved: propagate the SAME design language (color, elevation, radius, spacing scale, motion — not literal copied values) to every remaining item in the Component Inventory, checking each off as done. A component of a different type than the pilot keeps its own correct pattern (a table stays a table, a form stays a form) restyled to match the language, not forced into the pilot's literal shape.
6. Update the Component Inventory checkboxes in `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` as each item completes — Phase 4 verifies against this.

**Mid-run criterion revisit.** Phase 3 execution reveals one of Phase 0's criterion answers no longer fits (e.g., committed to *Keep existing tokens* but a real gap now calls for a new accent color) → do not restart the full Aesthetic Customization. Ask exactly one `AskUserQuestion` re-covering just that criterion (same options, current answer marked distinctly), update the Design Brief file's synthesis line for that criterion only, continue Phase 3 from where it left off. Cap at 3 revisits per run (mirrors the pilot-cluster adjust cap above) — past 3, ask the user: lock the current Design Brief and proceed, or stop the run to re-plan.

Fix everything Phase 2 found — spacing, states, component swaps, grid/layout restructure, and full visual-direction changes are all in scope by default; no depth ceiling to stay under. Depth should still be *proportional* to what's actually broken: a spacing-only audit finding does not license a full JSX rewrite (see Anti-Patterns — "rewrite the entire layout when only a tweak was needed"). This cuts both ways — a genuinely generic/repetitive layout (every section rendered as the same box regardless of what it actually holds or does) is itself a structural-level finding (Information Architecture's view-type fit, Proportion & Scale Harmony's silent-drift check), not a shape to preserve out of caution; restructuring so each section fits its real content is the *proportional* fix there, not an unrequested rewrite. Structural/view-type changes specifically follow Round 0's Structural Freedom answer: *Preserve structure* forbids them this run regardless of what the audit finds; *Refine if audit finds a fit problem* keeps the proportional bound above; *Open to reinvention* lifts that bound for structural moves only.

**Execute the Design Brief.** Phase 0 step 8's Design Brief — not a flag — decides how bold or restrained this run is. Criterion 14 (Aesthetic Boldness) is *Experimental/bold* or *Trend-forward* → bespoke art direction, expressive typography scale, unique/asymmetric layout, custom motion, decorative accents (icon anchors, tinted sub-cards — see `references/quiet-polish-patterns.md`), expressive selection/completion/feedback moments (see that file's Motion & Interaction section) are all warranted — a genuinely delightful transition or a celebratory completion moment is not "unnecessary," it's what was asked for. Criterion 14 is *Brand-centric/cohesive* or *Functional/minimalist* → stay restrained and close to the existing system, per the other 17 answers. Restrained does not mean audit-fix-only — Phase 2's full checklist (typography hierarchy, elevation/depth, proportion & scale harmony, redundant/dated content) still drives Phase 3 on every component in scope, just executed without the bold pattern catalog's decorative moves; a component with zero functional bugs can still fail these checks and need restyling. Either way, what stays as a floor, not a cap: Phase 2's usability principles (all required states present, Hick's Law visible-choice limits, confirm-only-destructive-actions) — boldness must still clear them, not bypass them. Off-limits entirely, regardless of the brief: the hard technical rules below (accessibility, tech stack, logic/API, GPU-safe motion) — safety/engineering constraints, not aesthetic choices, no criterion answer touches them.

**Beating a reference image, not just matching it.** Input includes a reference/target image (an aspirational mockup, competitor screenshot, or AI-generated concept — see Input Modes) rather than only a "before" screenshot to fix → treat it as the bar to clear, then exceed it on the axes a static image structurally cannot compete on: consistency across every screen in the same flow (not just the one shown), real motion/interaction (a static image is frozen — see quiet-polish-patterns.md's Motion & Interaction section), measurable precision (exact spacing-grid/contrast-ratio conformance — a static mockup often has small unmeasured misalignments a real implementation shouldn't repeat), and real responsiveness/accessibility (the mockup only had to look good at one fixed size). Match its specific devices first (grouping, color tiers, iconography, layout moves), then win on these axes — don't stop at parity.

Requires the Design Brief from Phase 0 step 8 first — commit the brief, then pull patterns. Never pull patterns first and rationalize a brief after the fact.

**When the brief calls for boldness: one signature element, not scattered boldness.** Commit to ONE bold move — a color discipline, a custom typeface, a motion language, an illustration style, or an asymmetric layout gesture — and keep everything else restrained around it. Half-committed boldness (a little bit of everything) reads *more* generic than full commitment to one thing; the #1 reason bold output has read as safe in practice. Boldness must be **structural** (typography scale, contrast, motion-as-clarity, custom voice), never purely decorative.

When the brief calls for boldness, pull from these 6 named patterns (award-winning, execution-proven, not portfolio/consumer noise):

| Pattern | How it works | Why it reads as intentional, not reckless |
|---|---|---|
| Strategic Accent Boldness | Neutral baseline + 1-2 committed bold focal points | Clarity stays primary; boldness reads intentional |
| Authentic Voice + Human Craft | Custom photography/illustration, genuine copy, anti-stock | Authenticity signals credibility, not decoration |
| Bold Typography-First | Oversized custom/variable type; hierarchy via size/weight alone | Boldness lives in the skeleton, not ornament |
| High-Contrast Disciplined | Black/white or deep saturation, thick lines, no gradient/blur | Directness reads confident, not reckless |
| Motion-First Clarity | Every animation clarifies (state change, hierarchy); 1-2 sophisticated interactions per page max | Motion signals sophistication, doesn't distract |
| Product-Centric Hero | Real product UI/screenshot as the hero, not illustration | Confidence + transparency, not showmanship |

CSS/SVG grain-texture overlay (opacity <10%, `<feTurbulence>` or CSS `filter`) is also available as a texture technique when the brief calls for it — no dependency needed.

**Pattern-pull, not audit-fix, when the brief calls for boldness.** Once the Design Brief is committed, pull from the 6 patterns above plus its own arsenal — `~/.claude/skills/frontend-design/references/premium-design-patterns.md` exists → read it for the full catalog (navigation, layout, card, scroll-driven animation, kinetic typography, micro-interaction patterns); absent → use `references/anti-slop-minimum.md`'s archetype patterns instead. **Always also read `references/quiet-polish-patterns.md`** — a restrained tier (tinted sub-cards, icon anchors, eyebrow tags, radio-cards) for when the brief calls for warmth/refinement rather than boldness; a permanent supplement merged in addition to the catalog above, not a fallback for when it's missing. **Criterion 14 is *Game-inspired/Arcade* → also read `references/game-inspired-arcade-patterns.md`** — conditional on that specific boldness answer, unlike the always-merged quiet-polish tier — plus any domain-specific patterns/insights from whichever of Phase 0 step 7's design-pattern aspect reports exist for this run (`ui`/`ux`/`animation`/`layout`/`3d`/`text`, up to 6 — `features`/`flow` reports excluded here, informational-only for the Design Brief, not pattern-pull material). Merge all, don't replace the catalog. Phase 2's audit always runs in full — covers visual hierarchy, proportion, elevation, and content harmony, not just broken states/a11y/responsive; when the brief is bold it's a floor, not a ceiling on top of that — output is judged by how distinctive the ONE committed signature element is, not just absence of defects.

**Dependency allowlist — add directly, no need to ask, when the Motion/Animation criterion is *Expressive* or *Balanced*:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), native CSS scroll-driven animations / View Transitions API, Rive, Lottie — the de-facto standard toolkit on 2025-2026 award-winning sites.
**Still stop-and-ask, regardless of the brief:** React Three Fiber/Three.js (650KB+ — only if 3D is genuinely core to the concept), Barba.js, any paid/SaaS tool beyond Rive, custom WebGL/GLSL shaders.

**Anti-slop gate before reporting done — every run, regardless of the brief** (a *Functional/minimalist* pick means restrained, not generic): `~/.claude/skills/frontend-design/references/anti-slop-rules.md` exists → read it for the full checklist; absent → use `references/anti-slop-minimum.md`'s fail conditions instead. At minimum fail the run on: Inter/Roboto as the only typeface, purple-to-blue gradient as the dominant aesthetic, 3+ visually-identical cards in a row, placeholder names/numbers ("John Doe", round 50%/$100), generic startup copy ("Elevate", "Seamless", "Next-Gen"), pure `#000000` background, missing hover/focus states, **unmodified stock flat illustration** (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps without custom palette/poses — same tier as purple-gradient; fix by tier: custom hand-drawn > line-art/sketch > isometric 3D > heavily-customized flat > geometric/abstract > skip illustration). **Exception — not slop**: a single small (≤32px) custom line/duotone icon placed with clear intent as a decorative anchor (e.g. beside a title) is NOT a stock illustration scene, and is encouraged, not flagged — see the Icon Anchor pattern in `references/quiet-polish-patterns.md`.

Still mandatory regardless of the brief: accessibility (contrast, focus rings, all required states), no tech-stack migration, no logic/state/API changes, GPU-safe motion only (`transform`/`opacity` — never animate `width`/`height`/`top`/`left`; mobile LCP is already tight, bold must not blow the budget).

**Hard rules (apply to every run, regardless of the brief):**
- ✅ Work with the existing tech stack — DO NOT migrate framework
- ✅ DO NOT break logic/state/API — only change the presentation layer
- ✅ Exception: UX Efficiency and Content Design & Error Prevention category fixes (Phase 2) may touch frontend interaction state/hooks/localStorage — see the scope carve-out under UX Efficiency. Still no backend/API/data-model changes.
- ✅ **Content-density proposals are never auto-applied, in any mode**: the Information Architecture "sparse/under-filled" check (Phase 2) flags real unrendered data worth surfacing → compile it as a short list of concrete, specific suggestions (field name + where it'd go — never invented/placeholder data), present via `AskUserQuestion` at Phase 4 for the user to accept/reject per item, before adding anything. A content/product decision, not an aesthetic one — stays a proposal regardless of the brief.
- ✅ Check `package.json` before adding a dependency — except the dependency allowlist above, addable directly when the Motion criterion calls for it
- ✅ When hiding (not deleting) → use opacity/visibility, don't unmount
- ✅ Use Tailwind tokens — no hardcoded hex
- ✅ Use the Project Profile's "Good reference UI" entry as the reference standard when the Aesthetic Boldness criterion is *Brand-centric/cohesive* — absent → the best-looking component already in the project; a *Functional/minimalist*, *Experimental/bold*, or *Trend-forward* pick may depart from it per the Design Brief
- ✅ **Responsive is mandatory**: every layout change MUST be verified at 3 viewports — mobile (375px), tablet (768px), desktop (1280px); write mobile-first, then override with sm:/lg:
- ✅ Third-party styled component (has `import 'lib/*.css'`) wrapped in a wrapper div → wrapper owns ALL visual state (border, ring, disabled opacity); null out all border/shadow inside the component via CSS var override + scoped `!important`
- ✅ **ARIA discipline**: prefer native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) over ARIA. Only add `role`/`aria-*` when native HTML can't express the interaction, and when added, ensure the full role+state+property set is present — never add ARIA attributes "just in case"
- ❌ DO NOT add complex animation if Motion/Framer isn't already in the project — exception: the dependency allowlist above applies when the Motion criterion calls for it
- ❌ DO NOT add new brand colors — only use existing tokens, unless the Color Palette criterion picked *Accent colors only* (new accent) or *Full palette redesign*/*Dynamic* (wholesale new palette)
- ❌ DO NOT use the component library's default color (shadcn blue) if the project has its own primary color
- ❌ DO NOT add unnecessary toast notifications — exception: a deliberate celebratory/completion moment the Design Brief actually calls for is not "unnecessary" — the bar is whether it's deliberate, not whether it's minimal
- ❌ DO NOT change logic/API/state management

---

### Phase 4: Verify

1. Initial URL/localhost → take an after screenshot, compare before/after
2. Image input → verify the code matches the image's intent
3. Run `pnpm format` (if the project has it)
4. **Accessibility verify**: project has (or the user allows adding) `@axe-core/playwright` or plain `axe-core` → run a short script against the audited route/component, print violations. Unavailable → print the equivalent manual-check command for the user to run themselves — visual/manual review should not be the only verification for accessibility.
5. Just edited an image file directly under `public/` (overwritten at the same path, name unchanged) and the user reports "not seeing the change" → don't rush to edit the code/image again; tell the user to hard-refresh or clear `.next/cache/images` + restart the dev server first — Next.js Image Optimizer caches by URL+size, not by file content, so the fix is likely already correct but an old cached version is still being served
6. **Adversarial Verify** (subagent — only when Fix actually touched structural/JSX-level code: component swap, grid/layout restructure, visual-direction change — OR the Design Brief's boldness criterion was *Experimental/bold* or *Trend-forward* — OR UX Efficiency / Content Design & Error Prevention category fixes touched frontend state/interaction logic): spawn 1 fresh subagent with the diff, Phase 2's audit checklist, and the anti-slop gate. It re-audits the final state independently — no access to this run's reasoning — and reports PASS or a list of remaining issues (audit items still broken, fixes that overstepped what was actually needed, anti-slop violations). Issues found → return to Phase 3, fix, re-run this step once. Save its report to `plans/reports/vdesign-adversarial-<slug>-<HHMMSS>.md` before the orchestrator acts on it. Mirrors `vreview`'s Phase 4 Adversarial Pass in this same skill pack.
7. **Self-Check** (inline, every run, no subagent): before writing the short report, confirm — (a) fix depth was proportional to what Phase 2 actually found, no unrequested rewrites beyond that; (b) every applicable Phase 2 category was addressed or explicitly marked not-applicable; (c) the anti-slop gate (including the illustration check) was actually checked off, not just implied; (d) the final result actually matches the Design Brief from Phase 0 step 8, not a quieter or louder version of it; (e) when Phase 1's Component Inventory ran, every item in it is checked off in `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` or explicitly marked not-applicable with a 1-line reason — no silently skipped component.
8. **Content-density proposals** (only if Phase 2's sparse/under-filled check flagged something): read the content-density candidate list from `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md`'s `## Audit Findings` section before asking. Before the short report, present the compiled list via `AskUserQuestion` — one item per real unrendered field/data point found, each independently acceptable/rejectable. Never add any of it to the code without the user's explicit answer here, in any mode.
9. **Short report**: "Redesigned [X]. Main changes: [list 3-5 bullet points]"
   - No long summary
   - Only mention significant changes
   - 1 line stating the committed Design Brief (condensed — boldness level + the 1-2 criteria that most shaped the result), plus Domain Research's status if step 7 ran (cached/fresh/fallback/unavailable), plus Adversarial Verify's PASS/issues-found outcome when it ran

---

## Project Profile

Resolve in this order before Phase 1:
1. `.vdesign/profile.md` at the target project's git root — if present, read and use it directly.
2. Absent → infer from `package.json` dependencies, `tailwind.config.*`, and the components folder.
3. Still ambiguous → ask 1 question, then offer (don't force) to save the answer to `.vdesign/profile.md` for next time.

### Example — eTARO project profile (illustrative shape, not a default)

| Constraint | Detail |
|------------|----------|
| UI library | `@etaro/ui` (packages/ui) + shadcn/ui — always use before writing raw HTML |
| Design tokens | CSS vars in `globals.css` — don't add new colors |
| Motion library | Magic UI + Framer Motion already available — usable for micro-animations |
| Context | B2B Healthcare: **clarity > impressiveness**, **simplicity > creativity** |
| Good reference UI | Booking form, Sessions page, Notes UI — learn patterns from these |
| Font | Follow existing config — don't change |
| Form fields | MUST use `FormTextField`, `FormSelectField`, etc. — no raw boilerplate |

---

## Anti-Patterns (DO NOT do)

- ❌ Rewrite the entire layout when only a "tweak" of one part was needed
- ❌ Add flashy animation when the Motion/Animation criterion picked *Minimal* or *Utilitarian* — GPU-safe motion rules still apply regardless of the criterion
- ❌ Copy creative design from a landing page/portfolio into product UI when the Aesthetic Boldness criterion picked *Brand-centric/cohesive* or *Functional/minimalist*
- ❌ Restructure page/section layout when Round 0's Structural Freedom criterion picked *Preserve structure* — even if Phase 2's audit thinks a different view-type would look better
- ❌ Change the brand color because it's "nicer" — only use tokens
- ❌ Ask the user before reading the code — scout first, ask only when actually needed
- ❌ Fix padding but break responsiveness
- ❌ Report "done" without verifying via screenshot (when a URL is available)
- ❌ Use bare `grid-cols-2` or `grid-cols-3` with no mobile collapse (`grid-cols-1 sm:grid-cols-2`)
- ❌ Use fixed width (`w-[320px]`) with no responsive fallback
- ❌ Hide an element with `hidden sm:block` without providing a mobile alternative
- ❌ Hover-only action (`group-hover:opacity-100`) with no visible fallback on mobile
- ❌ Fixed-height Modal/Dialog on mobile — causes content overflow
- ❌ Fixed bottom element without `pb-safe` / `env(safe-area-inset-bottom)`
- ❌ Image with default `objectPosition` when the subject gets cropped off on mobile
- ❌ Animate opacity of child components — container only
- ❌ Unmount a component to hide it — use CSS visibility/opacity if state needs to be preserved
- ❌ Use raw HTML elements instead of `@etaro/ui` components
- ❌ Use shadcn/MUI default colors when the project has its own primary color token
- ❌ Add unnecessary toast notifications (a deliberate celebratory/completion moment the Design Brief actually calls for is not "unnecessary" — see Phase 3)
- ❌ Let the scrollbar eat into the content area's width — always use an overlay/transparent scrollbar
- ❌ Inconsistent tab style within the same page — check cross-component tab consistency
- ❌ Guess a component's pattern "like X" — MUST read X first
- ❌ `float` / `shape-outside` inside a `flex` or `grid` container — has no effect, the browser silently ignores it (no error, no warning), causing confusing layout breakage
- ❌ Decorative overlay (shine border, border beam, floating badge, glow) without an explicit `z-index` — a sibling with `position: relative` appearing later in the DOM will cover it due to DOM-order stacking when `z-index: auto`
- ❌ Full-bleed image using `object-contain` without matching the container's `aspect-ratio` to the image file's actual ratio — gets letterboxed on both sides even though the container is full width
- ❌ Setting `h-full` only on the grid item wrapper while forgetting to set it on the inner visual frame (border/bg/shadow) too — cards still end up mismatched in height even though the grid stretched items equally
- ❌ Forcing `line-clamp`/fixed height onto copy of varying length across parallel cards instead of rebalancing the text length — line-clamp is a band-aid, rebalancing the copy is the actual root fix for "harmoniousness"
- ❌ Skip Phase 0's Aesthetic Customization or treat its 18 answers as a decorative afterthought instead of synthesizing them into a real Design Brief (step 8) before touching code — an un-anchored run still reads as generic/safe; picking patterns before picking a direction produces a grab-bag, not a coherent design
- ❌ Re-run Domain Research for an aspect already cached this session/day for the same domain-slug (Phase 0 step 7) — check `plans/reports/` per-aspect first, reuse instead of re-researching; only cache-missed aspects get a fresh agent
- ❌ Mix more than the allowed count of font-size/spacing/border-radius values without a derivable scale — arbitrary one-off values break proportion harmony
- ❌ Flat, single-tier surfaces everywhere with no elevation distinction — everything reads at the same visual depth
- ❌ Heavy shadow/skeuomorphic depth in a B2B context — over-correcting flatness into clutter
- ❌ List/table with only one-at-a-time actions and no bulk/multi-select when the action is naturally batchable
- ❌ Confirmation dialog for a reversible, low-risk action — use undo instead
- ❌ Generic button labels ("Submit", "OK") when a specific outcome-based label is available
- ❌ Validating a field on every keystroke instead of on blur — creates error-message flicker while typing
- ❌ Reusing the same dark-mode shadow/contrast values from light mode without re-verification
- ❌ Burying the highest-priority info/action below the fold on a dense dashboard
- ❌ Picking table row density arbitrarily instead of matching the actual user type (casual vs power-user)

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
