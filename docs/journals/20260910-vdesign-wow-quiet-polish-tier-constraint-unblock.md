# vdesign --wow: Quiet Polish Tier, Suspend Broadening, and a Code-Reviewer Catch

**Date**: 2026-09-10 16:38  
**Severity**: Medium  
**Component**: vdesign skill (skills/vdesign/SKILL.md, SKILL.vi.md, new references/quiet-polish-patterns.md + .vi.md)  
**Status**: Resolved with one mid-implementation fix

## What Happened

User showed two M-CHAT-R form redesigns: one by ChatGPT (before), one by Claude+vdesign `--wow` (after). ChatGPT's redesign was visibly more polished — soft-tinted sub-card containers, small icon accents, pill-shaped field labels, thoughtful radio-card states. Claude's `--wow` output was flat and bare by comparison. User's reaction: "The ChatGPT version reads as more cared-for. Why can't `--wow` match that polish without being loud?"

**Initial root cause hunt:** User + implementer traced the gap through three concrete channels:

1. **Pattern catalog problem**: `~/.claude/skills/frontend-design/references/premium-design-patterns.md` (shared with frontend-design skill) is the only tier vdesign knows about under `--wow`. That file is all "loud Awwwards" — glassmorphism panels, particle explosions, kinetic typography. No tier for "warm, tiered-structure refinement" (soft tints, small icons, subtle elevation). vdesign was inheriting a design language optimized for landing pages, not healthcare/education forms.

2. **Anti-slop gate silence**: The gate lists what's banned (unmodified stock illustrations, purple gradients, etc.) but doesn't list what's **permitted** when `--wow` is active. So the model, under uncertainty and audit pressure, defaults to the safest bet: don't add any decorative elements at all.

3. **Suspend clause too narrow**: Phase 3's current `--wow` suspend statement only carves out three specific things: "portfolio/avant-garde aesthetics," "clarity > impressiveness bias," and one anti-pattern. It doesn't suspend the deeper B2B domain-sensitivity restraint (the implicit "healthcare forms should be cautious" logic). A form for screening autistic children in Vietnam felt like an environment where being "bold" needed justification — so the model played conservative.

**User decision:** Rather than declare `--wow` broken or broadly loosen its constraints everywhere, user chose a surgical fix: **(a)** rewrite the suspend clause to explicitly tạm ngưng TOÀN BỘ aesthetic caution while keeping hard technical rules (a11y, tech stack, logic/API, GPU-safe motion) permanently on; **(b)** create a new tier file `quiet-polish-patterns.md` that sits between B2B-flat and loud-Awwwards, with patterns like tinted sub-cards, icon anchors, eyebrow tags, radio-cards; **(c)** make vdesign **always** read this file under `--wow`, not as a fallback.

**Implementation (Phase 3 pattern-pull paragraph rewritten, new file added):**
- SKILL.md Phase 3 suspend: Changed from "suspend 3 specific items" to "suspend ALL aesthetic caution — not domain-sensitivity restraint masquerading as technical safety."
- Added explicit language: "Clarity and accessibility are enforced separately as hard technical rules below, not as an aesthetic brake."
- Pattern-pull step now reads `quiet-polish-patterns.md` as a permanent supplement (not a fallback for when premium-design-patterns.md is missing).
- Anti-slop gate: Added exception for small custom icons (≤32px, line/duotone, placed with intent) — not slop, actively encouraged under `--wow`.
- Same changes applied to SKILL.vi.md (Vietnamese parallel).

**Bug surfaced during code review:** Code-reviewer subagent read the new suspend clause (which says domain-sensitivity is no longer a restraint under `--wow`) and found it contradicted two bullets in SKILL.md's Anti-Patterns list:
- ❌ "Add flashy animation to a healthcare app" (no caveat for `--wow`)
- ❌ "Copy creative design from a landing page/portfolio into product UI" (no caveat)

These bullets were written before the suspend clause was broadened. Under the old narrow suspend (3 items), they were consistent. Under the new suspend (all aesthetic caution), they created a direct contradiction. Implementer caught this, added `(unless --wow is active...)` caveat to both bullets, applied to both EN + VI files. One subagent-caught regression prevented.

**Commit 2dd0d90:** 4 files, 76 insertions/10 deletions.

---

**Round 2 (same session, user continuation):** After seeing the Quiet Polish tier land, user escalated the ask: not just "remove aesthetic caution," but explicitly require `--wow` to **exceed** ChatGPT's mockup quality across dimensions a static image can't convey. Expanded implementation scope:

1. **Suspend clause widened further** — Phase 3's suspend now covers aesthetics AND interaction tone. Before: "suspend aesthetic caution but keep interaction conservative/generic." Now: "suspend ALL caution (aesthetic + interaction), except hard technical floors (accessibility, GPU, responsive, dependency safety)." This means interaction can be deliberately *delightful* (not just functional), not merely "correct but muted."

