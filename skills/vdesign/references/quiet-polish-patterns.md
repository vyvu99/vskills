# Quiet Polish Patterns

A pattern tier for `--wow` that sits between the flat B2B default and the loud Awwwards catalog (`premium-design-patterns.md`). Use when the committed vibe calls for warmth/friendliness/refinement rather than boldness — a wellness/education/consumer-health form, an onboarding flow, a survey — not a landing-page hero. Always read and merge alongside whichever full catalog applies (`premium-design-patterns.md` or `anti-slop-minimum.md`'s archetypes) — this is a permanent supplement, not a fallback.

The gap this closes: the loud catalog assumes "more impressive = bigger effect" (glassmorphism panels, particle explosions, kinetic type). Quiet polish assumes "more impressive = more considered" — small, restrained, human-feeling moves that read as care, not decoration for its own sake.

## Grouping & Nesting

- **Tinted Sub-Card** — a distinct content block (a highlighted question, a callout, a summary) gets its own nested surface: a soft tint 1-2 steps off the page background (not stark white-on-white), generous rounded corners (16-24px), no heavy border — separation comes from the tint + spacing, not a hard line. Distinguishes it from surrounding flat content without adding a new elevation tier's shadow weight.
- **Secondary Background Tint** — the page background itself gets a soft, very low-saturation tint (a whisper of the brand hue, e.g. `hsl(brand-hue, 15%, 97%)`) instead of pure white/gray, so the primary content card reads as "the thing" sitting on a calm backdrop rather than everything being the same flat white.
- **Decorative Corner Wash** — a very soft, large-radius radial gradient blob (opacity 5-10%, brand hue) bleeding off one corner of a card/section — adds depth without a shadow, never competes with content contrast.

## Anchors & Iconography

- **Icon Anchor** — a single small (≤32px) custom line/duotone icon placed beside a title or section header as a friendly focal point (e.g. a book icon next to "Bộ công cụ", a heart icon next to a CTA). NOT a stock illustration scene — one glyph, one color (or two-tone), placed with intent. This is the #1 move that makes a redesign feel "cared for" without reading as decoration-for-decoration's-sake.
- **Soft Icon Chip** — the icon anchor sits inside a small circular/rounded-square chip with a tinted background (same tint family as the page background), giving it its own tiny elevation without a hard border.
- **Sparkle/Accent Mark** — a tiny decorative glyph (sparkle, dot cluster, short line flourish) placed adjacent to a heading or icon chip — used at most once per view, purely as a warmth signal, never load-bearing for meaning.

## Labels & Typography

- **Eyebrow Tag** — a small pill badge above a heading or question (`rounded-full px-2.5 py-0.5 text-xs`, tinted background matching the section) carrying a short label ("Câu 1", "Bước 2") — replaces plain inline "Label:" text prefixes with a visually distinct, lightly elevated tag.
- **Two-Weight Hierarchy** — pair a slightly heavier/larger title with a visibly lighter, smaller, muted-color subtitle directly beneath it — even one extra weight/color step of separation reads as considered typography instead of a flat single-size block of text.

## Selection & Input States

- **Radio-Card** — replace a segmented toggle/pill-button choice with a full-width or half-width card per option: rounded border, generous padding, and a filled-dot (or checkmark) indicator on the left that fills solid + border recolors to the accent when selected. Reads as more deliberate and touch-friendly than a bare outlined toggle pair.
- **Selected-State Warmth** — the selected option's card gets a soft tinted fill (not just a border color change) so selection is legible at a glance, not only on close inspection.

## Motion & Interaction

A static reference image (mockup, competitor screenshot, AI-generated concept) is frozen — it cannot show a transition. Real code can, and this is one of the clearest ways it should exceed a static reference, not just match its look. Keep every move GPU-safe (`transform`/`opacity` only, never `width`/`height`/`top`/`left`) and in the 150-350ms range — quiet polish is felt, not performed.

- **Selection Transition** — a Radio-Card's dot-fill and border-color animate in (150-250ms ease-out) when selected, instead of snapping instantly. The fill itself can scale from 0 to full rather than just appearing.
- **Progress Fill Animation** — a progress bar's fill animates smoothly to its new value on advance (250-350ms ease-out), never jump-cuts. GPU-safe implementation: a fixed-width track with an inner fill element animated via `transform: scaleX(progress)` (`transform-origin: left`), not by animating `width` directly.
- **Selected-Card Settle** — the newly-selected option's card does a very subtle scale pulse (e.g. `scale(1.02)` → `scale(1)`, ~150ms) on selection, reinforcing the Selected-State Warmth tint with motion, not just color.
- **Icon Chip Entrance** — an Icon Anchor's chip fades/scales in slightly after its container mounts (short stagger, ~80-120ms delay), rather than appearing simultaneously with everything else — small sequencing reads as considered.
- **Tactile Press Feedback** — any tappable surface (radio-card, button, chip) gets `scale(0.98)` on `:active` — confirms the tap registered before the async result does.
- **Completion Moment** — on genuinely completing a flow (not every minor action), a brief, restrained celebratory cue (a soft check-mark draw-in, a gentle scale/fade on a completion icon) is warranted — this is a deliberate vibe choice, not "unnecessary," but keep it to one moment per flow, not scattered.
- **Reduced-motion guard** — every pattern here still needs a `prefers-reduced-motion` fallback (instant state change, no animation) per the base Animation & Motion audit category — quiet polish never skips this.

## When to reach for this tier vs. the loud catalog

- Vibe is Soft Neumorphic / Organic Asymmetric / Maximal Minimal / Authentic Humanist / Flow-First System → pull primarily from here.
- Vibe is Neo-Brutalist / Chromatic Dopamine / Kinetic-Motion-First / Spatial 3D → pull primarily from `premium-design-patterns.md`, use this tier sparingly if at all (a single icon anchor can still work; tinted sub-cards usually don't fit a brutalist vibe).
- Either way: never combine more than 2-3 of these patterns in one view — quiet polish loses its effect if everything gets a tint, a chip, and a sparkle at once.
