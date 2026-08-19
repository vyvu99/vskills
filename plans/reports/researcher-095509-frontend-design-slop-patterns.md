# Frontend-Design Slop Patterns & Premium Techniques

**Researcher:** frontend-design skill audit  
**Date:** 2026-08-19  
**Time:** 09:55:09  
**Context:** Extracting portable patterns from frontend-design references for vdesign --bold mode redesign

---

## Anti-Slop Rules (Portable)

### Typography (Non-Negotiable)
- **Avoid:** Inter, Roboto, Arial, Open Sans, Space Grotesk
- **Use instead:** Geist, Outfit, Cabinet Grotesk, Satoshi, Plus Jakarta Sans; variable fonts for display; editorial serifs for creative work
- **Weight hierarchy:** Don't just use 400/700; include 500/600 for subtle distinction
- **Orphaned words:** Use CSS `text-wrap: balance` or `text-wrap: pretty`
- **Headers:** Prefer sentence case over Title Case; use lowercase italic or small-caps for variation

### Color (Single Largest LLM Fingerprint)
- **Primary AI tell:** Purple/blue gradient aesthetic—**avoid entirely**
- **Dark colors:** Never pure `#000000`; use `#0a0a0a`, `#111`, Zinc-950, or tinted dark instead
- **Saturation rule:** Keep accents at saturation ≤ 75%; desaturate to blend elegantly
- **One accent per project:** Remove all secondary accent colors
- **Gray discipline:** Single gray family only (never mix warm + cool grays)
- **Shadows:** Tint shadows to match background hue (dark navy shadow on navy bg, not black)
- **Texture fix:** Flat design with zero texture feels sterile—**add subtle noise/grain overlay always**

### Layout (Avoids Generic Grid Trap)
- **Replace 3-column equal cards with:** 2-column zig-zag, asymmetric grid, horizontal scroll, or masonry
- **Replace centered hero + centered H1 with:** split-screen hero, left-aligned, or asymmetric whitespace
- **Viewport fix:** Use `min-h-[100dvh]` not `h-screen` (iOS Safari bug)
- **Border-radius variation:** Tight on inner elements, softer on containers; never uniform everywhere
- **Always constrain max-width:** ~1200-1440px with auto margins
- **Mobile fallback:** Below 768px, all asymmetric layouts collapse to single column

### Content (The "Jane Doe" Anti-Pattern)
- **Names:** Use realistic, diverse names—never "John Doe", "Jane Smith", "Sarah Chan"
- **Numbers:** Use organic data (47.2%, $99.00) not round numbers (50%, $100.00)
- **Brand names:** Contextual, invented names—never "Acme", "Nexus", "SmartFlow"
- **Copy avoid list:** "Elevate", "Seamless", "Unleash", "Next-Gen", "Game-changer", "Delve", "Tapestry"
- **Always real copy:** Draft actual content, never Lorem Ipsum
- **Tone:** No exclamation marks in success messages; be confident, not loud
- **Error messages:** Direct ("Connection failed. Try again.") not cute ("Oops!")

### Components & Icons
- **Unstyled components are slop:** Always customize shadcn (radii, colors, shadows)
- **Cards:** Replace generic border+shadow+white-bg with spacing/dividers when high visual density
- **Icon sets:** Avoid Lucide/Feather exclusively; use Phosphor, Heroicons, or custom SVG
- **Icon metaphors:** Rocketship for "Launch" and shield for "Security" are clichés—use intentional choices
- **Testimonials:** Replace 3-card carousel-dots with masonry wall, embedded posts, or single rotating quote
- **Badges:** Replace pill-shaped "New"/"Beta" with square badges or plain text
- **Avatars:** Move beyond circles; use squircles or rounded squares

### Visual Effects (GPU-Aware)
- **Glow effects:** Avoid neon/outer glows (`box-shadow` glows); use inner borders or tinted shadows instead
- **Motion:** Never default to `ease-in-out` / `linear`—use spring physics or custom cubic-beziers
- **Cursors:** Skip custom mouse cursors (hurt performance, hurt accessibility)
- **Gradient text:** Allowed sparingly on accent elements only, never on body or large headers
- **Glassmorphism:** Only with full treatment (`backdrop-blur` + 1px inner border `border-white/10` + inner shadow), not standalone `backdrop-blur`

