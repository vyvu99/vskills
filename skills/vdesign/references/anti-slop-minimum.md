# Anti-Slop Minimum Catalog

Fallback pattern catalog and anti-slop checklist for `--wow`, used only when `~/.claude/skills/frontend-design/references/{premium-design-patterns,anti-slop-rules}.md` are not installed on this machine. Written independently for `vdesign` from general, well-known UI/UX and anti-slop-design knowledge — not derived from `frontend-design`'s catalog.

## Archetype patterns (fallback for the full pattern catalog)

Pick the pattern that matches the committed vibe (Phase 0 step 7) and apply it consistently across navigation, layout, cards, motion, and typography — not just one surface.

1. **Editorial / Magazine Layout** — asymmetric grid, oversized pull-quotes or section numerals, generous whitespace, type-led hierarchy (size/weight carry it, not color). Cards: full-bleed image + caption, no uniform borders. Navigation: minimal, text-only, brand top-left + links right-aligned. Motion: content fades/slides in on scroll, no bounce. Micro-interactions: underline-on-hover for links, no button ripple.
2. **Brutalist / High-Contrast** — pure black/white (or one saturated accent) base, thick 2-4px borders instead of shadows, sharp or minimal corner radius, a single heavy display typeface for headings. Cards: hard-edged, visible borders, no blur/gradient. Navigation: exposed structure — visible grid lines, sharp dividers. Motion: snap transitions, no soft easing. Micro-interactions: color invert on hover/focus instead of shadow lift.
3. **Soft / Organic** — rounded corners (12px+), soft multi-layer shadows or frosted-glass surfaces, muted/pastel palette, curved section dividers instead of straight lines. Cards: soft shadow + rounded, gentle scale-up on hover. Navigation: pill-shaped active indicator. Motion: eased, springy transitions (200-350ms ease-out). Micro-interactions: gentle scale/opacity change on hover, no hard color swaps.

## Anti-slop fail conditions (fallback for the full checklist)

Fail the `--wow` run if any of these ship unaddressed — the same 8 conditions this skill already treats as its non-negotiable floor:

1. Inter or Roboto used as the only typeface (default-feeling, no committed voice)
2. Purple-to-blue gradient as the dominant aesthetic
3. 3+ visually-identical cards in a row with no visual hierarchy between them
4. Placeholder names/numbers left in ("John Doe", round 50%/$100)
5. Generic startup copy ("Elevate", "Seamless", "Next-Gen") in headings/CTAs
6. Pure `#000000` background (use a near-black token instead)
7. Missing hover/focus states on interactive elements
8. Unmodified stock flat illustration (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps without custom palette/poses) — fix by tier: custom hand-drawn > line-art/sketch > isometric 3D > heavily-customized flat > geometric/abstract > skip illustration
