---
name: vdesign
description: "Redesign existing UI/UX according to a personal aesthetic: refined, harmonious, modern, elegant, consistent with the system. Use when upgrading the UI of an existing page/component/feature/PR."
user-invocable: true
when_to_use: "Invoke when you want to redesign or upgrade the UI/UX of a page, component, feature, or an entire existing diff/PR."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--wow]"
metadata:
  author: vyvu
  version: "7.0.0"
---

# vdesign — Personal UI/UX Redesign Skill

Upgrade or redesign UI/UX with a consistent aesthetic: **refined · harmonious · modern · elegant · consistent with the system**.

No depth-level flags. `vdesign <target>` is the only base mode — audit-driven: it fixes everything Phase 2 finds, regardless of depth (spacing → structural → visual-direction change). No artificial ceiling, no "found it but can't fix it, wrong level" outcome.

`--wow` (optional) — unlocks Awwwards-tier creative freedom on top of the base mode; see the Vibe Archetype Catalog and Phase 3 below.

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

## Personal Aesthetic (Non-negotiable)

This is the user's vocabulary — **ALL** must be met by default, not just a few picked at random. Suspended only when `--wow` is explicitly passed (see Phase 3):

| Keyword | Practical meaning in code |
|---------|--------------------------|
| **Refined** | Micro-details in the right place: consistent border-radius, even icon sizes, text-overflow handled, no odd spacing scale values |
| **Harmonious** | Color, font, spacing match the rest of the project; no "isolated island" of its own style; font-size/spacing/component-size follow a consistent modular scale/ratio, not arbitrary values |
| **Modern** | No outdated patterns (old-style bordered tables, old-style form labels, flat buttons with no state); makes good use of whitespace |
| **Elegant** | Clear hierarchy, low visual noise, no unnecessary decoration, clearly distinguished button hierarchy (primary/ghost/link) |
| **Deep** | Clear elevation tiers, consistent shadow/border/light-source — never flat-and-lifeless, never skeuomorphic |
| **Consistent with the system** | Matches design tokens, component patterns, and the project's visual language — **this is the most important requirement** |
| **Accessible** | Information isn't hidden; labels are clear; important icons have tooltips; empty/loading/error states are all present |
| **Efficient** | Minimizes clicks/steps: bulk actions, inline-edit, smart defaults where safe |
| **Creative when permitted** | Distinct visuals are allowed when the user asks for "something different to add variety" — but must still stay consistent on spacing/color |

**DO NOT** apply portfolio/avant-garde aesthetics. Even a full redesign must still serve the B2B product context: **clarity > impressiveness**.

---

## Vibe Archetype Catalog (`--wow`)

16 named, current (2025-2026) design philosophies to commit to in Phase 0's Vibe Commitment step. Pick ONE — never blend 3+ philosophies on one page (see anti-slop gate). Ratings assume this skill's B2B "clarity > impressiveness" default context; ignore B2B-viability when the target project is explicitly consumer/portfolio.

| # | Archetype | Core Aesthetic | B2B-Viable | Motion | Risk |
|---|---|---|---|---|---|
| 1 | Neo-Brutalist Bold | Thick lines, high contrast, raw geometry | Yes | Low | Low |
| 2 | Maximalist Editorial | Layered, vibrant, dense composition | Selective | Medium | Medium |
| 3 | Ethereal Glass | Frosted, translucent, soft depth | Yes | Low | Very Low |
| 4 | Soft Neumorphic | Subtle shadows, tactile, 3D-subtle | Yes | Low | Very Low |
| 5 | Kinetic/Motion-First | Animated reveals, micro-interactions | Yes | High | Medium |
| 6 | Chromatic Dopamine | Bold saturated color, exuberant | Accent only | Medium | High |
| 7 | Surreal Narrative | Photo-real + impossible, dreamlike | Hero only | Low | High |
| 8 | Organic Asymmetric | Curves, biophilic, natural forms | Yes | Low | Very Low |
| 9 | Maximal Minimal | White + 1-2 bold focal elements | Yes (best) | Low | Very Low |
| 10 | Flow-First System | Journey-driven, progressive disclosure | Yes | Medium | Very Low |
| 11 | Bento Interactive | Modular grid, playful blocks | Yes | Medium | Low |
| 12 | Typography-Dominant | Oversized, custom typeface, hierarchy | Yes | Low | Very Low |
| 13 | Authentic Humanist | Custom craft, genuine voice, anti-stock | Yes (critical) | Low | Very Low |
| 14 | Data-Adaptive | Personalized, context-aware, intelligent | Yes | Medium | Medium |
| 15 | Retro-Nostalgic | 70s/80s, warm, vintage textures | Niche | Low | High |
| 16 | Spatial 3D | Depth, parallax, layered storytelling | Yes | High | Medium |

