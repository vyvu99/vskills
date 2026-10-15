# Phase 2 Audit Checklist

Read this file in full at Phase 2 and go through each category — only flag issues that **actually affect visual/UX quality**.

**Framework-conditional syntax note:** items use Tailwind/React shorthand (`grid-cols-*`, `sm:`, `next/image`, etc.) as illustrative shorthand for the underlying CSS/UX concept, not a literal requirement — translate to the project's equivalent mechanism for other stacks (CSS Modules, Chakra, Vue/Svelte, plain CSS), e.g. `sm:` → breakpoint mixin/media query, `next/image` → the project's sized-image component (§3 of `repo-profile.md`).

---

#### Typography
- [ ] Clear text hierarchy: heading > subheading > body > caption > muted?
- [ ] Font size consistent with the system (no mixing text-sm/text-xs arbitrarily)?
- [ ] Line-height and letter-spacing appropriate?
- [ ] Input field font size ≥ 16px (avoid zoom on mobile)?

#### Color & Surfaces
- [ ] Using CSS vars/Tailwind tokens — no hardcoded hex?
- [ ] Background/border/shadow consistent with same-type components elsewhere in the project?
- [ ] **Contrast — measure, don't guess**: resolve actual fg/bg color values (CSS vars, Tailwind config, or literal hex/rgb), compute WCAG relative luminance (`L = 0.2126*R + 0.7152*G + 0.0722*B`, linearized sRGB) and contrast ratio `(L1+0.05)/(L2+0.05)`. Report PASS/FAIL vs 4.5:1 (normal text) / 3:1 (large text ≥18pt/14pt-bold, non-text UI per SC 1.4.11). Can't resolve statically (runtime-computed, external design system) → **"NOT MEASURED — verify manually"**, never assume PASS.
- [ ] Do active/selected/highlighted states have a distinguishing color?
- [ ] **NOT using the component's default color** (e.g. shadcn's default blue) — must use the system's primary color (`primary`, `accent` tokens)?

#### Depth & Elevation
- [ ] Elevation tiers defined (3-5 named levels: base/card/elevated-card/overlay) and consistently assigned — each surface type always uses the same tier?
- [ ] Shadows come from a fixed token scale (sm/md/lg/xl) — no ad-hoc box-shadow values?
- [ ] Light source consistent across all shadows (same offset direction/ratio)?
- [ ] Z-index from a defined scale (dropdown < sticky < modal < toast) — no arbitrary `z-[9999]`; modals/toasts render via portal to avoid stacking-context traps?
- [ ] Cards/panels use border + minimal shadow; heavier shadow reserved for floating elements (modal, popover, FAB) only?
- [ ] Blur/glass effects (if used) only on overlays, not on primary content surfaces?
- [ ] No unintended stacking traps: sticky/opacity/transform parents don't accidentally clip child dropdowns/popovers?

#### Layout & Spacing
- [ ] Padding/gap use a consistent spacing scale (no odd `p-[13px]` values)?
- [ ] Responsive is solid: mobile-first, no horizontal scroll?
- [ ] Correct layout container pattern: `container → header fixed → content overflow-y-auto → footer/input fixed`?
- [ ] Not using `h-screen` — using `min-h-[100dvh]`?
- [ ] Consistent alignment (no mixing left/center arbitrarily)?

#### Components
- [ ] Using the correct component from the UI library instead of raw HTML?
- [ ] Clear button hierarchy: primary (filled) vs secondary (outline/ghost) vs tertiary (link/text)?
- [ ] Consistent icons (same library, same size)?
- [ ] Card: avoid a generic `border + shadow + white bg` if density is high — use spacing/divider instead?
- [ ] Form fields use `Form*` wrappers from the UI library (`FormTextField`, `FormSelectField`, etc.)?
- [ ] Icon usage follows a consistent semantic mapping — the same icon always means the same action/concept across the app, not swapped arbitrarily?
- [ ] Icon-only buttons/controls have an accessible label (`aria-label` or equivalent) — not relying on the icon alone?

