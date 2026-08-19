---
name: vdesign
description: "Redesign existing UI/UX according to a personal aesthetic: refined, harmonious, modern, elegant, consistent with the system. Use when upgrading the UI of an existing page/component/feature/PR."
user-invocable: true
when_to_use: "Invoke when you want to redesign or upgrade the UI/UX of a page, component, feature, or an entire existing diff/PR."
category: frontend
keywords: [redesign, ui, ux, design, harmonious, refined, modern, elegant]
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--L1 | --L2 | --L3] [--bold]"
metadata:
  author: vyvu
  version: "5.1.0"
---

# vdesign — Personal UI/UX Redesign Skill

Upgrade or redesign UI/UX with a consistent aesthetic: **refined · harmonious · modern · elegant · consistent with the system**.

Three cumulative depth levels, plus an independent `--bold` flag:

| Flag | Level | Unlocks (cumulative on top of the previous level) |
|------|-------|------|
| `--L1` | Light | Spacing/alignment, icon size, text-overflow, missing states (loading/empty/error/hover/focus/active/disabled), color/token alignment, typography hierarchy. Does NOT touch layout/structure. |
| `--L2` | Structural | + swap/extract/merge components, change grid/flex structure, section order, density — visual direction stays the same (a card stays a card) |
| `--L3` | Full redesign | + change visual direction entirely (card→list, sidebar→top nav), rewrite JSX/TSX from scratch |
| _(none)_ | Ask | If wording is ambiguous, ask 1 question via `AskUserQuestion` listing the 3 levels — do not silently guess |

`--bold` (optional, requires `--L2` or `--L3`) — unlocks Awwwards-tier creative freedom; see Phase 3.

Do not change the tech stack. Do not break logic/state/API.

---

## Input Modes (7 types)

| Input | Handling |
|-------|------------|
| _(empty)_ | Ask the user 1 question: "Which part do you want to redesign?" |
| `localhost:PORT/path` or URL | Take a screenshot first → then read the corresponding source files |
| Route path (e.g. `/clients/[id]?tab=notes`) | Resolve to the corresponding pages/components files |
| Component/feature name (e.g. `TreatmentPlanWizard`) | Grep to find the file → read the entire component tree |
| `[Image]` / attached screenshot | Analyze the image → extract design gaps → apply fixes |
| `--pr` | `gh pr diff` to get changed files → redesign all UI files in it (requires gh, §2 of `repo-profile.md`; unavailable → falls back to `--diff`) |
| `--diff` | `git diff --name-only` to get staged/unstaged → redesign UI files |

---

## Personal Aesthetic (Non-negotiable)

This is the user's vocabulary — **ALL** must be met by default, not just a few picked at random. Suspended only when `--bold` is explicitly passed (see Phase 3):

| Keyword | Practical meaning in code |
|---------|--------------------------|
| **Refined** | Micro-details in the right place: consistent border-radius, even icon sizes, text-overflow handled, no odd spacing scale values |
| **Harmonious** | Color, font, spacing match the rest of the project; no "isolated island" of its own style |
| **Modern** | No outdated patterns (old-style bordered tables, old-style form labels, flat buttons with no state); makes good use of whitespace |
| **Elegant** | Clear hierarchy, low visual noise, no unnecessary decoration, clearly distinguished button hierarchy (primary/ghost/link) |
| **Consistent with the system** | Matches design tokens, component patterns, and the project's visual language — **this is the most important requirement** |
| **Accessible** | Information isn't hidden; labels are clear; important icons have tooltips; empty/loading/error states are all present |
| **Creative when permitted** | Distinct visuals are allowed when the user asks for "something different to add variety" — but must still stay consistent on spacing/color |

**DO NOT** apply portfolio/avant-garde aesthetics. Even a full redesign must still serve the B2B product context: **clarity > impressiveness**.

---

## Workflow: Scan → Audit → Fix → Verify

### Phase 0: Determine scope