2. **New subsection in Phase 3: "Beating a reference image"** — when user provides a reference image (not just a "before" to fix, but a target aesthetic), vdesign now explicitly aims to surpass it on axes static images can't show:
   - **Consistency across flows** — reference image shows 1 screen; final design must be uniform across full multi-screen journey
   - **Real motion/interaction** — where reference is frozen, design has intentional transition moments (150-350ms, GPU-safe)
   - **Measurable precision** — spacing, contrast, icon alignment optimized to exact token values, not "close to" reference
   - **Responsive + a11y** — reference may work at 1 viewport; design must scale gracefully and remain fully accessible
   
   Updated Input Modes table to reference this subsection: mode "Reference image provided, user wants to beat it" now points to "Beating a reference image."

3. **New "Motion & Interaction" section in quiet-polish-patterns.md** (7 patterns, GPU-safe, 150-350ms range):
   - **Selection Transition** — selected element fades in tint, siblings fade to 70% opacity (concurrent, 200ms ease-in-out)
   - **Progress Fill Animation** — fill element inside fixed-width track animates via `transform: scaleX(progress)` left-to-right (250-350ms ease-out)
   - **Selected-Card Settle** — on selection, card expands 4px height and drops 2px shadow, momentum easing (250ms)
   - **Icon Chip Entrance** — icon-inside-pill fades in + scales from 0.8 when parent mounts (180ms cubic-bezier(0.34, 1.56, 0.64, 1) bounce)
   - **Tactile Press Feedback** — button/interactive element scales to 0.96 on pointerdown, back to 1 on pointerup (100ms linear, haptic pulse on mobile)
   - **Completion Moment** — after form submission, checkmark animates in (scale 0→1, 300ms) with preceding pulse-ring (3 expanding rings, staggered 50ms)
   - **Reduced-motion guard** — all 6 patterns check `prefers-reduced-motion: reduce` and degrade to instant/opacity-only if true
   
   Paired `.vi.md` translation.

4. **Toast rule loosening** — Two places in SKILL.md's Hard Rules and Anti-Patterns were tightened:
   - Old Anti-Pattern: ❌ "Show a toast for every action (unnecessary UI churn)"
   - New: ❌ "Show a toast for every action (unnecessary UI churn)" — EXCEPTION: under `--wow`, a *deliberate* moment of celebration (e.g. form submission success, milestone unlock) is not "churn," it's crafted delighting. Still filter genuine noise, but celebratory moments are invited.

5. **Precision checklists added to Proportion & Scale Harmony section:**
   - **Icon optical alignment:** glyph's visual center (not bounding box) must align with container's geometric center; duotone icons: both layers aligned consistently
   - **All spacing/radius must resolve to live design tokens** — no "approximately 16px" or "feels like 12px"; every dimension is exact token reference (e.g. spacing-3, radius-lg)
   - Small icon custom assets: line weight ≥1.5px at ≥32px native size (so it stays readable when scaled down)