#### Proportion & Scale Harmony
- [ ] Font sizes across the page/component derive from a single modular scale (base × ratio^n: Perfect Fourth 1.333 / Major Third 1.25 / Golden Ratio 1.618) — no arbitrary in-between sizes?
- [ ] Spacing values (padding/margin/gap) are all multiples of the project's base grid (8px, secondary 4px) — no odd values like `p-[13px]`?
- [ ] Distinct value count stays bounded: ≤6-7 font-size, ≤10 spacing, ≤3-4 border-radius values per page/component — flag "orphan" values used only once?
- [ ] Icon size proportional to adjacent text — icon height ≈ line-height of the text beside it?
- [ ] Same-variant components (all primary buttons, all inputs) share identical height/padding — no silent drift between instances? Verify via the actual shared class/style, not a per-instance visual pass.
- [ ] Vertical rhythm: gaps between stacked elements are multiples of the base line-height, not arbitrary?
- [ ] Icon optical alignment: the icon's visual glyph (not its container box, which often has built-in padding) is centered against the text's cap-height/x-height — a self-centered container can still look off against text?
- [ ] Every spacing/radius value in the diff resolves to an actual declared token (Tailwind scale, CSS var) — no near-token approximation (`p-[15px]` "close enough" to `p-4`) that silently breaks the grid?

#### Third-party Self-styled Components
Applies when encountering a component with `import 'lib/styles.css'` or that injects its own CSS: rich text editor (CKEditor, TipTap, Quill), code editor (Monaco, CodeMirror), date/color picker, react-select, map component, etc.

- [ ] **Double border check**: wrapper div AND the library component both drawing a border/shadow → double border; only one side should own the visual boundary.
- [ ] **Clear ownership**: wrapper div owns border/focus ring/error state → must null out all borders inside the component. Or the reverse: component self-styles → wrapper adds nothing.
- [ ] **Focus state**: focus ring managed in exactly one place — wrapper (via JS state `onFocus`/`onBlur`) or component CSS (`:focus-within`), not both.
- [ ] **Disabled state**: disabled must reflect on the wrapper's visuals too (opacity/pointer-events), not just pass the `disabled` prop into the component.

**When the wrapper owns the border — fix in this order:**
1. Override the lib's CSS custom properties at the wrapper class: `--ck-color-base-border: transparent`, `--select-border: transparent`, etc.
2. Scope `border: none !important; box-shadow: none !important` via the wrapper class for the lib's inner elements
3. Wrapper manages focus state via React `useState` + `onFocus`/`onBlur`, not CSS `:has(.ck-focused)`

#### States (Must all be present)
- [ ] **Loading**: skeleton or spinner within the component, not blank — skeleton shape mirrors the actual content layout (a card skeleton looks like a card, not a generic gray block); for multi-part content, reveal progressively (outline → text → images) rather than a single flat reveal
- [ ] **Empty**: empty state has a clear message + CTA if needed
- [ ] **Error**: readable error message, no exposed stack trace
- [ ] **Hover**: action items (button, row) have a hover state
- [ ] **Focus**: visible focus ring for keyboard navigation
- [ ] **Active/Selected**: selected item has a visual indicator
- [ ] **Disabled**: disabled button has a visually distinct look + cursor-not-allowed