### Quick Self-Check (Instant AI Tells)
If ANY of these apply, design reads as AI-generated—fix before shipping:
- [ ] Inter font anywhere in project?
- [ ] Purple or blue gradient as main aesthetic?
- [ ] Three equal-width cards in a row?
- [ ] Centered hero text over dark gradient image?
- [ ] "John Doe" or "Acme Corp" in any content?
- [ ] Round placeholder numbers (50%, $100)?
- [ ] "Elevate your workflow" or similar startup copy?
- [ ] Pure `#000000` as background?
- [ ] Generic spinner (no skeleton)?
- [ ] No hover/active states on buttons?

---

## Premium Design Vocabulary & Techniques (Portable)

### Vibe Archetypes (Commit Before Coding)
**Three pre-defined directions—pick one, then pull patterns from its arsenal:**

**Ethereal Glass** (SaaS / AI / Tech)
- Deep OLED black `#050505`
- Radial mesh gradient orbs in background
- Cards with `backdrop-blur-2xl` and vantablack
- Wide geometric Grotesk typography

**Editorial Luxury** (Lifestyle / Real Estate / Agency)
- Warm creams `#FDFBF7`, muted sage, or deep espresso
- Variable serif for massive headings
- Subtle CSS noise/film-grain overlay for physical paper feel

**Soft Structuralism** (Consumer / Health / Portfolio)
- Silver-grey or pure white background
- Massive bold Grotesk
- Airy floating components with highly diffused ambient shadows

### Navigation Patterns
| Pattern | Technique |
|---------|-----------|
| **Mac Dock Magnification** | Icons scale fluidly on hover with spring physics |
| **Magnetic Button** | `useMotionValue` + `useTransform` pulls button toward cursor |
| **Gooey Menu** | Sub-items detach from main button like viscous liquid |
| **Dynamic Island** | Pill-shaped component that morphs to show status/alerts |
| **Fluid Island Nav** | Floating glass pill (`mt-6 mx-auto rounded-full`); hamburger lines fluidly rotate to X on mobile |
| **Contextual Radial Menu** | Circular menu expanding at click coordinates |
| **Mega Menu Reveal** | Full-screen dropdowns with stagger-fade complex content |
| **Floating Speed Dial** | FAB springs into curved line of secondary actions |

### Layout Patterns (Beyond 3-Column Cards)
| Pattern | Implementation |
|---------|-----------------|
| **Asymmetrical Bento** | CSS Grid with `col-span-8 row-span-2` next to stacked `col-span-4`; falls back `grid-cols-1` on mobile |
| **Z-Axis Cascade** | Cards stacked like physical objects with slight overlap; remove rotations <768px |
| **Editorial Split** | Massive left-half typography; scrollable right-half image pills |
| **Split Screen Scroll** | Two halves sliding opposite directions on scroll |
| **Curtain Reveal** | Hero section parting in middle like curtains on scroll |
| **Masonry Layout** | Staggered grid without fixed row heights (Pinterest-style) |
| **Chroma Grid** | Grid borders/tiles with subtle continuously animating color gradients |

### Card Patterns (True Premium Treatment)
| Pattern | CSS/Details |
|---------|-------------|
| **Double-Bezel (Doppelrand)** | Outer shell `bg-black/5 ring-1 ring-black/5 p-1.5 rounded-[2rem]` wrapping inner core with concentric radius `rounded-[calc(2rem-0.375rem)]` |
| **Parallax Tilt Card** | 3D-tilting tracking mouse coordinates (Framer Motion or vanilla) |
| **Spotlight Border Card** | Card borders illuminate dynamically under cursor |
| **True Glassmorphism** | `backdrop-blur` + 1px inner border `border-white/10` + inner shadow `shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]` |
| **Holographic Foil Card** | Iridescent rainbow reflections shifting on hover |
| **Tinder Swipe Stack** | Physical stack of cards user can swipe away |
| **Morphing Modal** | Button seamlessly expands into full-screen dialog |

