# Design Decision Checklist

vdesign decides every axis below itself, every run — no `AskUserQuestion`, no per-run
user picks. This is the taxonomy + decision priority it uses to fill in the Design
Brief (`SKILL.md` Phase 0 step 7): 18 criteria across 6 groups, covering every axis
that actually changes how a redesign looks and feels. Skip only the criteria that are
structurally inapplicable to the target (e.g. Dark Mode Stance when the project has no
theming system at all, or Data & Table Density when the target has no data-heavy
surface at all — say so, don't force a decision with no real answer).

Sources behind this list: v0 (Vercel), Galileo AI, Framer AI, Material Design 3 /
Theme Builder, Relume, Figma design tokens, Fluent 2 / Atlassian / Cloudscape / SAP
Fiori design systems, Ant Design, Carbon Design System, Linear, Nielsen Norman
Group's empty-state research, Smashing Magazine's CSS `corner-shape` coverage — not
invented from scratch, and not a fixed catalog to memorize verbatim: treat the
options below as the floor, not a ceiling — pick a project-specific option when one
obviously fits better than any listed here.

## Decision priority

For each criterion, decide in this order and state which one actually drove the
pick (never "just felt right"):

1. **This run's Domain Research** (`SKILL.md` Phase 0 step 6, always runs) — a
   concrete, current (2026) finding for this exact aspect/domain beats any generic
   default below.
2. **Project Profile** — existing design tokens, `package.json` dependencies, the
   "Good reference UI" entry, already-read component code. Use when there's a real
   reason to stay consistent, not by default.
3. **Real User & Purpose** (`SKILL.md` Phase 1 Step 1) — the actual persona and task
   this screen serves; drives density, tone, and whether a bolder or more
   restrained choice actually fits the context (e.g. a clinical B2B tool and a
   consumer wellness app land on different answers for the same criterion).
4. **Personal Aesthetic Quality Floor** (`SKILL.md`) — when no strong signal exists
   from 1-3 (greenfield, no precedent), pick the most common/conservative option for
   that axis rather than guessing boldly, and say so explicitly.

## Round 0 — Structural Freedom

0. **Structural freedom** — how much the page/component's structure itself may
   change, not just its styling. Decided primarily by Phase 1's Real User & Purpose
   read, not this file: restructure (merge/reorder/split sections, change view-type)
   whenever the current structure genuinely doesn't fit the real task — never bounded
   by "proportional to what the audit found" for structural moves specifically, but
   every restructure must trace to a concrete reason from that read, not "because it
   could look better."

## Round 1 — Visual Foundation

1. **Typography** — primary typeface direction and sizing voice.
   - *Minimal/Professional* — neutral, technical; representative: `IBM Plex Sans, sans-serif` (IBM Plex, Source Sans 3)
   - *Bold/Editorial* — distinctive, branded; representative: `Playfair Display, serif` (Playfair Display, Fraunces, Clash Display)
   - *Code/Technical* — dev-tool, creative; representative: `JetBrains Mono, monospace` (JetBrains Mono, Fira Code, Space Grotesk)
   - *Startup/Modern* — contemporary, friendly; representative: `Inter Tight, sans-serif` (Satoshi, Cabinet Grotesk, Inter Tight)
2. **Color palette philosophy** — how the palette gets built.
   - *Keep existing tokens* — full consistency with the current codebase, no brand color changes anywhere in this run
   - *Accent colors only* — keep primary, add exactly one new brand accent; base/primary tokens stay untouched
   - *Full palette redesign* — new palette from brand colors, built from scratch, every color token in scope may change
   - *Dynamic/auto-generated* — tool-generated palette with accessibility built in (Material Theme Builder style), same freedom as full redesign
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
14. **Aesthetic boldness / overall direction** — the master dial everything else scales against. No longer locked to "stay close to the system by default" — Domain Research runs every time, so pick whichever direction this run's findings and the Real User & Purpose read actually support:
    - *Brand-centric/cohesive* — every decision serves one clear, consistent identity; stays close to the project's existing system
    - *Experimental/bold* — pushes norms, unexpected choices, genuine creative freedom, may depart from the existing system entirely
    - *Functional/minimalist* — content-first, no decoration beyond what clarity needs
    - *Trend-forward* — actively pulls from current (2025-2026) real-world design trends surfaced by this run's Domain Research
    - *Game-inspired/Arcade* — HUD-style panels, glow/neon accents, chunky tactile feedback (squash/bounce on press), weighty satisfying motion; art direction borrowed from game UI, not gamification mechanics (no points/levels/streaks added)

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

## How vdesign decides

- **Structural Freedom** (Round 0) is driven by Phase 1's Real User & Purpose read,
  not guessed from this list — see that section's note above.
- **Domain Research** (`SKILL.md` Phase 0 step 6) now runs every time, regardless of
  which boldness direction criterion 14 lands on — it's an input to the decision,
  not gated by it.
- **Phase 3 Fix** executes the Design Brief (below) — every axis that used to be
  unlocked by a flag or a user answer is now unlocked by the Decision Priority
  above, stated explicitly in the brief, never left implicit.
- Hard technical rules (accessibility, GPU-safe motion, no DB schema/migration
  changes) are never affected by any decision here — they are safety/engineering
  constraints, not aesthetic ones. API/service-layer changes ARE in scope when a
  decision above needs them (e.g. exposing a field for a new data/table density
  choice) — see `SKILL.md`'s Hard rules.

## Design Brief

After deciding all 18 criteria (self-determined, not asked), write a short concrete
brief (5-10 lines, not a one-word label per criterion) translating those decisions —
plus Domain Research's findings and the Real User & Purpose read — into specific
choices: the actual typeface names, the actual palette approach, the actual motion
timing/easing, the actual shape/icon/imagery direction, the actual spacing scale, the
actual layout system, the actual tone, the actual boldness level, and (when
applicable) the actual data/table, form, and empty/loading/error treatment. State it
out loud before Phase 1 starts. This is the single source of truth Phase 3 executes
against — an un-synthesized pile of 18 raw decisions is not a brief.