1. Parse the argument to determine the input mode (see table above)
2. If there's a URL/localhost → **take a screenshot immediately** using `mcp__mimo__vision` or Playwright
3. If there's `--pr` → resolve the VCS profile per `~/.claude/skills/_vskills-shared/repo-profile.md` §2 first (if the file is absent, assume full gh mode — today's default). Full gh mode → `gh pr diff --name-only` to get the list of files. Degraded (no gh / non-GitHub) → print the §2 message and ask the user for a branch name, or fall back to `--diff` (`git diff --name-only`, needs no gh) — then continue into Phase 1 normally.
4. Resolve the Project Profile: check `.vdesign/profile.md` at the target project's git root (`git rev-parse --show-toplevel`). Present → read and use it. Absent → infer UI library/design tokens from `package.json` dependencies, `tailwind.config.*`, and the components folder. Still ambiguous → ask 1 question, then offer (don't force) to save the answer to `.vdesign/profile.md` for next time.
5. If empty → ask the user via `AskUserQuestion` — **exactly 1 question**
6. If `--bold` is set → **Domain Research**, before Vibe Commitment:
   - Domain slug = the domain from the Project Profile's context (e.g. "B2B Healthcare") + the target feature/page name resolved in step 1 (e.g. "booking form") — slugify (e.g. `healthcare-booking-form`)
   - Cache check: look in `plans/reports/` for `researcher-vdesign-bold-<slug>*.md` created earlier this session/today — present → read and reuse, skip straight to step 7
   - No cache → spawn 1 researcher agent (Task/Agent tool) to find current (2025-2026) UI/UX/animation/layout patterns specific to `<target feature>` in `<domain>` product context — must stay inside the B2B "clarity > impressiveness" bias (not pure Awwwards/portfolio inspiration); report concrete named patterns with sources. Save to `plans/reports/researcher-vdesign-bold-<slug>-<HHMMSS>.md`
   - Agent/search fails or unavailable → fall back silently to the static catalog only; note "domain research unavailable" in the Phase 4 short report
7. If `--bold` is set → **Vibe Commitment**, before touching any code: pick ONE aesthetic direction — an archetype from `~/.claude/skills/frontend-design/references/premium-design-patterns.md` (Ethereal Glass / Editorial Luxury / Soft Structuralism), a named 2025-2026 movement (Neo-Brutalism, Immersive 3D/WebGL, Kinetic Typography, Bento-interactive, Maximalist editorial), a custom vibe from the user's own reference/mood keywords, or a vibe informed by step 6's domain research report when one exists. If the user didn't specify one, propose the best-fit vibe for the project's domain and state it out loud before implementing — say which source (static catalog vs. domain research) grounded the pick. An un-anchored `--bold` run (no committed vibe) is the single biggest reason bold output still reads as generic/safe.

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
- Find a component in the project that serves as a **good reference** (the user often uses the booking form, notes, or sessions page as the standard) → read it to learn the pattern

**When the user says "like X" or "similar to X":**
→ MUST read component/page X first before implementing — do not guess the pattern

---

### Phase 2: Audit

Go through each category — only flag issues that **actually affect visual/UX quality**:

#### Typography
- [ ] Clear text hierarchy: heading > subheading > body > caption > muted?
- [ ] Font size consistent with the system (no mixing text-sm/text-xs arbitrarily)?
- [ ] Line-height and letter-spacing appropriate?
- [ ] Input field font size ≥ 16px (avoid zoom on mobile)?

#### Color & Surfaces
- [ ] Using CSS vars/Tailwind tokens — no hardcoded hex?
- [ ] Background/border/shadow consistent with same-type components elsewhere in the project?
- [ ] Sufficient contrast?
- [ ] Do active/selected/highlighted states have a distinguishing color?
- [ ] **NOT using the component's default color** (e.g. shadcn's default blue) — must use the system's primary color (`primary`, `accent` tokens)?

#### Layout & Spacing
- [ ] Padding/gap use a consistent spacing scale (no odd `p-[13px]` values)?
- [ ] Responsive is solid: mobile-first, no horizontal scroll?
- [ ] Correct layout container pattern: `container → header fixed → content overflow-y-auto → footer/input fixed`?
- [ ] Not using `h-screen` — using `min-h-[100dvh]`?
- [ ] Max-width container placed correctly?
- [ ] Consistent alignment (no mixing left/center arbitrarily)?

#### Components
- [ ] Using the correct component from the UI library instead of raw HTML?
- [ ] Clear button hierarchy: primary (filled) vs secondary (outline/ghost) vs tertiary (link/text)?
- [ ] Consistent icons (same library, same size)?
- [ ] Card: avoid a generic `border + shadow + white bg` if density is high — use spacing/divider instead?
- [ ] Form fields use `Form*` wrappers from the UI library (`FormTextField`, `FormSelectField`, etc.)?