---

## Workflow: Scan → Audit → Fix → Verify

### Phase 0: Determine scope

1. Parse the argument to determine the input mode (see table above)
2. If there's a URL/localhost → **take a screenshot immediately** using whatever screenshot tool is available (Playwright MCP, browser tool, etc.); if none is available, ask the user to paste a screenshot directly
3. If there's `--pr` → resolve the VCS profile per `~/.claude/skills/_vskills-shared/repo-profile.md` §2 first (if the file is absent, assume full gh mode — today's default). Full gh mode → `gh pr diff --name-only` to get the list of files. Degraded (no gh / non-GitHub) → print the §2 message and ask the user for a branch name, or fall back to `--diff` (`git diff --name-only`, needs no gh) — then continue into Phase 1 normally.
4. Resolve the Project Profile: check `.vdesign/profile.md` at the target project's git root (`git rev-parse --show-toplevel`). Present → read and use it. Absent → infer UI library/design tokens from `package.json` dependencies, `tailwind.config.*`, and the components folder. Still ambiguous → ask 1 question, then offer (don't force) to save the answer to `.vdesign/profile.md` for next time.
5. If empty → ask the user via `AskUserQuestion` — **exactly 1 question**
6. If `--wow` is set → **Domain Research**, before Vibe Commitment:
   - Domain slug = the domain from the Project Profile's context (e.g. "B2B Healthcare") + the target feature/page name resolved in step 1 (e.g. "booking form") — slugify (e.g. `healthcare-booking-form`)
   - Aspect list is fixed, always these 8: `ui` (UI/Visual), `ux` (UX/Interaction), `animation` (Animation/Motion), `layout` (Layout/Responsive), `3d` (3D/WebGL/spatial-depth patterns), `text` (Typography/microcopy/tone-of-voice patterns), `features` (competitor/domain feature patterns for the target feature — informational only, never expands redesign scope), `flow` (competitor/domain user-journey patterns for the target feature — informational only, never expands redesign scope)
   - Cache check per aspect, independently: look in `plans/reports/` for `researcher-vdesign-bold-<slug>-<aspect>*.md` created earlier this session/today — hit → reuse that aspect's report; miss → mark the aspect for fresh research
   - Spawn all cache-missed aspects in parallel — one Task/Agent call per aspect, up to 8, in the same message. Design-pattern aspects (`ui`/`ux`/`animation`/`layout`/`3d`/`text`) each find current (2025-2026) patterns specific to `<target feature>` in `<domain>` product context, scoped to their one assigned aspect — actively pull from real award-winning galleries (Awwwards Site/Mobile/Developer of the Day and Honorable Mentions, filtered by category matching `<domain>` where the gallery supports it; CSS Design Awards and Site Inspire as alternates when Awwwards has thin coverage for the domain) rather than only reciting abstract pattern descriptions; report concrete named patterns **with real source URLs** (the specific site/page studied, not just a pattern name). `features`/`flow` agents instead find current competitor/domain feature or flow patterns for `<target feature>` in `<domain>` — framed explicitly as context only, NOT scope to implement; the agent must not propose adding these to the redesign. Save each to `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
   - **Visual/technical study of top hits (orchestrator-level, not the research subagent — it has no browser tool):** after Domain Research reports back, if browser automation (e.g. `claude-in-chrome`) is available in this environment, open the 1-3 highest-value source URLs found and (a) take a screenshot for overall gestalt (composition, color harmony, hierarchy — judgment a bullet list can't convey) and (b) run `getComputedStyle()` via the browser's JS-execution tool on 1-2 standout elements to extract real, exact design-token values (box-shadow, border-radius, color, transition-duration/easing) — computed values are unaffected by minified/obfuscated production CSS, unlike trying to read a site's raw downloaded stylesheet, which is usually illegible (hashed utility classes, no structure) and not worth fetching. Merge these concrete values into Phase 3's pattern-pull. If browser automation isn't available, this step is skipped — Domain Research's text-based pattern-plus-source-URL reporting is still the floor, not optional.
   - An aspect whose agent fails or is unavailable: `ui`/`ux`/`animation`/`layout`/`text` fall back silently to their matching static catalog section (Cards and Containers / Micro-Interactions / Scroll Animations / Layout and Grids / Typography and Text in `premium-design-patterns.md`); `3d`/`features`/`flow` have no static catalog to fall back to — that aspect is simply absent from downstream steps, noted as "unavailable" (not "fallback"). The other aspects (cached, freshly researched, or fallback) still proceed; never fail the whole domain-research step because one aspect failed
7. If `--wow` is set → **Vibe Commitment**, before touching any code: pick ONE archetype from the Vibe Archetype Catalog above, a custom vibe from the user's own reference/mood keywords, or a vibe informed by whichever of step 6's per-aspect domain research reports exist (cached and/or fresh, up to 8 — `features`/`flow` reports, when present, inform the pick as context only, e.g. "competitors use a guided step-by-step flow → vibe should support that," and must never expand the redesign's scope to new features or flow steps). If the user didn't specify one, propose the best-fit archetype for the project's domain and state it out loud before implementing — say which aspects grounded the pick and their status (cached/fresh/fallback to static catalog/unavailable). An un-anchored `--wow` run (no committed vibe) is the single biggest reason output still reads as generic/safe.

---

### Phase 1: Scan (Component Tree Traversal)

**MUST** trace the component tree — not just read 1 file:

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

**When the user says "like X" or "similar to X":**
→ MUST read component/page X first before implementing — do not guess the pattern

---

### Phase 2: Audit

Read `references/audit-checklist.md` in full and go through each category — only flag issues that **actually affect visual/UX quality**. That file also covers the framework-conditional syntax note (Tailwind/React shorthand throughout is illustrative, translate to the project's actual stack).

<!-- The full ~100-item checklist (Typography through Sticky & Scroll Behavior) lives in references/audit-checklist.md — kept out of this file to keep the skill body lean. -->

---

### Phase 3: Fix

Fix everything Phase 2 found — spacing, states, component swaps, grid/layout restructure, and full visual-direction changes are all in scope by default; there is no depth ceiling to stay under. Depth should still be *proportional* to what's actually broken: a spacing-only audit finding does not license a full JSX rewrite (see Anti-Patterns — "rewrite the entire layout when only a tweak was needed").

**`--wow` (optional)**

Suspends ALL aesthetic AND interaction caution for this run — not just the 3 items previously listed, and not just visuals. This means: no "clarity > impressiveness" bias, no portfolio/avant-garde prohibition, no domain-sensitivity restraint (a healthcare/education/children's-product context does NOT mean tone it down — clarity and accessibility are enforced separately as hard technical rules below, not as an aesthetic brake), and no "keep interactions standard/low-key/generic" default either. Bespoke art direction, expressive typography scale, unique/asymmetric layout, custom motion, decorative accents (icon anchors, tinted sub-cards — see `references/quiet-polish-patterns.md`), expressive selection/completion/feedback moments (see that file's Motion & Interaction section) are all fully permitted — a genuinely delightful transition or a celebratory completion moment is not "unnecessary," it's the point. What stays as a floor, not a cap: Phase 2's usability principles (all required states present, Hick's Law visible-choice limits, confirm-only-destructive-actions) — these are usability floors, not timidity, and boldness must still clear them, not bypass them. What stays off-limits entirely: the hard technical rules below (accessibility, tech stack, logic/API, GPU-safe motion, dependency allowlist) — those are safety/engineering constraints, not restraint on creativity, and are never suspended.

**Beating a reference image, not just matching it.** When the input includes a reference/target image (an aspirational mockup, competitor screenshot, or AI-generated concept — see Input Modes) rather than only a "before" screenshot to fix, treat it as the bar to clear, then exceed it on the axes a static image structurally cannot compete on: consistency across every screen in the same flow (not just the one shown), real motion/interaction (a static image is frozen — see quiet-polish-patterns.md's Motion & Interaction section), measurable precision (exact spacing-grid/contrast-ratio conformance — a static mockup often has small unmeasured misalignments a real implementation shouldn't repeat), and real responsiveness/accessibility (the mockup only had to look good at one fixed size). Match its specific devices first (grouping, color tiers, iconography, layout moves), then win on these axes — don't stop at parity.

Requires the Vibe Commitment from Phase 0 step 7 first — pick the vibe, then pull patterns. Never pull patterns first and rationalize a vibe after the fact.

**One signature element, not scattered boldness.** Commit to ONE bold move — a color discipline, a custom typeface, a motion language, an illustration style, or an asymmetric layout gesture — and keep everything else restrained around it. Half-committed boldness (a little bit of everything) reads *more* generic than full commitment to one thing; this is the #1 reason `--wow` output has read as safe in practice. Boldness must be **structural** (typography scale, contrast, motion-as-clarity, custom voice), never purely decorative.

Pull from these 6 named patterns (award-winning B2B, not portfolio/consumer):

| Pattern | How it works | B2B-safe because |
|---|---|---|
| Strategic Accent Boldness | Neutral baseline + 1-2 committed bold focal points | Clarity stays primary; boldness reads intentional |
| Authentic Voice + Human Craft | Custom photography/illustration, genuine copy, anti-stock | Authenticity signals credibility, not decoration |
| Bold Typography-First | Oversized custom/variable type; hierarchy via size/weight alone | Boldness lives in the skeleton, not ornament |
| High-Contrast Disciplined | Black/white or deep saturation, thick lines, no gradient/blur | Directness reads confident, not reckless |
| Motion-First Clarity | Every animation clarifies (state change, hierarchy); 1-2 sophisticated interactions per page max | Motion signals sophistication, doesn't distract |
| Product-Centric Hero | Real product UI/screenshot as the hero, not illustration | Confidence + transparency, not showmanship |

CSS/SVG grain-texture overlay (opacity <10%, `<feTurbulence>` or CSS `filter`) is also available as a `--wow` texture technique — no dependency needed.

**Pattern-pull, not audit-fix.** Once the vibe is committed, pull from the 6 patterns above plus that vibe's arsenal — if `~/.claude/skills/frontend-design/references/premium-design-patterns.md` exists, read it for the full catalog (navigation, layout, card, scroll-driven animation, kinetic typography, micro-interaction patterns); if absent, use `references/anti-slop-minimum.md`'s archetype patterns instead. **Always also read `references/quiet-polish-patterns.md`** — a restrained tier (tinted sub-cards, icon anchors, eyebrow tags, radio-cards) for when the committed vibe calls for warmth/refinement rather than boldness; this is a permanent supplement merged in addition to the catalog above, not a fallback for when it's missing — plus any domain-specific patterns/insights from whichever of Phase 0 step 6's design-pattern aspect reports exist for this run (`ui`/`ux`/`animation`/`layout`/`3d`/`text`, up to 6 — `features`/`flow` reports are excluded here, they're informational-only for Vibe Commitment, not pattern-pull material). Merge all of them, don't replace the catalog. Phase 2's audit still runs (it catches broken states/a11y/responsive) but under `--wow` it's a floor, not a ceiling — output is judged by how distinctive the ONE committed signature element is, not just absence of defects.

**Dependency allowlist — add directly, no need to ask:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), native CSS scroll-driven animations / View Transitions API, Rive, Lottie — the de-facto standard toolkit on 2025-2026 award-winning sites.
**Still stop-and-ask:** React Three Fiber/Three.js (650KB+ — only if 3D is genuinely core to the concept), Barba.js, any paid/SaaS tool beyond Rive, custom WebGL/GLSL shaders.

**Anti-slop gate before reporting done** — if `~/.claude/skills/frontend-design/references/anti-slop-rules.md` exists, read it for the full checklist; if absent, use `references/anti-slop-minimum.md`'s fail conditions instead. At minimum fail the run on: Inter/Roboto as the only typeface, purple-to-blue gradient as the dominant aesthetic, 3+ visually-identical cards in a row, placeholder names/numbers ("John Doe", round 50%/$100), generic startup copy ("Elevate", "Seamless", "Next-Gen"), pure `#000000` background, missing hover/focus states, **unmodified stock flat illustration** (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps without custom palette/poses — same tier as purple-gradient; fix by tier: custom hand-drawn > line-art/sketch > isometric 3D > heavily-customized flat > geometric/abstract > skip illustration). **Exception — not slop**: a single small (≤32px) custom line/duotone icon placed with clear intent as a decorative anchor (e.g. beside a title) is NOT a stock illustration scene and is encouraged, not flagged — see the Icon Anchor pattern in `references/quiet-polish-patterns.md`.

