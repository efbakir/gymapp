# Unit — Visual Language

Dark, calm, performance-focused. Benchmark for surface treatment: Revolut dark mode. Core test: can a tired user read this screen and log a set in under 3 seconds?

---

## 1. Color

### Dark surfaces
- **Base background**: Softened near-black with a subtle blue-grey or neutral grey influence. Not pure black. Not AMOLED black. Not a gaming aesthetic. Think `#0F1117` or `#111318` range — visually settled and premium.
- **Elevated surface**: One step lighter than base. Used for sheets, grouped section backgrounds.
- **Card surface**: One step lighter than elevated. Cards sit on the background through fill contrast alone — no shadows, no borders required to define them. A card must read as a card without decoration.
- System semantic colors map to this intention: `Color(.systemBackground)` for base, `Color(.systemGroupedBackground)` for elevated context, card fill as a distinct UIColor fill value.

### Accent
- **Primary accent**: `#FF4400` orange. Used for: primary CTA, active rest timer state, current target highlight, cycle progress marker.
- **Usage constraint**: Restrained. Orange is intentional — it signals "act here." Do not use it for decoration, secondary labels, passive states, or more than one interactive element per screen.
- **Tone**: Mature, controlled. Not neon. Not overly saturated. It should feel like a precision instrument, not a sale tag. Study how Revolut deploys orange or red CTAs: singular, purposeful, calm.
- **Adapt for dark**: On dark backgrounds `#FF4400` is bold enough — do not add glow, shadow, or background fill behind the accent button unless it is a full filled CTA.

### Supporting colors
- **Ghost / target text**: `Color.secondary` — computed targets, read-only engine values. Visually subordinate, never interactive.
- **Completed state**: Muted, readable. Not loud. A filled checkmark or subdued green tone. Should not compete with active data.
- **Failure state**: `Color.red` — missed targets, failure row background `Color.red.opacity(0.08)`, border `Color.red.opacity(0.5)`. Always paired with an icon (never color alone — HIG).
- **Deload badge**: `Color.orange.opacity(0.8)` paired with `arrow.down.circle.fill`. Sparse use only.
- **Borders**: `Color(uiColor: .separator)` — sparse, subtle. Only use when fill contrast alone cannot distinguish two surfaces. Default assumption: no border needed.
- **Progress chart accent**: Slightly deeper orange `rgb(214, 84, 0)` for volume charts and PR sparklines where full `#FF4400` would compete with interactive elements.

---

## 2. Design system size (hard constraint)

The design system must stay minimal. Aim for exactly:

| Role | Count |
|------|-------|
| Background levels | 3 (base / elevated / card) |
| Accent colors | 1 (orange `#FF4400`) |
| Border styles | 1 (separator, sparse) |
| Success treatment | 1 |
| Destructive treatment | 1 |
| Text hierarchy levels | 3 (primary / secondary / ghost) |
| Button variants | 2 (primary filled / secondary text or outlined) |
| Card variants | 1 |

Any addition must be justified by a Gym Test improvement. If it doesn't make logging faster or clearer, it doesn't ship.

---

## 3. Typography

- **Hierarchy**: Numbers and key workout data (weight, reps, rest countdown) dominate. They are the largest and boldest elements. Exercise names are secondary. Labels and metadata are tertiary.
- **Font**: System font (San Francisco). Dynamic Type–friendly styles only.
- **Rule**: If text is not helping the user log or understand state, it should not be there.

---

## 4. Layout and structure

- **No shadows**: Zero shadow use. Surface separation comes from fill contrast between background levels. Elevate without shadowing.
- **Cards**: One card variant. Rounded rectangle. Card surface fill sits visibly above background. Minimal internal padding that keeps data dense but not cramped.
- **One primary CTA per screen**: Every screen has exactly one filled, high-contrast primary action. Everything else is secondary or removed.
- **Spacing**: Consistent 8pt grid. Generous between sections; tighter within a card to keep related data close.
- **Navigation**: Consistent top bar. Bottom area reserved for primary CTA or rest timer. Thumb-friendly. No floating buttons that obscure data.

---

## 5. Components and patterns

- **Primary CTA**: Filled, `#FF4400`, large, ≥ 44pt. One per screen. Label states the outcome ("Complete Set", "Start Workout", "Start Rest").
- **Secondary actions**: Text or outlined, not orange. Small, not competing with primary.
- **Inputs**: Large tap targets for weight and reps. Pre-filled from last session. No required fields beyond weight and reps.
- **Success feedback**: Clear, unambiguous state change after logging (checkmark, row completion styling). No "did it save?" ambiguity.
- **Bottom sheets**: For focused sub-tasks (edit set, template picker). User stays in context.
- **RIR stepper**: 6 capsule buttons (0–5). Button "0" = red signal. ≥ 44pt each. Pre-fills from last session.

---

## 6. Iconography

- **Style**: SF Symbols only. Line weight consistent. No decorative icons.
- **Color**: `Color.secondary` for passive icons. Accent only for active/primary (e.g. running rest timer).
- **Quantity**: Minimal. Only where icon replaces a label more efficiently, or where HIG requires icon+label pairing (e.g. failure state).

---

## 7. Rest timer and Live Activity

- **In-app**: Big countdown. Same accent for "running." Visible without leaving the workout screen.
- **Live Activity**: Lock Screen and Dynamic Island. Minimal, legible. Same visual language — no stylistic deviation.

---

## 8. Benchmark for dark surface treatment

**Revolut dark mode** is the reference for how dark cards and dark surfaces should feel:
- Cards are visibly distinct from backgrounds without borders or shadows
- The overall surface feels layered, not flat and not cluttered
- Color is sparse and purposeful
- Typography and spacing carry hierarchy — not decoration

When in doubt about a dark surface decision, ask: "Would this look appropriate in Revolut's dark UI?"

---

## 9. What we are not doing

- No light mode
- No gradients
- No shadows
- No glows or visual effects
- No multiple accent colors
- No decorative illustrations or imagery
- No component proliferation

---

## Summary

| Element | Rule |
|---------|------|
| Base background | Softened near-black, subtle blue-grey tone. Not pure black. |
| Cards | Fill contrast only. No shadows. One variant. |
| Accent | `#FF4400`. Restrained. One primary CTA per screen. |
| Typography | Numbers dominate. 3 levels: primary / secondary / ghost. |
| Borders | Sparse. Separator color. Use only when fill contrast is insufficient. |
| Shadows | Never. |
| Design system | Minimal. If it doesn't serve the Gym Test, it's not added. |
| Benchmark | Revolut dark mode for surface control. |

This visual language supports the **Gym Test**: fast, clear, low cognitive load, every screen.
