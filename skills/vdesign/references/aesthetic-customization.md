# Aesthetic Customization

Runs on **every** `vdesign` invocation — no flag gates it. Before Phase 3 touches any code, walk the user through 5 rounds of `AskUserQuestion` (≤4 questions each, 17 criteria total) covering every axis that actually changes how a redesign looks and feels. The agent does not silently pick a direction; the user always does, explicitly, per run. Skip only the criteria that are structurally inapplicable to the target (e.g. Dark Mode Stance when the project has no theming system at all, or Data & Table Density when the target has no data-heavy surface at all — say so, don't ask a question with no real answer).

Sources behind this list: v0 (Vercel), Galileo AI, Framer AI, Material Design 3 / Theme Builder, Relume, Figma design tokens, Fluent 2 / Atlassian / Cloudscape / SAP Fiori design systems, Ant Design, Carbon Design System, Linear, Nielsen Norman Group's empty-state research, Smashing Magazine's CSS `corner-shape` coverage, and standard creative-brief practice — not invented from scratch, and not a fixed catalog to memorize verbatim: treat the options below as the floor, not a ceiling — offer a project-specific option when one obviously fits better.

## Round 1 — Visual Foundation

1. **Typography** — primary typeface direction and sizing voice.
   - *Minimal/Professional* (IBM Plex, Source Sans 3) — neutral, technical
   - *Bold/Editorial* (Playfair Display, Fraunces, Clash Display) — distinctive, branded
   - *Code/Technical* (JetBrains Mono, Fira Code, Space Grotesk) — dev-tool, creative
   - *Startup/Modern* (Satoshi, Cabinet Grotesk, Inter Tight) — contemporary, friendly
2. **Color palette philosophy** — how the palette gets built.
   - *Keep existing tokens* — full consistency with the current codebase
   - *Accent colors only* — keep primary, add a new brand accent
   - *Full palette redesign* — new palette from brand colors, built from scratch
   - *Dynamic/auto-generated* — tool-generated palette with accessibility built in (Material Theme Builder style)
3. **Motion/animation philosophy** — how much movement the UI carries.
   - *Minimal* — 150-300ms transitions only, no micro-interactions
   - *Balanced* — transitions + a few key micro-interactions (hover, page transition)
   - *Expressive* — staggered reveals, orchestrated page loads, emotional micro-interactions
   - *Utilitarian* — motion only to communicate state changes, never decorative
4. **Elevation & shadow system** — how depth gets built.
   - *Flat/minimal* — no shadows or very subtle ones, separation via stroke/border
   - *Layered (soft + sharp)* — ambient + directional shadows combined for natural depth
   - *Strong elevation* — pronounced shadows, multiple layers, clear z-axis hierarchy
   - *Monochromatic/minimal* — opacity + stroke instead of shadow

## Round 2 — Surface & Character

5. **Backgrounds & texture** — page/section background treatment.
   - *Solid colors* — minimalist, content-first
   - *Subtle gradients* — depth without overwhelming
   - *Geometric patterns/SVG* — brand personality, playful or technical
   - *Atmospheric effects* — layered/blurred/mesh, backdrop-filter-driven
6. **Shape language & border radius** — corner treatment as a personality signal.
   - *Sharp/geometric* (0-2px) — professional, authoritative, technical
   - *Soft rounded* (8-12px) — friendly, approachable, modern
   - *Playful/soft* (16px+) — warm, welcoming, casual
   - *Squircles/premium* (CSS `corner-shape`) — playful-premium hybrid
7. **Iconography style** — icon construction, not just which icon set.
   - *Outline* — thin strokes, empty fill, clean and flexible
   - *Filled* — bold, solid, easy to spot
   - *Hand-drawn/playful* — loose strokes, varied weight, unique
   - *Geometric/minimal* — strict grid, perfect geometry, technical
8. **Illustration & imagery style** — how (and whether) visuals represent people/concepts.
   - *Photography/realistic* — authentic, trust-focused
   - *Abstract/geometric* — shapes and color, no literal representation
   - *Hand-painted/character* — custom illustration, mascot, emotional
   - *Minimal/icon-based* — icons only, content stays the focus

## Round 3 — Structure

9. **Information density & spacing mode.**
   - *Compact* (4px grid) — data-heavy, dashboards, dense tables
   - *Comfortable* (8px grid) — the balanced default
   - *Spacious* (16-24px gutters) — editorial, breathing room, premium feel
10. **Component density & grid approach.**
    - *Tight* (4-8px) — precise, technical
    - *Standard* (8-12px) — balanced, most common
    - *Generous* (16px+) — readable, editorial
    - *Flexible/organic* — no strict grid, flow-based
11. **Layout structure & breakpoints.**
    - *Standard 12-column* — flexible, responsive, industry default
    - *8-column* — bolder sections, larger components
    - *Fluid/viewport-based* — percentage gutters, organic scaling
    - *Fixed containers* — classic, controlled max-width
12. **Dark mode stance.**
    - *Light mode only* — simplicity, contemporary light aesthetic
    - *Dark mode only* — modern, focus/nighttime tools
    - *Auto toggle* — system preference + manual override (default best practice)
    - *Dual-design* — light content area + dark chrome (hybrid readability)

## Round 4 — Direction

13. **Brand personality & tone of voice** — how the UI "talks," including microcopy.
    - *Professional/Ruler* — authoritative, structured, formal
    - *Playful/Jester* — fun, unexpected, cheeky microcopy
    - *Empathetic/Caregiver* — warm, supportive language
    - *Adventurous/Explorer* — bold, experimental, curious tone
14. **Aesthetic boldness / overall direction** — the master dial everything else scales against.
    - *Brand-centric/cohesive* — every decision serves one clear, consistent identity; stays close to the project's existing system
    - *Experimental/bold* — pushes norms, unexpected choices, genuine creative freedom, may depart from the existing system entirely
    - *Functional/minimalist* — content-first, no decoration beyond what clarity needs
    - *Trend-forward* — actively pulls from current (2025-2026) real-world design trends

## Round 5 — Content & States

15. **Data & table density** — how data-heavy surfaces (tables, dashboards, lists) get built.
    - *Spreadsheet-dense* (Cloudscape/Fiori-style) — maximal rows-per-screen, compact cells, sort/filter chrome always visible
    - *Card/row-hybrid* — table semantics but each row reads like a mini-card (avatar, badges, more breathing room)
    - *Chart-first dashboard* — data visualized (charts/sparklines) before raw tables, tables are drill-down only
    - *Minimal/inline* — data folded into prose or simple lists, no table chrome unless the dataset demands it
16. **Form & input style** — visual + interaction treatment of inputs, not just color.
    - *Floating label* (Material) — label animates into the input on focus/fill
    - *Top label + helper text* (Fluent, Carbon) — label always visible above, helper/error text below
    - *Inline/borderless* (minimal, Linear-style) — underline or no border, label as placeholder-adjacent
    - *Grouped/segmented* — related fields visually grouped in a bordered card, clear field-to-field rhythm
17. **Empty / loading / error state style** — how the UI represents "nothing here yet" / "still working" / "something broke".
    - *Skeleton screens* — gray content-shaped placeholders while loading, matches final layout
    - *Spinner/minimal* — simple spinner or progress bar, no layout mimicry
    - *Illustrated* — custom illustration/icon + friendly copy for empty/error states (onboarding feel)
    - *Text-only/utilitarian* — plain text message, no illustration, fastest to build and lowest visual weight

## What the answers drive

- **Domain Research** (Phase 0, next step) runs only when it earns its cost: criterion 14 answered *Trend-forward* or *Experimental/bold*, or the user's own answers elsewhere explicitly invoke "what's current right now." *Brand-centric* or *Functional/minimalist* skip it — there's nothing live to ground those in, use the answers directly.
- **Phase 3 Fix** executes the Design Brief (see below), not a flag. Every place the old `--wow` flag used to unlock something (new brand colors, new dependencies, decorative motion, structural layout changes) is now unlocked or not by the matching criterion answer above, per-run, explicit — never inferred.
- Hard technical rules (accessibility, no tech-stack migration, no logic/API changes, GPU-safe motion) are never affected by any answer here — they are safety/engineering constraints, not aesthetic ones.

## Design Brief

After all 5 rounds, write a short concrete brief (5-10 lines, not a one-word label per criterion) translating the 17 answers — plus Domain Research findings when it ran — into specific decisions: the actual typeface names, the actual palette approach, the actual motion timing/easing, the actual shape/icon/imagery direction, the actual spacing scale, the actual layout system, the actual tone, the actual boldness level, and (when applicable) the actual data/table, form, and empty/loading/error treatment. State it out loud before Phase 1 starts. This is the single source of truth Phase 3 executes against — an un-synthesized pile of 17 raw answers is not a brief.