#### UX Efficiency & Reduced Interaction
- [ ] Visible choice count in one view ≤5-7 (Hick's Law) — more than that → group or progressively disclose?
- [ ] Form with >7 visible fields → split into steps or collapsible sections?
- [ ] List/table with repeatable row actions → supports multi-select + bulk action, not only one-at-a-time?
- [ ] Editing a single simple field (status, name) doesn't force navigation to a new page/full modal when inline-edit is viable?
- [ ] Low-risk, reversible actions (toggle, archive) proceed directly with undo, not a confirmation dialog; only destructive/irreversible actions get a confirm step?
- [ ] Frequently-reused values (last filter, last selection) are remembered client-side (localStorage/session) instead of resetting every time?
- [ ] Feedback for any action appears within 400ms (Doherty Threshold) — optimistic UI update or a loading indicator, never a silent wait?
- [ ] Dropdown/select with >10 options has a search/filter input, not a bare scroll list?

**Scope note (UX Efficiency + Content Design & Error Prevention):** fixes here commonly only need frontend interaction state (React state/hooks, localStorage) — when a fix genuinely needs a new/changed API endpoint (e.g. a true bulk-delete endpoint), implement it directly (API/service layer is in scope, see `SKILL.md`'s hard rules) rather than faking it client-side; DB schema/migration changes stay out of scope regardless.

#### Information Architecture & Scannability
- [ ] **View-type fit**: does the chosen view type (table, card grid, kanban, timeline, master-detail, calendar, tree, etc. — picked for what the data/task calls for) match the data shape and task named in Phase 1's Real User & Purpose step, or force an awkward fit (e.g. nested data crammed into a flat table)?
- [ ] **Generic-repetition check**: sections/cards with meaningfully different content/purpose rendered as identical generic boxes just for visual sameness — flag the genericness itself (not a safe default) and restructure each section's layout to fit its actual content.
- [ ] A field Phase 1's task actually needs is missing from the view because it was never fetched at all (not just fetched-but-unrendered — see Sparse/under-filled below)? Trace whether it already exists upstream (DB column, service-layer data) — if so, wire it through the API/service layer (never invent it client-side) and surface it, subject to Phase 4's content-exposure confirmation; if it doesn't exist upstream either, flag it as a product/backend dependency instead.
- [ ] Above-the-fold content on a dense page/dashboard prioritizes the highest-value info top-left (F-pattern) — critical KPI/action isn't buried below the fold?
- [ ] Dense data table row height matches the actual user: comfortable default (~48-52px, fewer rows/viewport) for mixed/occasional users, compact option (~28-32px) for power-user/analyst contexts — not picked arbitrarily?
- [ ] A list/table with many items provides a way to scan key info without opening each row individually (column choice, summary badges) — not forcing per-row drill-down for basic comparison?
- [ ] Progressive disclosure used for dense dashboards: overview first, drill-down for detail, not everything rendered at once?
- [ ] **Sparse/under-filled check**: does the view read as empty/thin relative to its whitespace when the underlying data/props/API response already carries fields that aren't currently rendered, or when the backing DB schema carries a field never even fetched? Compile these as content-exposure candidates — never invent data to fill space — for Phase 4's single batched confirmation before wiring them into the API/service layer and the UI (see `SKILL.md` Hard rules).

#### Accessibility (WCAG 2.2)
- [ ] **2.4.11 Focus Not Obscured**: is a focused element ever fully hidden behind a sticky header/cookie banner/other overlay?
- [ ] **2.5.7 Dragging Movements**: does every drag-and-drop interaction have a click/tap alternative (not drag-only)?
- [ ] **3.3.8 Accessible Authentication**: does the login flow avoid blocking password paste, and avoid requiring a cognitive puzzle with no alternative?
- [ ] Tab order follows the visual/logical reading order, not accidental DOM-insertion order?
- [ ] A skip-to-content link is the first focusable element on pages with repeated navigation/headers?
- [ ] Composite widgets (tabs, menus, comboboxes) support arrow-key navigation within the widget (roving tabindex) per WAI-ARIA APG, not just Tab-only navigation?
- [ ] Escape key closes the topmost modal/popover as a standard convention?

#### Animation & Motion
- [ ] Animation only where it has **meaning**: hover reveal, state transition, page enter
- [ ] Do not animate opacity of **child components** — only the container wrapper
- [ ] When hiding a component but needing to keep its state → use `opacity-0 w-0` / `visibility: hidden`, **DO NOT unmount**
- [ ] Action bar/toolbar → only show on hover (`group-hover:opacity-100`)
- [ ] Animation duration: subtle (150-300ms), not too flashy for a B2B app
- [ ] Has a `prefers-reduced-motion` guard if using CSS animation

#### Media & Images (banner, hero character, background art, video)
- [ ] Full-bleed image with `object-contain` → container MUST set `aspect-ratio` matching the image's actual W/H (measure via PIL/`sips -g pixelWidth -g pixelHeight`, don't guess) — a mismatched ratio letterboxes the image even at full width
- [ ] For full-bleed with acceptable minor cropping instead of computing aspect-ratio → use `object-cover` with `mask-image: linear-gradient(to bottom, transparent, black 10%, black 90%, transparent)` to fade the edges and hide the hard crop marks
- [ ] Illustration must "grow" without taking sibling (text/button) layout space → `position: absolute`, but still reserve room for adjacent text via `max-width: calc(100% - Npx)` or matching padding, to avoid overlap
- [ ] `float` + `shape-outside` (text wraps around an image's contour) only works as a direct child of a **block container** — no effect inside `flex`/`grid` (browser silently ignores it, no warning). If the parent must be flex, use `absolute` + `max-width` reservation instead
- [ ] Multiple cards in the same row with illustrations that need to align on the top or bottom edge → anchor the container with `top-0`/`bottom-0` (not both) AND set matching `object-position` on the same side (`object-top`/`object-bottom`) — do not rely on the images' natural aspect ratios happening to align, since each source image usually has a different content margin/bbox
- [ ] Equal-height cards in a `grid` (grid auto-stretches items equally) but the inner visual frame (border/bg/shadow) only auto-sizes to content → must set `h-full` on BOTH the outer wrapper (grid item) AND the inner visual frame, otherwise cards still end up mismatched in height even though the grid item stretched correctly
- [ ] A dynamic overlay (shine border, border beam, glow, floating badge) without an explicit `z-index` → a sibling with `position: relative` that appears LATER in the DOM will cover the overlay, because `z-index: auto` among positioned elements stacks by DOM order, not by "which one is intended to be on top"; always assign an explicit `z-index` to animation/decoration overlays
- [ ] **Illustration slop check**: unmodified unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps illustration in hero/empty-state/onboarding → flag as slop, same tier as purple-gradient/Inter-only (see anti-slop gate in `SKILL.md`). Fix by tier: custom hand-drawn > line-art/sketch > isometric 3D > heavily-customized flat (own palette + custom poses, not stock scenes) > geometric/abstract > skip illustration entirely.
- [ ] **Hero video** (when present): `muted autoplay loop playsinline` + static poster fallback (JPEG); swap to static image on mobile (`max-width: 768px`) to protect LCP.
- [ ] **Responsive art direction** (when mobile/desktop need different compositions, not just a scaled-down size): use `<picture>` + media-query `<source>` for different crops, not one image stretched/shrunk by CSS alone.

#### Form/Wizard Specific
- [ ] Stepper: compact height, no wasted vertical space
- [ ] Form layout: label + input aligned consistently
- [ ] Validation error: shown right below the field, not only at the top
- [ ] Multi-step wizard: clear progress indicator
- [ ] Reference: use the Project Profile's "Good reference UI" entry as the gold standard for form/wizard patterns — absent → the best-executed form already in the project

#### Content Design & Error Prevention
- [ ] Button labels are outcome-specific (verb + object, e.g. "Create report") — not generic ("Submit", "OK") when a more specific label is available?
- [ ] Error messages state what's wrong AND what to do next — not just "Invalid input"?
- [ ] Validation timing: don't validate on every keystroke — validate on blur first, then (if failed) re-validate on change until fixed?
- [ ] Where format matters (phone, date, currency), the expected format is visible before the user types (placeholder/hint), not only revealed after an error?
- [ ] Input masking/constraints prevent invalid entry where feasible (e.g. date picker blocks invalid dates) rather than relying solely on after-the-fact validation?
- [ ] Empty-state and success-message copy gives context + a clear next action, not just a status statement?
- [ ] Destructive/high-stakes action labels are specific about consequence (e.g. "Delete 12 records" not just "Delete")?

**Scope:** validation-timing and input-masking items follow the same scope note as UX Efficiency above.

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

**Responsive spacing:**
- [ ] Section padding: `py-6 sm:py-8 lg:py-12` — mobile usually needs less whitespace than desktop
- [ ] Card padding: `p-4 sm:p-5 lg:p-6` — don't fix large padding for every viewport
- [ ] Grid gap: `gap-3 sm:gap-4 lg:gap-6`

#### Theming & Dark Mode
Applies only if the project has dark mode / a theme toggle. Skip this category entirely if the project is light-mode-only.
- [ ] Contrast ratios are re-verified separately in dark mode — a pair passing in light mode is NOT assumed to pass in dark?
- [ ] Dark mode background avoids pure `#000000` — uses a soft dark tone (e.g. `#121212`-`#1E1E1E` range) to avoid halation?
- [ ] Shadows in dark mode use higher opacity (~40-70%) or an elevation-tint (lighter surface color per tier) instead of reusing light-mode shadow values?
- [ ] Images/icons/illustrations adapt to dark mode (no white-box artifacts around transparent PNGs, no illegible dark-on-dark icons)?

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