### Scroll-Driven Animations
| Pattern | Implementation |
|---------|-----------------|
| **Sticky Scroll Stack** | Cards stick to top, physically stack over each other during scroll |
| **Horizontal Scroll Hijack** | Vertical scroll translates to smooth horizontal gallery pan |
| **Zoom Parallax** | Central background zooming in/out seamlessly on scroll |
| **Scroll Progress Path** | SVG lines that draw themselves as user scrolls |
| **Staggered Entry** | Elements cascade with Y-translation + opacity fade; use `staggerChildren` (Framer Motion) or CSS `animation-delay: calc(var(--index) * 100ms)` |

### Typography Effects (Text As Interaction)
| Pattern | Effect |
|---------|--------|
| **Kinetic Marquee** | Endless text bands reversing or speeding up on scroll |
| **Text Mask Reveal** | Massive typography as transparent window to video background |
| **Text Scramble Effect** | Matrix-style character decoding on load or hover |
| **Variable Font Animation** | Interpolate weight/width on scroll/hover for "alive" text |
| **Outlined-to-Fill Transition** | Text starts as stroke outline, fills with color on scroll entry |
| **Circular Text Path** | Text curved along spinning circular path |
| **Kinetic Typography Grid** | Grid of letters that dodge or rotate away from cursor |

### Micro-Interactions (Elevate Buttons & States)
| Pattern | Implementation |
|---------|-----------------|
| **Button-in-Button Trailing Icon** | Arrow nested in `w-8 h-8 rounded-full bg-black/5` flush with button's inner right padding |
| **Particle Explosion** | CTAs shatter into particles on success |
| **Directional Hover-Aware Button** | Fill enters from exact side mouse came from |
| **Ripple Click Effect** | Visual waves rippling from click coordinates |
| **Skeleton Shimmer** | Shifting light reflections across placeholder boxes (match layout shape exactly) |
| **Tactile Press Feedback** | On `:active`, use `scale(0.98)` or `translateY(1px)` for physical push sensation |
| **Eyebrow Tags** | Microscopic pill before major headings: `rounded-full px-3 py-1 text-[10px] uppercase tracking-[0.2em]` |

### Surfaces & Effects
| Pattern | Technique |
|---------|-----------|
| **Grain/Noise Overlay** | Fixed `pointer-events-none` pseudo at `z-50`; never on scrolling containers |
| **Colored Tinted Shadows** | Shadows carry background hue, not generic black |
| **Mesh Gradient Background** | Organic lava-lamp-like animated color blobs |
| **Lens Blur Depth** | Dynamic focus blurring background layers to highlight foreground |
| **Animated SVG Line Drawing** | Vectors draw their own contours in real-time |

---

## Workflow Shape

### Current Frontend-Design Approach
The workflow (`workflow-quick.md`) is **execution-fast, not research-heavy**:
1. Run `ui-ux-pro-max` searches (product/style/mood/color domains)
2. Skip extensive planning, move to implementation quickly
3. Implement with HTML/CSS/JS
4. Generate assets with `ck:ai-multimodal`
5. Report & approve

### Critical Upstream: Vibe Commitment
**BEFORE executing**, `premium-design-patterns.md` mandates:
> "Before writing code, commit to a vibe"

This is a **concept-first gate**, but not heavy research. You choose from three archetypes (Ethereal Glass / Editorial Luxury / Soft Structuralism) or define a custom vibe, then pull concrete pattern blocks matching that archetype.

### Comparison to vdesign's Current Workflow
vdesign uses: **Scan → Audit → Fix → Verify** (maintenance/hygiene reactive)

frontend-design implies: **[Vibe Commit] → Archetype-Driven Patterns → Implementation → Asset Generation → QA** (design-first, prescriptive)

---

## Dependency & Library Guidance (Bold/Creative Work Unlocks)

### Motion Libraries (Explicitly Enabled for Premium)
- **Anime.js v4** — Precise, portable motion with spring physics eases, stagger, SVG morphing
  - v4 syntax mandatory: `import { animate, createTimeline, stagger } from 'animejs'`
  - Single-line format for simple animations; multi-line only for >4 properties
  - GPU-safe: animates only `transform` and `opacity`
  
- **Framer Motion** — JS-driven patterns (useMotionValue, useTransform, whileInView)
  - For scroll-triggered reveals, parallax, directional hover
  - Runs outside React render cycle (performance-safe)
  - Extract as isolated leaf client components (`"use client"`)
  