#### Third-party Self-styled Components
Applies when encountering a component with `import 'lib/styles.css'` or that injects its own CSS: rich text editor (CKEditor, TipTap, Quill), code editor (Monaco, CodeMirror), date/color picker, react-select, map component, etc.

- [ ] **Double border check**: does the wrapper div add its own `border`/`shadow`? If the wrapper adds a border AND the component also has its own border → double border. Only one side should own the visual boundary.
- [ ] **Clear ownership**: wrapper div owns border/focus ring/error state → must null out all borders inside the component. Or the reverse: component self-styles → wrapper adds nothing.
- [ ] **Focus state**: focus ring managed in exactly one place — wrapper (via JS state `onFocus`/`onBlur`) or component CSS (`:focus-within`), not both.
- [ ] **Disabled state**: disabled must reflect on the wrapper's visuals too (opacity/pointer-events), not just pass the `disabled` prop into the component.

**When the wrapper owns the border — fix in this order:**
1. Override the lib's CSS custom properties at the wrapper class: `--ck-color-base-border: transparent`, `--select-border: transparent`, etc.
2. Scope `border: none !important; box-shadow: none !important` via the wrapper class for the lib's inner elements
3. Wrapper manages focus state via React `useState` + `onFocus`/`onBlur`, not CSS `:has(.ck-focused)`

#### States (Must all be present)
- [ ] **Loading**: skeleton or spinner within the component, not blank
- [ ] **Empty**: empty state has a clear message + CTA if needed
- [ ] **Error**: readable error message, no exposed stack trace
- [ ] **Hover**: action items (button, row) have a hover state
- [ ] **Focus**: visible focus ring for keyboard navigation
- [ ] **Active/Selected**: selected item has a visual indicator
- [ ] **Disabled**: disabled button has a visually distinct look + cursor-not-allowed

#### Animation & Motion
- [ ] Animation only where it has **meaning**: hover reveal, state transition, page enter
- [ ] Do not animate opacity of **child components** — only the container wrapper
- [ ] When hiding a component but needing to keep its state → use `opacity-0 w-0` / `visibility: hidden`, **DO NOT unmount**
- [ ] Action bar/toolbar → only show on hover (`group-hover:opacity-100`)
- [ ] Animation duration: subtle (150-300ms), not too flashy for a B2B app
- [ ] Has a `prefers-reduced-motion` guard if using CSS animation

