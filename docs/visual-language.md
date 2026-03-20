# Unit — Visual language

**Light-first, calm, performance-focused.** The UI is built with the **atomic design system** (`atomic-design-system.md`): tokens live in `AppAtoms.swift`, screens compose through `AppScreen` and shared molecules/organisms.

**Core test:** Can a tired user read the screen and log a set in under 3 seconds?

---

## 1. Color

### Surfaces (light baseline)

- **Page background** (`AppColor.background`): Soft neutral grey — easy on the eyes in bright gyms; not harsh white edge-to-edge.
- **Elevated / nav surface** (`AppColor.surface`): White — top chrome and areas that sit above the page background.
- **Card surface** (`AppColor.cardBackground`): White — cards read clearly against the grey page through **fill contrast**, not shadows.

### Text

- **Primary** (`AppColor.textPrimary`): Body, titles, key data.
- **Secondary / muted** (`AppColor.textSecondary`, `AppColor.mutedText`): Labels, subtitles, helper copy.

### Accent and primary CTA

- **Interactive accent** (`AppColor.accent`): Primary actions (e.g. filled CTA uses accent fill with white label text in `AppPrimaryButton`). Restrained: **one obvious primary action** per screen where the Gym Test applies.
- **Accent soft** (`AppColor.accentSoft`): Chips, subtle highlights — not a second “loud” brand color.

### Supporting

- **Borders** (`AppColor.border`): Hairlines and `AppDivider` — use sparingly.
- **Success / warning / error** (`AppColor.success`, `warning`, `error`): Semantic states; pair with icons or labels — never color alone (HIG).

---

## 2. Design system size (hard constraint)

Keep the token set **small**. New roles need a Gym Test or clarity justification.

| Role | Guidance |
|------|-----------|
| Background levels | page / surface / card (as defined in atoms) |
| Text levels | primary / secondary / muted |
| Primary CTA | one dominant action per critical screen |
| Card treatment | prefer `AppCard` / `appCardStyle()` only |

---

## 3. Typography

- **Hierarchy**: Weight, reps, timers, and targets dominate. Exercise names and metadata are secondary.
- **Font**: System (San Francisco). Use **`AppFont`** cases from atoms — Dynamic Type–friendly paths should stay available as you refine screens.
- **Rule**: If text doesn’t help log or understand state, remove or demote it.

---

## 4. Layout and structure

- **Cards**: Rounded rectangle (`AppRadius.md`), padding `AppSpacing.md`. Separation from background is **contrast**, not drop shadows.
- **One primary CTA** on high-stress flows: full-width black (accent) button pattern via `AppPrimaryButton` unless a documented exception exists.
- **Spacing**: 4pt grid via `AppSpacing` — consistent section gaps vs. tight in-card grouping.
- **Navigation**: Prefer `AppScreen` + shared nav molecules; 44×44pt minimum touch targets.

---

## 5. Components and patterns

- **Set logging**: Large tap targets, defaults from last session, minimal steps (Gym Test).
- **Success feedback**: Clear completion state (checkmark, row styling) — no “did it save?” ambiguity.
- **Sheets**: Focused sub-tasks; keep users in context.
- **RIR / effort**: Steppers or capsules ≥ 44pt where used; failure state visually distinct + labeled.

---

## 6. Iconography

- **SF Symbols** only; weights/sizes set explicitly (`AppIcon` + `.image(size:weight:)`).
- Passive icons: secondary text color. Active / primary: accent or primary text as appropriate.

---

## 7. Rest timer and Live Activity

- **In-app**: Large, legible countdown; state obvious at a glance.
- **Live Activity**: Lock Screen / Dynamic Island — same hierarchy principles; no decorative clutter.

---

## 8. What we are not doing

- No gratuitous gradients, glows, or decorative illustration in core flows
- No shadow stacks to “lift” cards — rely on surface tokens
- No unbounded one-off components in page files — extend atoms/molecules/organisms first

---

## Summary

| Element | Rule |
|---------|------|
| Background | Neutral grey page; white cards/surfaces via atoms |
| Cards | `AppCard` / `appCardStyle`; contrast, not shadows |
| Accent | Tokenized; one clear primary CTA on stress screens |
| Typography | Numbers and targets first; use `AppFont` |
| Structure | Atomic layers + `AppScreen` for new work |
| Benchmark | Gym Test + clarity under fatigue |

This visual language works with **`docs/atomic-design-system.md`** and the files under `Unit/UI/`.