- **GSAP / ThreeJS** — Alternatives for scroll storytelling
  - Note: Never mix Framer Motion + GSAP in same component tree

### Component Libraries (Unlock with --bold)
- **Magic UI (80+ components)** — Beautifully designed landing page components
  - Text effects: Animated Gradient Text, Aurora Text, Text Scramble, Morphing Text, Spinning Text
  - Buttons: Shimmer Button, Pulsating Button, Rainbow Button, Ripple Button
  - Animated effects: Animated Beam, Confetti, Orbiting Circles, Meteors, Scroll Progress
  - Installation: `npx magicui-cli add <component-name>`

### Asset Generation (Design-Driven, Not Generic)
- **Imagen-4 Models** via `ck:ai-multimodal`
  - Fast: `imagen-4.0-fast-generate-001` (~$0.02/image, exploration phase)
  - Standard: `imagen-4.0-generate-001` (~$0.04/image, production)
  - Ultra: `imagen-4.0-ultra-generate-001` (~$0.08/image, hero/marketing)
  
- **Design-Context-First Prompting** (NOT generic)
  1. Define aesthetic direction (Brutalist? Organic? Minimalist?)
  2. Specify color palette precisely (hex or Tailwind tokens)
  3. Reference design movements ("Bauhaus geometric", "Neo-brutalism")
  4. Include technical specs (aspect ratio, composition, text overlay suitability)
  
- **Evaluation Loop** — Use `gemini-2.5-flash` for analysis (~$0.001/image)
  - Score against design standards (aesthetic coherence, color harmony, composition, text overlay suitability)
  - Iterate if <7/10

### Performance Guardrails (Keep Bold Performant)
- **GPU-safe animations only:** `transform` and `opacity`; never `top/left/width/height/margin/padding`
- **`backdrop-blur` constraints:** Fixed-position elements only (navbars, modals); never scrolling containers
- **Grain/noise overlay:** Fixed `pointer-events-none` pseudo at `z-50`; never on scrolling containers or individual cards
- **Z-index discipline:** Use systemic layers (`--z-base: 0`, `--z-card: 10`, `--z-modal: 300`, etc.)
- **Scroll observers:** Use `IntersectionObserver` or `whileInView` (Framer Motion); never `window.addEventListener('scroll')`
- **Mobile fallback:** Below 768px, remove rotations, negative margins, overlaps; collapse asymmetric grids to single column

### No Restrictions on Adding Libraries
The frontend-design materials present all these (Anime.js, Magic UI, Imagen-4, Framer Motion) as **tooling unlocked for creative work**, not blocked. --bold/L5 should trigger:
- Permission to add Anime.js (if not present)
- Permission to add Magic UI (or equivalent component library)
- Auto-activation of `ck:ai-multimodal` for design-driven asset generation
- Unlock of performance guardrails (for maintainability, not avoidance)

---

## Recommendations for vdesign's --bold Mode

### 1. Add Vibe Commitment Gate (BEFORE Execution)
Insert a new upstream phase:
```
--L5 --bold WORKFLOW:
  [1] User specifies or system suggests vibe archetype
  [2] Pull concrete pattern blocks matching that vibe
  [3] THEN proceed to implementation (currently "Scan → Audit")
```

Vibe options:
- Pre-defined: Ethereal Glass, Editorial Luxury, Soft Structuralism
- Custom: User provides mood board keywords

### 2. Unlock Motion + Component Libraries at --L5 --bold
Currently, the workflow likely avoids dependencies. For --bold:
- **Anime.js v4** — Port the skill's motion patterns into code generation
- **Magic UI** — Add components from their text effect + button library
- **Framer Motion** — For scroll-driven reveals and directional hover (if React project)
- **Imagen-4 Ultra** — Trigger design-context-driven asset generation, not generic prompts

### 3. Replace Audit-Checklist with Pattern-Pulling
Current: "Scan audit checklist, find violations, fix"  
New: "Pick vibe → pull 2-3 concrete patterns from that vibe's arsenal → implement → validate against anti-slop checklist"