#### Decorative Images & Illustrations (banner, hero character, background art)
- [ ] If an image needs to be full-bleed (spanning the full container width) using `object-contain` → the container MUST set `aspect-ratio` (or `style={{ aspectRatio: 'W/H' }}`) matching the image file's actual width/height ratio (read via PIL/`sips -g pixelWidth -g pixelHeight`, don't guess) — if the container and image aspect ratios mismatch, `object-contain` will letterbox on both sides even if width is declared full
- [ ] For full-bleed with acceptable minor cropping instead of computing aspect-ratio → use `object-cover` with `mask-image: linear-gradient(to bottom, transparent, black 10%, black 90%, transparent)` to fade the edges and hide the hard crop marks
- [ ] If an illustration needs to "grow" without taking up sibling (text/button) layout space → set `position: absolute` (not a normal flex/grid item); but still must reserve room for the adjacent text via `max-width: calc(100% - Npx)` or matching padding for the image size, to avoid overlapping text
- [ ] `float` + `shape-outside` (the technique where text automatically wraps around an image's contour) ONLY works when the element is a direct child of a **block container** — **it has no effect inside `flex`/`grid`** (the browser silently ignores `float`, no warning/error). If the parent must be flex, use `absolute` + `max-width` reservation instead of float
- [ ] Multiple cards in the same row with illustrations that need to align on the top or bottom edge → anchor the container with `top-0`/`bottom-0` (not both) AND set matching `object-position` on the same side (`object-top`/`object-bottom`) — do not rely on the images' natural aspect ratios happening to align, since each source image usually has a different content margin/bbox
- [ ] Equal-height cards in a `grid` (grid auto-stretches items equally) but the inner visual frame (border/bg/shadow) only auto-sizes to content → must set `h-full` on BOTH the outer wrapper (grid item) AND the inner visual frame, otherwise cards still end up mismatched in height even though the grid item stretched correctly
- [ ] A dynamic overlay (shine border, border beam, glow, floating badge) without an explicit `z-index` → a sibling with `position: relative` that appears LATER in the DOM will cover the overlay, because `z-index: auto` among positioned elements stacks by DOM order, not by "which one is intended to be on top"; always assign an explicit `z-index` to animation/decoration overlays

#### Form/Wizard Specific
- [ ] Stepper: compact height, no wasted vertical space
- [ ] Form layout: label + input aligned consistently
- [ ] Validation error: shown right below the field, not only at the top
- [ ] Multi-step wizard: clear progress indicator
- [ ] Reference: the booking form (create-booking) is the **gold standard** in the system

#### Table/List Specific
- [ ] Table header: typography clearly distinguished from data rows
- [ ] Row hover state present?
- [ ] Empty state when there's no data?
- [ ] Pagination UI sufficient?
- [ ] Action column: shown on hover or always visible?
- [ ] Responsive: less important columns hidden on mobile?

#### Mobile & Responsive

**Breakpoint strategy (Tailwind mobile-first):**
- [ ] Base styles written for mobile first — `sm:` / `md:` / `lg:` are overrides for larger screens, not the other way around
- [ ] Standard breakpoints used in the project: `sm` 640px · `md` 768px · `lg` 1024px · `xl` 1280px — don't add odd custom breakpoints
- [ ] Every breakpoint change must have a clear reason: layout collapse, font scale up, sidebar unhide, etc.

**Layout & Grid:**
- [ ] Multi-column grid MUST collapse: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` — no bare `grid-cols-3`
- [ ] Flex row on desktop → `flex-col` on mobile: `flex flex-col sm:flex-row`
- [ ] Sidebar layout: `hidden lg:block` sidebar + full-width content on mobile, or a Sheet/Drawer
- [ ] No fixed/absolute width (e.g. `w-[320px]`) without a responsive fallback
- [ ] Container max-width placed correctly: `max-w-5xl mx-auto px-4` — px-4 mobile, px-6 sm+

**Typography scaling:**
- [ ] Heading scales with viewport: `text-xl sm:text-2xl lg:text-3xl` — not a single fixed size for all
- [ ] Body text does not need to change size across viewports (text-sm/text-base is already fine)
- [ ] Input/textarea font-size ≥ 16px on mobile to avoid iOS auto-zoom

**Touch & Interaction:**
- [ ] Touch targets ≥ 44×44px for every interactive element (button, link, checkbox, toggle)
- [ ] Hover-only interactions MUST have a mobile fallback: action buttons always visible, not only `group-hover:`
- [ ] Spacing between touch targets: gap ≥ 8px to avoid fat-finger errors

**Overflow & Scroll:**
- [ ] No horizontal scroll on mobile (`overflow-x-hidden` on root if needed)
- [ ] Table on mobile: `overflow-x-auto` wrapper or collapse into a card layout
- [ ] Long text/email/URL: `truncate` or `break-all` on mobile — don't let it overflow

**Images & Media:**
- [ ] Sized image component + container with an explicit size — no layout shift. Component name is conditional on the detected framework (§3 of `repo-profile.md`): Next.js → `next/image` with `fill`; Nuxt → `NuxtImg`; Astro → `astro:assets` `<Image>`; generic → the project's own image component with explicit width/height or an aspect-ratio container, ask the user if none is discoverable. The same §3 conditionality applies to any other framework-specific API named elsewhere in this checklist.
- [ ] Decorative/hero images: `objectPosition` ensures the subject is visible in the mobile crop
- [ ] Avatar/thumbnail responsive size: `size-8 sm:size-10` if needed

**Navigation & Modal:**
- [ ] Dropdown menu: wide enough on mobile, not cut off
- [ ] Modal/Dialog: full-screen or `max-h-[90dvh] overflow-y-auto` on mobile — not a fixed height
- [ ] Sheet from bottom on mobile instead of a centered Dialog
- [ ] Sticky header has a more compact height on mobile (`py-2 sm:py-4`)

**Safe areas (iOS/Android):**
- [ ] Fixed bottom elements: `pb-safe` or `padding-bottom: env(safe-area-inset-bottom)` on iOS
- [ ] Fixed top: `pt-safe` if the notch needs to be respected
- [ ] Not using `h-screen` — using `min-h-[100dvh]` to avoid mobile browser chrome issues

**Responsive spacing:**
- [ ] Section padding: `py-6 sm:py-8 lg:py-12` — mobile usually needs less whitespace than desktop
- [ ] Card padding: `p-4 sm:p-5 lg:p-6` — don't fix large padding for every viewport
- [ ] Grid gap: `gap-3 sm:gap-4 lg:gap-6`

#### Scrollbar
- [ ] Scrollbar doesn't eat into content width → use an overlay scrollbar (`scrollbar-thin` Tailwind plugin or CSS `scrollbar-width: thin; scrollbar-color: transparent transparent` with `:hover` reveal)
- [ ] Scrollbar background: transparent
- [ ] Scroll-to-bottom button (if present): placed centered, near the input, not fixed to the right corner

#### Tooltip & Popover
- [ ] Tooltip style consistent across the whole project — not left as default unstyled?
- [ ] Chart tooltips: consistent format/style, text-justify for Vietnamese content?
- [ ] Popover: opacity animation + rounded corners matching the style system (not using shadcn defaults if the project has already customized it)?
- [ ] Tooltip only used when truly necessary — if the UI is already clear, skip the tooltip

#### Badge & Tag
- [ ] Badge compact, not oversized relative to its content?
- [ ] Can the badge be pinned to the card's top border when visual separation is needed?
- [ ] Badge color uses semantic tokens (status, category), not hardcoded?

#### Tab & Navigation
- [ ] Tabs within the same page/card must match each other in style — check cross-component tab consistency?
- [ ] Do date/time tabs match the calendar header tabs when in the same scope?
- [ ] Sidebar inside a Sheet/Drawer: consistent with the system's main sidebar?

#### Sticky & Scroll Behavior
- [ ] Back button / header shrinks compactly when sticky on scroll?
- [ ] Sticky header doesn't cover content below it (enough padding-top for content)?

---

### Phase 3: Fix

Apply fixes only within the current level's unlocked scope (cumulative):

| Level | Fix scope unlocked |
|-------|------|
| `--L1` Light | Spacing & alignment, icon size, text-overflow, missing states (empty/loading/error/hover/focus/active/disabled), color/token alignment, typography hierarchy — grid/flex structure stays as-is |
| `--L2` Structural | + swap/extract/merge components, replace grid/flex structure, section order, density — visual direction stays the same |
| `--L3` Full redesign | + fully change visual direction (card → list, sidebar → top nav), rewrite JSX/TSX from scratch — reuse existing data/hooks/handlers |

Findings outside the current level's scope are still reported to the user (never silently dropped), with a note on which `--L` would unlock the fix.

**`--bold` (optional, requires `--L2` or `--L3`)**
If passed with no level, or with `--L1`, bump to `--L3` and tell the user why. Suspends for this run only: "DO NOT apply portfolio/avant-garde aesthetics", the "clarity > impressiveness" default bias, and the anti-pattern "Copy creative design from a landing page/portfolio into product UI" — allows bespoke art direction, expressive typography scale, unique/asymmetric layout, custom motion.

Requires the Vibe Commitment from Phase 0 step 7 first — pick the vibe, then pull patterns. Never pull patterns first and rationalize a vibe after the fact.

**Pattern-pull, not audit-fix.** Once the vibe is committed, pull 3-5 concrete named patterns from that vibe's arsenal — see `~/.claude/skills/frontend-design/references/premium-design-patterns.md` for the full catalog (navigation, layout, card, scroll-driven animation, kinetic typography, micro-interaction patterns) — plus any domain-specific patterns/insights from Phase 0 step 6's domain research report, if one exists for this run. Merge the two, don't replace the catalog. Phase 2's audit still runs (it catches broken states/a11y/responsive) but under `--bold` it's a floor, not a ceiling — bold output is judged by how distinctive the pulled patterns are, not just by absence of defects.

**Dependency allowlist — add directly, no need to ask:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), native CSS scroll-driven animations / View Transitions API, Rive, Lottie — the de-facto standard toolkit on 2025-2026 award-winning sites.
**Still stop-and-ask:** React Three Fiber/Three.js (650KB+ — only if 3D is genuinely core to the concept), Barba.js, any paid/SaaS tool beyond Rive, custom WebGL/GLSL shaders.

**Anti-slop gate before reporting done** — see `~/.claude/skills/frontend-design/references/anti-slop-rules.md` for the full checklist; at minimum fail the run on: Inter/Roboto as the only typeface, purple-to-blue gradient as the dominant aesthetic, 3+ visually-identical cards in a row, placeholder names/numbers ("John Doe", round 50%/$100), generic startup copy ("Elevate", "Seamless", "Next-Gen"), pure `#000000` background, missing hover/focus states.

Still mandatory even under `--bold`: accessibility (contrast, focus rings, all required states), no tech-stack migration, no logic/state/API changes, GPU-safe motion only (`transform`/`opacity` — never animate `width`/`height`/`top`/`left`; B2B mobile LCP is already tight, bold must not blow the budget).

**Hard rules (apply to every level, including `--bold`):**
- ✅ Work with the existing tech stack — DO NOT migrate framework
- ✅ DO NOT break logic/state/API — only change the presentation layer
- ✅ Check `package.json` before adding a dependency — except the `--bold` allowlist above, which may be added directly
- ✅ When hiding (not deleting) → use opacity/visibility, don't unmount
- ✅ Use Tailwind tokens — no hardcoded hex
- ✅ Use the best-looking component in the project (booking form, notes UI) as the reference standard
- ✅ **Responsive is mandatory**: every layout change MUST be verified at 3 viewports — mobile (375px), tablet (768px), desktop (1280px); write mobile-first, then override with sm:/lg:
- ✅ Third-party styled component (has `import 'lib/*.css'`) wrapped in a wrapper div → wrapper owns ALL visual state (border, ring, disabled opacity); null out all border/shadow inside the component via CSS var override + scoped `!important`
- ❌ DO NOT add complex animation if Motion/Framer isn't already in the project — exception: under `--bold`, the dependency allowlist above applies instead
- ❌ DO NOT add new brand colors — only use existing tokens (exception: `--bold` may introduce a new accent if the committed vibe requires it)
- ❌ DO NOT use the component library's default color (shadcn blue) if the project has its own primary color
- ❌ DO NOT add unnecessary toast notifications
- ❌ DO NOT change logic/API/state management

---

### Phase 4: Verify

1. If there was an initial URL/localhost → take an after screenshot, compare before/after
2. If there was an image input → verify the code matches the image's intent
3. Run `pnpm format` (if the project has it)
4. If you just edited an image file directly under `public/` (overwritten at the same path, name unchanged) and the user reports "not seeing the change" → don't rush to edit the code/image again; tell the user to hard-refresh or clear `.next/cache/images` + restart the dev server first — Next.js Image Optimizer caches by URL+size, not by file content, so the fix is likely already correct but an old cached version is still being served
5. **Short report**: "Redesigned [X]. Main changes: [list 3-5 bullet points]"
   - No long summary
   - Only mention significant changes
   - If `--bold` ran: 1 line noting whether Phase 0 step 6's domain research was used (fresh or cached) or fell back to the static catalog only

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
- ❌ Add flashy animation to a healthcare app
- ❌ Copy creative design from a landing page/portfolio into product UI
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
- ❌ Add unnecessary toast notifications
- ❌ Let the scrollbar eat into the content area's width — always use an overlay/transparent scrollbar
- ❌ Inconsistent tab style within the same page — check cross-component tab consistency
- ❌ Guess a component's pattern "like X" — MUST read X first
- ❌ `float` / `shape-outside` inside a `flex` or `grid` container — has no effect, the browser silently ignores it (no error, no warning), causing confusing layout breakage
- ❌ Decorative overlay (shine border, border beam, floating badge, glow) without an explicit `z-index` — a sibling with `position: relative` appearing later in the DOM will cover it due to DOM-order stacking when `z-index: auto`
- ❌ Full-bleed image using `object-contain` without matching the container's `aspect-ratio` to the image file's actual ratio — gets letterboxed on both sides even though the container is full width
- ❌ Setting `h-full` only on the grid item wrapper while forgetting to set it on the inner visual frame (border/bg/shadow) too — cards still end up mismatched in height even though the grid stretched items equally
- ❌ Forcing `line-clamp`/fixed height onto copy of varying length across parallel cards instead of rebalancing the text length — line-clamp is a band-aid, rebalancing the copy is the actual root fix for "harmoniousness"
- ❌ Run a low level (e.g. `--L1`) but change layout/visual direction anyway — stay within the current level's unlocked scope, report out-of-scope findings instead of fixing them
- ❌ Run `--bold` without committing to a vibe first (Phase 0 step 7) — un-anchored boldness still reads as generic/safe; picking patterns before picking a direction produces a grab-bag, not a coherent design
- ❌ Re-run domain research for a domain-slug already cached this session/day (Phase 0 step 6) — check `plans/reports/` first, reuse instead of re-researching

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