Still mandatory even under `--wow`: accessibility (contrast, focus rings, all required states), no tech-stack migration, no logic/state/API changes, GPU-safe motion only (`transform`/`opacity` — never animate `width`/`height`/`top`/`left`; B2B mobile LCP is already tight, bold must not blow the budget).

**Hard rules (apply to every run, including `--wow`):**
- ✅ Work with the existing tech stack — DO NOT migrate framework
- ✅ DO NOT break logic/state/API — only change the presentation layer
- ✅ Exception: UX Efficiency and Content Design & Error Prevention category fixes (Phase 2) may touch frontend interaction state/hooks/localStorage — see the scope carve-out under UX Efficiency. Still no backend/API/data-model changes.
- ✅ **Content-density proposals are never auto-applied, in any mode**: if the Information Architecture "sparse/under-filled" check (Phase 2) flags real unrendered data worth surfacing, compile it as a short list of concrete, specific suggestions (field name + where it'd go — never invented/placeholder data) and present it via `AskUserQuestion` at Phase 4 for the user to accept/reject per item, before adding anything. This is a content/product decision, not an aesthetic one — it stays a proposal regardless of `--wow`.
- ✅ Check `package.json` before adding a dependency — except the `--wow` allowlist above, which may be added directly
- ✅ When hiding (not deleting) → use opacity/visibility, don't unmount
- ✅ Use Tailwind tokens — no hardcoded hex
- ✅ Use the Project Profile's "Good reference UI" entry as the reference standard — absent → the best-looking component already in the project
- ✅ **Responsive is mandatory**: every layout change MUST be verified at 3 viewports — mobile (375px), tablet (768px), desktop (1280px); write mobile-first, then override with sm:/lg:
- ✅ Third-party styled component (has `import 'lib/*.css'`) wrapped in a wrapper div → wrapper owns ALL visual state (border, ring, disabled opacity); null out all border/shadow inside the component via CSS var override + scoped `!important`
- ✅ **ARIA discipline**: prefer native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) over ARIA. Only add `role`/`aria-*` when native HTML can't express the interaction, and when added, ensure the full role+state+property set is present — never add ARIA attributes "just in case"
- ❌ DO NOT add complex animation if Motion/Framer isn't already in the project — exception: under `--wow`, the dependency allowlist above applies instead
- ❌ DO NOT add new brand colors — only use existing tokens (exception: `--wow` may introduce a new accent if the committed vibe requires it)
- ❌ DO NOT use the component library's default color (shadcn blue) if the project has its own primary color
- ❌ DO NOT add unnecessary toast notifications (exception: under `--wow`, an intentional celebratory/completion moment that's part of the committed vibe is not "unnecessary" — the bar is whether it's deliberate, not whether it's minimal)
- ❌ DO NOT change logic/API/state management

---

### Phase 4: Verify

1. If there was an initial URL/localhost → take an after screenshot, compare before/after
2. If there was an image input → verify the code matches the image's intent
3. Run `pnpm format` (if the project has it)
4. **Accessibility verify**: if the project has (or the user allows adding) `@axe-core/playwright` or plain `axe-core`, run a short script against the audited route/component and print violations. If unavailable, print the equivalent manual-check command for the user to run themselves — visual/manual review should not be the only verification for accessibility.
5. If you just edited an image file directly under `public/` (overwritten at the same path, name unchanged) and the user reports "not seeing the change" → don't rush to edit the code/image again; tell the user to hard-refresh or clear `.next/cache/images` + restart the dev server first — Next.js Image Optimizer caches by URL+size, not by file content, so the fix is likely already correct but an old cached version is still being served
6. **Adversarial Verify** (subagent — only when Fix actually touched structural/JSX-level code: component swap, grid/layout restructure, visual-direction change — OR `--wow` was used — OR UX Efficiency / Content Design & Error Prevention category fixes touched frontend state/interaction logic): spawn 1 fresh subagent with the diff, Phase 2's audit checklist, and (if `--wow`) the anti-slop gate. It re-audits the final state independently — no access to this run's reasoning — and reports PASS or a list of remaining issues (audit items still broken, fixes that overstepped what was actually needed, anti-slop violations). Issues found → return to Phase 3, fix, re-run this step once. Mirrors `vreview`'s Phase 4 Adversarial Pass in this same skill pack.
7. **Self-Check** (inline, every run, no subagent): before writing the short report, confirm — (a) fix depth was proportional to what Phase 2 actually found, no unrequested rewrites beyond that; (b) every applicable Phase 2 category was addressed or explicitly marked not-applicable; (c) if `--wow` ran, the anti-slop gate (including the illustration check) was actually checked off, not just implied.
8. **Content-density proposals** (only if Phase 2's sparse/under-filled check flagged something): before the short report, present the compiled list via `AskUserQuestion` — one item per real unrendered field/data point found, each independently acceptable/rejectable. Never add any of it to the code without the user's explicit answer here, in any mode.
9. **Short report**: "Redesigned [X]. Main changes: [list 3-5 bullet points]"
   - No long summary
   - Only mention significant changes
   - If `--wow` ran: 1 line per aspect (all 8) noting Phase 0 step 6's status, plus Adversarial Verify's PASS/issues-found outcome — e.g. "ui: fresh, ux: cached, animation: fallback (agent unavailable), layout: fresh, 3d: unavailable, text: cached, features: fresh, flow: unavailable; Adversarial Verify: PASS"

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
- ❌ Add flashy animation to a healthcare app (unless `--wow` is active — see Phase 3 suspend clause; GPU-safe motion rules still apply)
- ❌ Copy creative design from a landing page/portfolio into product UI (unless `--wow` is active — see Phase 3 suspend clause)
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
- ❌ Add unnecessary toast notifications (unless `--wow` is active and it's a deliberate celebratory/completion moment — see Phase 3 suspend clause)
- ❌ Let the scrollbar eat into the content area's width — always use an overlay/transparent scrollbar
- ❌ Inconsistent tab style within the same page — check cross-component tab consistency
- ❌ Guess a component's pattern "like X" — MUST read X first
- ❌ `float` / `shape-outside` inside a `flex` or `grid` container — has no effect, the browser silently ignores it (no error, no warning), causing confusing layout breakage
- ❌ Decorative overlay (shine border, border beam, floating badge, glow) without an explicit `z-index` — a sibling with `position: relative` appearing later in the DOM will cover it due to DOM-order stacking when `z-index: auto`
- ❌ Full-bleed image using `object-contain` without matching the container's `aspect-ratio` to the image file's actual ratio — gets letterboxed on both sides even though the container is full width
- ❌ Setting `h-full` only on the grid item wrapper while forgetting to set it on the inner visual frame (border/bg/shadow) too — cards still end up mismatched in height even though the grid stretched items equally
- ❌ Forcing `line-clamp`/fixed height onto copy of varying length across parallel cards instead of rebalancing the text length — line-clamp is a band-aid, rebalancing the copy is the actual root fix for "harmoniousness"
- ❌ Run `--wow` without committing to a vibe first (Phase 0 step 7) — un-anchored boldness still reads as generic/safe; picking patterns before picking a direction produces a grab-bag, not a coherent design
- ❌ Re-run domain research for an aspect already cached this session/day for the same domain-slug (Phase 0 step 6) — check `plans/reports/` per-aspect first, reuse instead of re-researching; only cache-missed aspects get a fresh agent
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

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vci, vtickets, vdesign, vlearn, vrollback) only if one genuinely fits; if nothing further is needed, say so plainly.