6. **Bug found by code-reviewer (second pass):** Progress Fill Animation pattern contradicted its own GPU-safe constraint:
   - Pattern initially written: "animate `width` from 0 to 100%" (explicitly banned in hard rules) + "300-400ms range" (outside the 150-350ms announced range)
   - Fix applied: rewrote to animate `transform: scaleX(progress)` on a child fill element inside a fixed-width track (GPU-safe, lower layer doesn't move) + adjusted range to 250-350ms (within band)
   - Lesson: self-contradiction within newly written prose — not just contradiction with prior sections. Shows that one pass of self-reading doesn't catch internal inconsistency in technical patterns.

**Commit c57e957:** 4 files, 42 insertions/10 deletions.

---

**Round 3 (same session, third escalation):** User tested the Quiet Polish tier against top Awwwards entries and asked directly: "Is it really competitive now? Should we pull reference designs from actual Awwwards winners, not just trust the pattern docs?" This forced a hard re-verification: were the pattern catalogs (`quiet-polish-patterns.md`, `premium-design-patterns.md`, `anti-slop-minimum.md`) actually derived from real production sites, or just text model artifacts with no ground-truth source?

**Finding via grep Phase 0 (Domain Research step 6):** The Domain Research phase explicitly instructs: "staying inside the B2B 'clarity > impressiveness' bias (**not pure Awwwards/portfolio inspiration**)". This line **directly contradicts** the fix from Round 1, which suspended aesthetic caution. The line was written before Round 1 and *never updated* — it sat dormant for 2 code-reviews, neither of which checked Phase 0 (both only audited Phase 3's suspend clause). When the suspend was broadened to "suspend ALL aesthetic caution," this line became a silent blocker: the research phase was *still* saying "don't look at portfolios for inspiration" while Phase 3 was saying "now you can."

**Verification of pattern source:** Cross-checked the three pattern files: `premium-design-patterns.md`, `quiet-polish-patterns.md`, `anti-slop-minimum.md` — none contain URLs or screenshot citations. They read as curated design vocabulary, not reverse-engineered from specific real sites. No way to know if they match what Awwwards winners actually do.

**Implementation (Commit 411782a, 2 files, 12 insertions/4 deletions):**
1. **Phase 0 step 6 rewritten:** Removed the Awwwards prohibition entirely. New directive: actively source from Awwwards Site/Mobile/Developer of the Day + Honorable Mentions (filter by domain: "Healthcare", "Education", "Community"). Fallback sources: CSS Design Awards, Site Inspire. Researcher **must** report back with URLs (not just pattern names) and explain how each pattern maps to that real site.

2. **New orchestrator step (post-research):** If browser automation available (`claude-in-chrome` or equivalent), open top 1-3 URLs from researcher report, capture screenshot (visual impression), then run `getComputedStyle()` on key elements to extract design-token values (shadow, radius, color, timing). Explains why: raw CSS often minified/obfuscated (Tailwind JIT, CSS-in-JS hashing); `getComputedStyle()` returns **computed** values regardless of source. Falls back to text+URL report if no browser tool.

3. **Phase 2 addition (Information Architecture & Scannability):** New checklist item "sparse/under-filled detection" — flag when template area is empty even though data exists (e.g., gallery grid with 2 items in a 12-slot container, form fields rendered but data-array is longer). Don't auto-fill; report and ask user.

4. **Phase 4 hard rule (Content Density):** New permanent rule (applies all modes, not just `--wow`): any proposal to add fields/sections for data density must pass `AskUserQuestion` with explicit list before implementation. User sees each item and approves/rejects. Prevents "sparse data = add filler" anti-pattern.

5. **Phase 4 reordering:** New step 8 (report content-density suggestions via `AskUserQuestion`), moves old "Short report" from step 8 to step 9. Ensures user approves density changes before final report.

**Code-reviewer validation (third pass):** All 5 changes verified — Phase 0 contradiction fixed, browser-automation step coherent with fallback logic, sparse checklist placed correctly (Phase 2 IA section), content-density rule in Phase 4 hard rules, step reordering doesn't break flow. EN + VI versions match semantically. No contradictions introduced. Review passed.

**Key realization (Round 3):** Contradiction existed across **full file lifecycle** but was missed twice because reviews were **scope-limited** (Phase 3 only). This is not a bug in the code-review process; it's a gap in **scope definition**. When a rule's scope changes (from "3 specific items" → "all aesthetic caution"), the review scope must change too: from "check the changed paragraph" to "grep downstream references to the old scope and verify they still cohere." Phase 0's prohibition on Awwwards was a downstream reference to the old scope ("don't look at portfolios for inspiration") that silently became stale when Round 1 suspended that bias.

## The Brutal Truth

This session proved two uncomfortable things:

**One:** When you have a reference file shared between multiple skills that all *read* the same file but *need different tones* (vdesign needs tiered restraint; frontend-design needs boldness), the shared file becomes a lowest-common-denominator problem. The supplement-file approach (`quiet-polish-patterns.md` living in vdesign's own references/) is the right fix, not trying to retrofit tone into the shared file.

**Two:** Broadening a rule's scope (from "suspend 3 items" to "suspend all aesthetic caution") without grep-checking downstream consequences is how you create quiet contradictions. The Anti-Patterns bullets didn't *lie* when the suspend was narrow — they became false when the scope changed. Code review should have been mandatory before implementation, not just for polish. It was.

## Technical Details

### Phase 3 Suspend Clause Evolution

**Round 1 — Narrow suspend (Commit 2dd0d90):**
```
Suspends ALL aesthetic caution for this run — not just the 3 items previously listed. 
This means: no "clarity > impressiveness" bias, no portfolio/avant-garde prohibition, 
no domain-sensitivity restraint (a healthcare/education/children's-product context does 
NOT mean tone it down — clarity and accessibility are enforced separately as hard 
technical rules below, not as an aesthetic brake). ... The only things that stay 
off-limits under `--wow` are the hard technical rules below (accessibility, tech stack, 
logic/API, GPU-safe motion, dependency allowlist) — those are safety/engineering 
constraints, not restraint on creativity, and are never suspended.
```

**Round 2 — Extended suspend (Commit c57e957):**
Now explicitly includes interaction tone as well. Wording expanded to clarify: "suspend aesthetic caution AND interaction-tone caution — celebration moments, delight, playfulness are all on-table, not just permitted but encouraged." Hard technical floors remain (accessibility, GPU-safe motion, responsive, dependency safety) — those floors are about *engineering*, not *taste*. Added separate subsection "Beating a reference image" (Phase 3) that defines how to surpass static mockups on multi-screen consistency, real motion timing, measurable precision, responsive scaling, and accessibility depth.

### New File Expansions: quiet-polish-patterns.md

**Round 1** (33 lines):
- **Tinted Sub-Card** — soft background tint, ≤2 steps off page background, bo góc 16-24px
- **Secondary Background Tint** — page background gets whisper-tint instead of pure white
- **Icon Anchor** — single small (≤32px) custom line icon beside title, inside soft chip
- **Eyebrow Tag** — pill badge above heading with short label ("Câu 1", "Bước 2")
- **Radio-Card** — full-width card per option, filled-dot indicator on left, tinted fill when selected
- Plus 3 more (Corner Wash, Sparkle Mark, Two-Weight Typography Hierarchy)

**Round 2** (new "Motion & Interaction" section, 7 patterns):
All patterns comply with hard technical rules (GPU-safe transforms only, no layout thrashing, 150-350ms ideal range, `prefers-reduced-motion` guard).

- **Selection Transition (200ms)** — selected element's background tint fades in (0→target opacity), siblings fade to 70% (ease-in-out). Uses `transition` on `background-color` and `opacity` — no transform, no paint. Concurrent, not sequential.

- **Progress Fill Animation (250-350ms)** — fill child element inside fixed-width track container animates via `transform: scaleX(progress)` left-to-right. Container width is static; only fill's scale-x changes. Easing: `ease-out` (faster start, gradual slow). Avoids animating `width` (layout thrash) or `background-clip` (paint thrash).

- **Selected-Card Settle (250ms)** — on selection, card height expands 4px (via `transform: scaleY(1.02)` from center), shadow depth increases by 2px (`box-shadow: 0 4px 12px`). Easing: momentum curve `cubic-bezier(0.25, 0.46, 0.45, 0.94)` to avoid linear bounce feel.

- **Icon Chip Entrance (180ms)** — icon-inside-pill fades in + scales from 0.8 to 1, triggered on mount or on-focus. Easing: `cubic-bezier(0.34, 1.56, 0.64, 1)` (bounce overshoot, playful). Uses `opacity` + `transform: scale()`, no layout impact.

- **Tactile Press Feedback (100ms)** — button/tappable element on `pointerdown` scales to 0.96 (via `transform: scale()`), on `pointerup` back to 1. Easing: `linear` (instant feel). On touch devices, trigger haptic pulse (`navigator.vibrate(50ms)`). Uses transform only, no reflow.

- **Completion Moment (300ms checkmark + pulse rings)** — After form submission, a success checkmark animates in (`scale: 0→1`, opacity 0→1, 300ms ease-out). Preceding it: 3 expanding concentric rings emerge from center point, each scaled 1→3 over 600ms with 50ms stagger, opacity 1→0 (pulse effect). All via `transform: scale()` and `opacity` — GPU-safe.

- **Reduced-motion Guard** — all 6 patterns check `prefers-reduced-motion: reduce` media query; if true, instant-swap (`transition: none`), or degrade to `opacity`-only fade (no movement). Pattern implementations must conditionally set `animation-duration: 0s` or `transition: opacity 0.2s` instead of motion-heavy versions.

Paired with `.vi.md` translation of all 7 patterns.

### Anti-Slop Gate + Toast Rule Updates (SKILL.md)

**Icon exception line** (Anti-Patterns section):
```
Exception — not slop: a single small (≤32px) custom line/duotone icon placed 
with clear intent as a decorative anchor (e.g. beside a title) is NOT a stock 
illustration scene and is encouraged, not flagged — see the Icon Anchor pattern 
in `references/quiet-polish-patterns.md`.
```

**Toast rule loosening** (Hard Rules + Anti-Patterns):
```
Old: ❌ "Show a toast for every action (unnecessary UI churn)"

New: ❌ "Show a toast for every action (unnecessary UI churn)" — EXCEPTION: under 
`--wow`, a deliberate celebratory moment (form submission success, milestone reached, 
data saved) is not churn, it's crafted delight. Still filter operational noise 
(auto-saves, invisible syncs), but intentional celebration is invited and should 
feel *earned*, not spammy.
```

### Precision Checklist Addition: Proportion & Scale Harmony

Expanded "Proportion & Scale Harmony" section with two new rigor requirements:

1. **Icon optical alignment:**
   - Glyph's visual center (not bounding box) must align with container's geometric center — can require transparent padding in SVG to achieve true optical balance
   - Duotone icons: both layers must be aligned consistently (not one layer offset accidentally)
   - For custom-drawn icons: line weight ≥1.5px at native ≥32px size (so descaling to 24px, 16px still reads crisp)

2. **All spacing and radius must resolve to live design tokens:**
   - Not "approximately 16px" or "feels like 12px" in design handoff
   - Every spacing value must map to exact project token (e.g., `spacing-3: 12px`, `spacing-4: 16px`)
   - Every border-radius must be a named token (`radius-sm`, `radius-md`, `radius-lg`)
   - Mixed token+pixel references are a red flag — indicates missing token or misunderstanding of scale

### Progress Fill Animation Bug (Self-Contradiction in Round 2)

**Original prose (round 2, initial write):**
> "Progress Fill Animation (300-400ms) — animate `width` from 0 to 100%..."

**Contradiction detected:** This violates two rules in the same skill:
- Hard Rule: "❌ DO NOT animate `width` or `height` (layout thrash) — use `transform: scaleX(progress)` or `scaleY` instead"
- Announced range: "Motion range: 150-350ms ideal for delightful feedback" (300-400ms is outside)

**Fix applied:** Rewrote to:
> "Progress Fill Animation (250-350ms) — fill child element inside fixed-width track container animates via `transform: scaleX(progress)` left-to-right. Easing: `ease-out`."

**Significance:** Self-contradiction within the same newly written prose — not between new code and legacy code. Indicates that one self-review pass is insufficient even for technical-pattern docs. Required independent code-reviewer second pass.

---

### Phase 0 Domain Research Bug (Round 3 — Cross-Phase Scope Contradiction)

**Original Phase 0 step 6 directive (pre-Round 1, still active through Round 2):**
> "...staying inside the B2B 'clarity > impressiveness' bias (**not pure Awwwards/portfolio inspiration**). Research interviews only, not portfolio spelunking..."

**Why this matters:** Round 1 suspended "clarity > impressiveness bias" and "portfolio/avant-garde prohibition" under `--wow`. But Phase 0's research instruction was **never updated** — it still explicitly told the researcher "do NOT look at Awwwards/portfolio sites for inspiration." Two code-reviews passed without anyone checking Phase 0, so the contradiction lived silently:
- Phase 0: "do not research Awwwards" (old constraint, pre-Round 1)
- Phase 3 Round 1: "suspend Awwwards prohibition" (new override, Round 1)
- Net result: confusion — was Awwwards research permitted or banned?

**Additional finding:** The three pattern files (`premium-design-patterns.md`, `quiet-polish-patterns.md`, `anti-slop-minimum.md`) contain curated design vocabulary with no URL citations or production-site source links. They read as model-generated design terminology, not reverse-engineered from actual top Awwwards winners.

**Fix applied (Commit 411782a):**
```
Phase 0, step 6 rewritten:
OLD: "...staying inside B2B 'clarity' bias (not pure Awwwards/portfolio inspiration)..."

NEW: "Source from production benchmarks: Awwwards Site/Mobile/Developer of the Day 
winners, filtered by domain category (Healthcare, Education, Community, etc.). 
Honorable Mentions section also valid. Fallback: CSS Design Awards, Site Inspire. 
Researcher MUST report back with URLs of 3-5 source sites and short note on which 
pattern from our catalog each site exemplifies. No paraphrasing—cite the URL."
```

Removes prohibition entirely, makes active sourcing mandatory, requires URL+citation in report.

### Browser Automation for Design-Token Extraction (Round 3 — Orchestrator Step)

**Problem:** After researcher returns URLs, how does vdesign extract actual design-token values (shadow depth, border-radius, color hex, animation timing) from production sites? Raw CSS source is often minified or obfuscated (Tailwind JIT, CSS-in-JS dynamic class names). Screenshots show visual impression but don't capture computed values.

**Solution — New orchestrator-level step (post-research, before Phase 1):** 
If browser automation available (`claude-in-chrome` or similar):
1. Open 1-3 top URLs from researcher report
2. Capture screenshot (visual reference)
3. For key interactive elements (buttons, form fields, cards), run `getComputedStyle(element)` to extract:
   - `box-shadow` (depth, blur, color)
   - `border-radius` (all corners)
   - `background-color` / `color` (hex + computed rgb)
   - `transition` / animation-duration (timing)
   - `padding` / `margin` (spacing tokens)
4. Report: "Site X's button primary uses shadow(0 2px 8px rgba(0,0,0,0.1)), radius-6, transition 200ms ease-out"
5. Fallback (no browser tool): Return text+URL report, skip computed values

**Why computed-style > raw CSS:** 
- Minified CSS: `@apply py-2 px-4 rounded shadow` → meaningless token names to someone not reading the tailwind config
- CSS-in-JS hashing: `.sc-a1b2c { box-shadow: 0 2px 8px ... }` → class name tells you nothing, but browser computed-style reveals the actual value
- Dynamic theming: raw CSS may show a variable `var(--shadow-sm)`, but computed-style shows the *resolved* value
- Screenshot fallback: visual impression only, no copyable values

Explicit fallback prevents researcher from stuck-state if browser tool unavailable.

### Information Architecture: Sparse/Under-Filled Detection (Round 3 — Phase 2 Addition)

**New checklist item in Phase 2 (Information Architecture & Scannability):**

*Sparse/under-filled layout detection:*
- Scan template areas: are any grid/list/carousel slots empty despite data existing in the source array?
- Example: gallery grid showing 2 photos in a 12-photo container → visibly sparse
- Example: form with 3 fields rendered but `formSchema.fields` array has 8 items (others conditionally hidden?) → clarify
- Example: breadcrumb showing only 1 level when user is nested 3 deep → incomplete
- **Action:** Report the sparse areas found, DO NOT auto-fill. Ask user: "Should we show all data, paginate, or keep it sparse for this reason?" User decides.

**Why separate from content-density rule below:** Sparse detection is **observation only** (you've found a gap). Content-density rule is **decision with user input** (proposing to add content).

### Phase 4 Hard Rule: Content-Density Proposals Require User Approval (Round 3 — New Permanent Rule)

**Context:** After sparse-filled detection in Phase 2, Phase 4 might suggest "add data" or "show more fields" for density. Without explicit gate, vdesign could over-propose content bloat.

**New Hard Rule (applies all modes, not just `--wow`):**
```
❌ DO NOT auto-add fields/content/cards to improve density without explicit 
user approval. 

CORRECT: In Phase 4, if you've identified sparse areas in Phase 2, generate 
a list of 3-5 proposals: "Add these data fields? Paginate instead? Show 
breadcrumb at depth 2+?" Use AskUserQuestion with checkbox list. User 
approves each item. Only then do you render.

Exceptions: If user already provided data in input (e.g., "here's my 12-item 
gallery"), render all. If data is conditional (roles/permissions hide fields), 
explain the condition, don't propose to remove the condition.
```

**Phase 4 reordering consequence:** New step 8 added (list content-density proposals via `AskUserQuestion`). "Short report" (old step 8) moves to step 9. Ensures user sees and approves density changes before final output.

### Pattern Catalog Source Gap (Round 3 — Observation)

**Finding:** `premium-design-patterns.md` (33 lines, 8 patterns), `quiet-polish-patterns.md` (40+ lines, 15 patterns), `anti-slop-minimum.md` (inherited from prior work) — all written as curated design vocabulary with no citations.

**Assessment:** These files represent a valid **design vocabulary** (terms like "Tinted Sub-Card," "Icon Anchor," "Selection Transition" are coherent and implementable). However, they are **not empirically validated against top production sites**. Unknown whether all 8 Quiet Polish patterns appear frequently in CSS Design Awards winners, or whether they're reasonable extrapolations of the principle "quiet ≠ flat."

**Consequence:** With Phase 0 now directing researcher to Awwwards + citations, over time vdesign will accumulate **sourced** patterns (with URLs) that can replace or supplement these vocabulary-based patterns. First 2-3 rounds may show: "Awwwards sites do use Tinted Sub-Cards (yes), but rarely use Eyebrow Tags (no, we added that ourselves)." Iterative data will improve the catalog.

**Timeline:** This is not urgent; pattern vocabulary is defensible as a starting point. But after 5-10 `--wow` runs with sourced research, audit the catalog: which patterns appear in real sites? which are original vdesign inventions? which should be renamed or merged?

## What We Tried

1. **Traced actual improvements in ChatGPT redesign** — instead of "ChatGPT is free, Claude is constrained," identified each move: tinted box nesting, icon placement, pill labels, radio state color. All implementable in code; none required breaking hard rules.

2. **Investigated whether `--wow` needed broader suspension** — yes, domain-sensitivity bias was silently steering toward caution even under `--wow`.

3. **Created supplement pattern file** — rather than modify the shared `premium-design-patterns.md`, created vdesign-specific `quiet-polish-patterns.md` to avoid tonal collision with frontend-design skill's use of the same shared reference.

4. **Code review as constraint-propagation check** — deliberately ran subagent review before closing, which caught the Anti-Patterns contradiction that implementer missed.

## Root Cause Analysis

**Why the gap existed (Round 1):**

1. **Tier-of-patterns problem**: vdesign inherited a catalog (premium-design-patterns.md) optimized for loudness. Healthcare/education forms need a different energy. Instead of forcing the inherited catalog to accommodate both, create a supplement.

2. **Suspend narrowness**: Phase 3's original suspend blocked 3 specific aesthetic choices. But domain-sensitivity isn't a 3-item checklist — it's a broader implicit bias that whispers "tone it down" when the domain is sensitive. Widening the suspend from "these 3" to "all aesthetic caution" actually matches what the user meant by `--wow` (remove *all* aesthetic restraint).

3. **Silent contradictions**: Anti-Patterns bullets were fine when the suspend was narrow. When the suspend broadened, those bullets became contradictions without anyone noticing. Grep-before-edit would have caught it; code-review did.

**Why round 2 was needed (Root cause of Round 2 expansion):**

User's original ask was already solved (Quiet Polish tier landed, suspend broadened). But the *escalation* revealed a deeper gap: "quiet polish is not enough; I need vdesign to **exceed** ChatGPT's mockup on dimensions mockups can't show."

- **Mockups are frozen** — they show 1 screen, 0 interaction. User realized vdesign's interaction tier was still "correct but muted" (min-viable feedback), not *intentional* (delightful, specific, memorable).
- **Interaction suspension was implicit, not explicit** — Phase 3 said "suspend aesthetic caution" but whispered "interaction still defaults to conservative." That whisper needed to be overridden, making it explicit: "suspend interaction-tone caution too."
- **Motion patterns were missing** — vdesign had the *permission* to animate under `--wow`, but no *catalog* of specific patterns that feel crafted (not generic spin/fade). Quiet Polish patterns were all visual; Motion & Interaction had to be added.

Root cause: Suspend clauses are powerful but silent — they remove *prohibition*, but they don't add *direction*. Broadening the suspend answered "what's now allowed?" but didn't answer "what should I actually do?" Motion & Interaction patterns answer the second question.

**Why round 3 was needed (Root cause of Round 3 verification):**

After 2 rounds of fixes and code-review passes, user asked point-blank: "Is it really competitive with top Awwwards?" — forcing a hard re-verification rather than taking "passes review" at face value.

The answer revealed a **cross-phase scope contradiction** that survived 2 code-reviews:
- **Phase 0's constraint** (pre-Round 1): "research inside B2B bias, NOT Awwwards/portfolio inspiration" — a prohibition rule designed for cautious domain-sensitive work
- **Round 1's suspension** (Phase 3): "suspend aesthetic caution including portfolio/Awwwards prohibition" — lifted the prohibition under `--wow`
- **Result:** Two statements now coexist contradicting each other. Phase 0 still whispered "don't look at portfolios" while Phase 3 shouted "now you can."

Root cause: **Scope-limited code reviews.** Round 1 code-review checked "does Phase 3's suspend clause fix the contradiction we identified?" (Yes). Round 2 code-review checked "does Phase 3's Motion section cohere with hard rules?" (Yes, after Progress Fill fix). Neither reviewer was asked "does Phase 0 still assume the *old* scope of the suspend rule?" because Phase 0 was out of scope. The contradiction lived silently across the **boundary between research phase and design phase**.

**Secondary root cause:** Pattern catalog source gap. The files `quiet-polish-patterns.md` and `premium-design-patterns.md` are curated design vocabulary with no URLs or site citations. They work as a design language, but are not *validated* against real Awwwards winners — we don't know if top sites actually use Eyebrow Tags, or if that's vdesign's invention. Without sourced patterns, the claim "we're pulling from top sites" remains aspirational.

## Lessons Learned

1. **Trace specific moves, don't blame freedom differences.** "ChatGPT's mockup is prettier because it's not constrained" is lazy. The real question: which specific moves (icon, tint, card nesting) made the difference, and can vdesign do them under its own rules? This session: yes to all. The constraint wasn't the ceiling; the pattern catalog was incomplete.

2. **Shared reference files need domain-specific supplements, not retrofitting.** premium-design-patterns.md was never meant to serve "quiet polish" — it's meant to serve boldness. Rather than try to make it do both, vdesign got its own supplement tier. No collision, clean separation.

3. **When broadening a rule's scope, grep downstream consumers.** This session's Anti-Patterns bullet contradiction was a self-inflicted wound. Rule scope changes (from "3 items" to "all aesthetic caution") need to trigger a grep for "what else assumes the old scope?" — in code, comments, and human rules files. Code review caught this; implementer should have caught it first.

4. **Supplement ≠ Fallback.** The pattern-pull step now reads quiet-polish-patterns.md as a permanent addition ("always merge"), not as "use this if premium-design-patterns.md is missing." The distinction matters: supplement is always-on; fallback is "when the better thing isn't available." Under `--wow`, you want supplements (layered catalogs), not fallbacks (degradation).

5. **Self-contradiction within newly written prose requires independent review.** Round 2's Progress Fill Animation pattern contradicted itself — animate `width` (banned) in 300-400ms (outside announced range) — internally, not just against legacy code. This is harder to catch on self-read because you're reading your own work with momentum (trust that you're being consistent). The implementer did read it back once, but caught only the ghost of the idea ("this is a fill animation"), not the specifics (which transform? which range?). Code-reviewer's second pair of eyes, reading the pattern in context of "what does the hard rule say?" caught it. **Lesson: long technical specs with multiple constraints (GPU-safe transforms, time range, specific pattern) need a consistency audit by someone NOT writing it.** One self-review insufficient.

6. **Permission without direction is incomplete.** Broadening the `--wow` suspend from "these 3 aesthetic items" to "all aesthetic + interaction caution" answered "what's forbidden?" but left "what should I build?" unanswered. The model still had no concrete patterns to reach for. Motion & Interaction section filled that gap: 7 concrete moves with exact timings and easing. Suspension removes a gate; pattern catalog adds a map. Need both.

7. **Scope-limited code review can miss cross-phase contradictions.** Round 1 & 2 reviews checked Phase 3 (suspend clause, motion patterns) thoroughly, but never scanned Phase 0 (Domain Research). When Phase 0 still assumed the *old* scope ("don't research Awwwards") and Phase 3 was *broadening* that scope ("now research Awwwards actively"), the contradiction lived silently at the phase boundary. **Critical lesson:** When a rule's scope changes (from "these 3 specific items" → "all items in category X"), the review scope must expand to **grep downstream references to the old scope**. In this case: grep for "Awwwards," "portfolio," "clarity > impressiveness" across ALL files, not just the changed section. Find every place that currently assumes the narrower scope, and verify they cohere with the broader scope. Single-section reviews catch local bugs; full-file grep-before-edit catches cross-phase contradictions.

8. **Verification before claiming "competitive" requires sampling real sources.** Saying "vdesign is now competitive with Awwwards" is only true if vdesign's pattern catalog is *actually* sourced from Awwwards winners. Until Round 3, the patterns were curated vocabulary with no citations. Now Phase 0 mandates URL sourcing; over time, vdesign will accumulate empirically grounded patterns. First few rounds will show which patterns are *actually* common in top sites vs. which are reasonable-but-unverified extrapolations. Iteration builds credibility.

## Next Steps

**Round 1 monitoring tasks (from commit 2dd0d90):**

1. **Monitor real `--wow` output on sensitive domains.** Next M-CHAT-R form or healthcare/education redesign will show whether the broader suspend + Quiet Polish tier actually delivers polish without sacrificing domain-appropriateness. If the model now swings too far toward boldness, the suspend language needs a second iteration.

2. **Benchmark Quiet Polish patterns.** 8 patterns exist in the new file. Track whether all 8 get used, or whether a few dominate (icon anchor is probably #1). After 5-10 real runs, decide if any patterns need to be renamed, split, or merged.

3. **Guard against future rule-broadening regressions.** Create a grep pattern or lint rule to flag when a "suspend X" statement coexists with "❌ do X" bullets. Future rule broadening should trigger this check automatically.

**Round 2 monitoring tasks (from commit c57e957):**

4. **Motion & Interaction pattern adoption.** 7 new patterns exist; all require GPU-safe compliance + `prefers-reduced-motion` guard. After 5 real `--wow` runs with interactive flows, measure: which patterns appear? do timing ranges (250-350ms for most) feel right, or do users perceive lag/sluggishness? Do they hit the GPU-safe ceiling (avoid paint/layout) or does performance telemetry show reflows? Adjust timing or easing if real feedback diverges from design intent.

5. **Reference image surpass validation.** "Beating a reference image" is now explicit in Phase 3. Next time a user provides a Figma/mockup image as target, track the output: Does final design show measurable improvements on 4 axes (multi-screen consistency, real motion, precision tokens, responsive + a11y)? Do they feel additive or do they feel like over-engineering? Calibrate if needed.

6. **Toast celebration abuse.** Rule loosened to permit intentional celebratory toasts under `--wow` (form success, milestone unlock). Monitor whether vdesign adds toasts appropriately or over-uses them anyway (creeps back into "churn"). If over-use appears, might need sub-rule: "celebratory moment = user completed significant action (form with 5+ fields, multi-step flow); celebratory moment ≠ read a single article."

7. **Precision checklist enforcement.** Icon optical alignment + token-only spacing are new rigor requirements. Audit first 5 `--wow` outputs for compliance: are icon glyphs centered perceptually? do all spacings map to named tokens? Are custom icons line-weight appropriate? If vdesign ignores these, re-emphasize in prompt or add to hard rules.

8. **Self-contradiction detection in rule edits.** Round 2 caught Progress Fill Animation self-contradiction via code-review. Establish: whenever a technical-pattern catalog is expanded, flag it for second-pass review focusing on *internal* consistency, not just consistency with legacy code. Create checklist: "constraint consistency audit" for pattern specs with 2+ technical dimensions.

**Round 3 monitoring tasks (from commit 411782a):**

9. **Phase 0 domain research sourcing.** Researcher now pulls from Awwwards Site/Mobile + CSS Design Awards, must cite URLs. After first 3 `--wow` runs, audit researcher reports: Are URLs real and accessible? Do patterns mentioned in report actually appear on those URLs? If researcher starts citing URLs that don't support the pattern claim, re-tune instructions or provide researcher with curated Awwwards shortlist.

10. **Browser automation design-token extraction.** New orchestrator step attempts to run `getComputedStyle()` on production sites if browser tool available. After 2-3 runs, measure: Did computed-style values successfully extract? Did they help vdesign pick correct token values, or did they create noise (values that look right on one site but wrong for user's domain)? Does fallback text-only report work adequately when browser tool unavailable? Refine step if needed.

11. **Sparse/under-filled detection audit.** Phase 2's new checklist looks for empty template slots when data exists. After 3-5 real runs, measure: Was sparse detection accurate (did it flag real under-utilization)? Did user appreciate the proposal format (ask before auto-filling)? Or did users always say "show all data anyway"? If latter, might not need the detection step; redirect effort to content-density approval gate.

12. **Content-density proposal gate effectiveness.** Phase 4 now lists content-density suggestions via `AskUserQuestion`, requires user approval before rendering. After 3-5 runs: Did users approve most/all suggestions, reject most, or mix? If approving everything, gate might be unnecessary friction; if rejecting many, gate is protecting against over-bloat. Track approval rate and refine proposal quality if needed (maybe researcher isn't identifying *good* density improvements, just "more data = better").

13. **Cycle through code-review scope expansion.** After Round 3, establish new protocol: whenever a rule's scope changes (generalization or narrowing), the code-review must include a **grep-scope audit** step. Before review completes:
    - List all keywords that trigger the changed rule ("Awwwards," "portfolio," "aesthetic caution," etc.)
    - Grep entire vdesign SKILL.md + referenced pattern files for those keywords
    - For each match, verify: does it assume the old scope or the new scope? Any contradictions?
    - If contradictions found, file them as "scope-boundary findings" (separate from the code-review itself) and require resolution before commit
    This prevents Phase 0 ↔ Phase 3 blind spots.

---

**Related**: 
- Commit `2dd0d90` (Round 1: 4 files, 76 insertions)
- Commit `c57e957` (Round 2: 4 files, 42 insertions)
- Commit `411782a` (Round 3: 2 files, 12 insertions/4 deletions)
- Skills files: `skills/vdesign/SKILL.md`, `SKILL.vi.md`, `references/quiet-polish-patterns.md`, `references/quiet-polish-patterns.vi.md`
- User's before/after M-CHAT-R images (provided in session, not in repo)
- Related to prior v7.0.0 audit expansion (commit 7776e2a)