Example for Ethereal Glass:
- Use Fluid Island Nav + Mac Dock Magnification for navigation
- Use Double-Bezel cards for feature blocks
- Use Kinetic Marquee for section headers
- Use Mesh Gradient Background
- Use Anime.js for state transitions

### 4. Embed Anti-Slop Rules as Non-Negotiable Guardrails
The checklist from anti-slop-rules.md is atomic. At --bold, treat as immutable:
- [ ] No Inter font
- [ ] No purple/blue gradients
- [ ] No 3-equal-column card rows
- [ ] Real, diverse names in content
- [ ] Organic data numbers
- [ ] Real copy (no Lorem Ipsum)
- [ ] Hover/active states on all interactive elements
- [ ] Noise/grain overlay on flat design
- [ ] No oversaturated accents

Violation = auto-fail for --bold delivery.

### 5. Design-Context-First Asset Generation
When --bold + needs images/backgrounds:
1. Extract aesthetic direction from chosen vibe
2. Craft Imagen-4 prompt with style/movement reference + color specifics
3. Generate with Fast model (exploration), then Standard/Ultra for production
4. Analyze with gemini-2.5-flash against design standards
5. Iterate or integrate

### 6. Document Workflow in Skill
Add a `workflow-bold.md` (mirror of frontend-design's `workflow-quick.md`):
```
## --bold Workflow

### Phase 1: Vibe & Pattern Selection
1. Choose vibe archetype (Ethereal Glass / Editorial Luxury / Soft Structuralism or custom)
2. Pull 3-5 concrete pattern blocks from premium arsenal matching vibe
3. Plan asset generation strategy (Imagen-4 prompts, optional)

### Phase 2: Implementation
1. Generate HTML/CSS/JS with selected patterns
2. Add Anime.js + Magic UI components as needed
3. Validate against anti-slop guardrails

### Phase 3: Asset Generation (If Images/Backgrounds Needed)
1. Define aesthetic direction
2. Craft design-driven Imagen-4 prompt
3. Generate, analyze (gemini-2.5-flash), iterate

### Phase 4: Delivery
- Anti-slop checklist all ✅
- Patterns visible and recognizable
- Performance guardrails met (GPU-safe animations, no blur on scrolling containers)
- No Lorem Ipsum, generic names, or startup clichés
```

---

## Summary Table: What Changes for --bold

| Aspect | Current (L1-L4) | --bold Unlock |
|--------|-----------------|---------------|
| **Concept** | Maintenance-driven audit | Design-first vibe commitment |
| **Motion** | CSS transitions (basic) | Anime.js v4 + spring physics + stagger |
| **Components** | Shadcn defaults | Magic UI + custom animations |
| **Assets** | Not generated | Imagen-4 with design-context prompts |
| **Dependencies** | Minimal | Anime.js, Magic UI, Framer Motion (optional) |
| **Patterns** | Generic fixes | 20+ premium blocks from chosen archetype |
| **Content** | Pragmatic | Real copy, diverse names, organic data |
| **Performance** | Best-effort | GPU-safe only (transform/opacity), guardrails enforced |

---

## Single Most Critical Insight

**The reason vdesign stays generic even at L5+bold:** It lacks a **vibe commitment gate** before execution. Frontend-design materials show that award-tier design begins with choosing one of 3 archetypes (or custom), then pulling *concrete, named pattern blocks* that belong to that archetype. vdesign's current workflow (audit → fix) is maintenance-reactive; it needs to be flipped to **design-first (vibe → patterns → implement → validate)** for bold output to feel intentional, not fixed-up.

The --bold flag should unlock:
1. Vibe commitment (concept-first)
2. Premium pattern library access (named, portable, archetype-aligned)
3. Motion + component libraries (Anime.js v4, Magic UI)
4. Design-driven asset generation (Imagen-4 with aesthetic context, not generic prompts)
5. Strict anti-slop guardrails (immutable checklist, enforced on delivery)

Without the vibe gate, even L5 output feels like "polish applied to a default design" instead of "intentionally designed from a coherent aesthetic vision."

---

## Unresolved Questions

None—all patterns extracted and portable. Anti-slop rules, premium techniques, workflow shape, dependency guidance, and recommendation path are all specified. The frontend-design skill provides a complete, precedent-tested model for award-tier output.
