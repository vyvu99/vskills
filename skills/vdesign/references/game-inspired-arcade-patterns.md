# Game-inspired/Arcade Patterns

A pattern tier for when the Design Brief's Aesthetic Boldness criterion (14) is *Game-inspired/Arcade* — art direction borrowed from game UI (HUD panels, glow/neon accents, tactile juice), never a fallback for other boldness picks and never merged by default like `quiet-polish-patterns.md`. Only read this file when criterion 14 is explicitly *Game-inspired/Arcade*.

**Scope boundary — art direction only, not gamification mechanics.** This tier is about how the UI looks and feels (visual/emotional language), never about adding points, levels, streaks, achievements, or unlock systems — those are product/feature decisions, out of scope for a redesign regardless of this criterion's answer.

The gap this closes: the loud catalog (`premium-design-patterns.md`) assumes "bold = editorial/landing-page energy" (glassmorphism, kinetic type, particle fields). Game-inspired assumes "bold = tactile/responsive energy" — every interactive surface confirms itself physically, HUD framing gives structure a diegetic feel, and motion carries weight instead of just easing smoothly.

## Panels & Surfaces

- **HUD Corner-Bracket Panel** — a content panel's corners get short bracket accents (`┌ ┐` / `└ ┘` style, 2-3px stroke, accent color) instead of a full rounded/square border, reading as a targeting reticle or game menu frame. Implementation: 4 small `::before`/`::after` pseudo-elements per corner (absolute-positioned `border-left`/`border-top` pairs), not a full border on the container — keeps the panel body visually open.
- **Chunky Tactile Border** — thick (3-4px), fully-saturated border on interactive surfaces (buttons, cards, input focus) instead of a thin 1px hairline — reads as a physical, pressable object rather than a flat web element. Pair with a matching thick `box-shadow` offset (`4px 4px 0 var(--accent)`, no blur) for a chunky "cel-shaded" depth cue.

## Feedback & Accents

- **Glow/Neon Accent Border** — an interactive element's border/ring carries a saturated `box-shadow` glow (`0 0 12px 2px var(--accent)`, 40-60% opacity) on hover/focus/active, instead of a plain color-shift — reads as an energized, powered-on state. Keep to one glow color per view (the accent token), never multiple neon hues competing.
- **Satisfying Press Ripple** — on tap/click, a circular `opacity`+`transform: scale()` ripple expands from the press point and fades out (200-300ms), confirming the hit registered — GPU-safe via a pseudo-element animated on `transform`/`opacity` only, never a real ripple library that touches layout.

## Motion & Interaction

Keep every move GPU-safe (`transform`/`opacity` only, never `width`/`height`/`top`/`left`) — game-feel is about *weight*, not duration; err toward overshoot/spring easing (`cubic-bezier(0.34, 1.56, 0.64, 1)`) rather than longer linear transitions.

- **Squash/Bounce Button Press** — on `:active`, a button scales down and slightly squashes (`scale(0.94, 0.90)`, ~80ms), then springs back past 100% before settling (`scale(1.02)` → `scale(1)`, overshoot easing) on release — confirms the press with physical weight, not just a flat `scale(0.98)` dampen.
- **Progress-Fill Weighty Easing** — a progress/XP-bar fill animates via `transform: scaleX(progress)` (never `width`) with an overshoot easing curve so it slightly overshoots the target fill then settles back, instead of a flat ease-out — reads as momentum, not a linear meter tick.
- **Reduced-motion guard** — every pattern here still needs a `prefers-reduced-motion` fallback (instant state change, no squash/bounce/overshoot) per the base Animation & Motion audit category — game-feel never skips this.

## When to reach for this tier

- Criterion 14 (Aesthetic Boldness) answered *Game-inspired/Arcade* → pull primarily from here, merged with Domain Research findings (step 7) when it ran.
- Any other criterion 14 answer → this file does not apply; use `premium-design-patterns.md` (bold/graphic energy) or `quiet-polish-patterns.md` (warm/restrained energy) instead.
- Even within a *Game-inspired/Arcade* run: don't stack every pattern on every surface — one HUD-bracket treatment for structural panels, tactile/glow feedback on the primary interactive path, is enough; overusing all of them at once reads as noisy, not energized.
