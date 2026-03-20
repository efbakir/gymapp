# Unit — Atomic design system

> **Single source of truth for UI structure and tokens in the SwiftUI codebase.**  
> Before adding or changing views, read this file and `visual-language.md`. If a pattern is missing here, define it at the correct layer first, then implement.

---

## Philosophy

Unit’s interface follows **atomic design** (Brad Frost): build screens **bottom-up** from a small, named set of tokens and components. Screen files (`*View.swift`) wire data and navigation; they do not invent one-off colors, spacing, fonts, or card chrome.

| Layer | Role | Location in repo |
|-------|------|-------------------|
| **Atoms** | Indivisible tokens and base primitives (color, type, spacing, radius, icons, divider) | `Unit/UI/Atoms/AppAtoms.swift` |
| **Molecules** | Small reusable composites with one job | `Unit/UI/Molecules/AppMolecules.swift` |
| **Organisms** | Larger sections (cards, settings groups) | `Unit/UI/Organisms/AppOrganisms.swift` |
| **Templates** | Screen shell: nav, scroll, padding, optional sticky CTA | `Unit/UI/Templates/AppScreen.swift` |
| **Pages** | Real screens with real data | `Unit/Features/**/**/*View.swift` |

**Rule:** Prefer tracing every visual decision to **`AppColor`**, **`AppFont`**, **`AppSpacing`**, **`AppRadius`**, or **`AppIcon`**. Legacy feature code may still reference older theme types during migration — new work must use atoms.

---

## Atoms (`AppAtoms.swift`)

### Colour — `AppColor`

Defined in code today (hex → `Color` via `UIColor`). Names express **role**, not implementation.

- **Surfaces**: `background`, `surface`, `cardBackground`
- **Text**: `textPrimary`, `textSecondary`, `mutedText`
- **Interactive**: `accent`, `accentSoft`, `disabled`, `border`
- **Status**: `success`, `error`, `warning`

**Rules**

- Do not scatter `Color(red:green:blue:)` or raw hex in feature views — extend `AppColor` if a new role is justified.
- Prefer semantic names (`textSecondary`) over `.gray` / `.black` in new UI.

### Typography — `AppFont`

Cases map to `Font` (+ optional `color`) via `.font` / `.color` accessors. Use **`AppFont.numericDisplay`** and **`AppFont.overline`** for workout numerics and small caps labels where specified in `visual-language.md`.

**Rules**

- Avoid inline `.font(.system(size:weight:))` in page files for standard hierarchy; use `AppFont` cases.

### Spacing — `AppSpacing` · Radius — `AppRadius`

Use named steps (`xs` … `xl` / `sm` … `lg`) for padding, `VStack` spacing, and corner radii.

**Rules**

- Avoid magic numbers like `.padding(16)` in new screens — use `AppSpacing.md` (or documented composition).

### Icons — `AppIcon`

SF Symbol names as `String` raw values; use `.image(size:weight:)` for consistent sizing.

**Rules**

- Set icon size explicitly at the call site (see `AppNavBar` / `AppListRow` for defaults).
- **List rows**: `AppListRow` is chevron-free by design; do not add `chevron.right` for “disclosure” — use context and tap targets (HIG: don’t rely on chevrons alone for meaning).

### Divider — `AppDivider`

Use instead of bare `Divider()` where the design system specifies a hairline with `AppColor.border`.

---

## Molecules (`AppMolecules.swift`)

| Component | Purpose |
|-----------|---------|
| `NavAction` / `NavTextAction` | Nav bar button descriptors |
| `AppNavBar` / `AppNavBarWithTextTrailing` | Fixed 44pt-tall bar; screens must not rebuild custom top bars |
| `AppListRow` | Standard list row; optional leading icon, title, subtitle, trailing slot |
| `AppStepper` | − / value / + control with fixed internal spacing |
| `AppTag` | Pills (default, accent, success, warning, error, muted, custom) |
| `AppPrimaryButton` | Full-width primary CTA (see `visual-language.md` for height/contrast) |

---

## Organisms (`AppOrganisms.swift`)

| Component | Purpose |
|-----------|---------|
| `AppCard` | Default card surface: padding, `cardBackground`, `AppRadius.md` |
| `appCardStyle()` | Modifier matching `AppCard` when a wrapper type is awkward |
| `SettingsSection` | Titled group inside an `AppCard` |

---

## Templates (`AppScreen.swift`)

**`AppScreen`** is the standard page wrapper: nav bar, optional divider, horizontal padding, scroll content, optional sticky `AppPrimaryButton`.

**Rules**

- New full-screen flows should compose inside `AppScreen` rather than ad-hoc `VStack` + custom nav.
- Bottom primary actions should go through `primaryButton:` when they match the sticky CTA pattern.

---

## Pages (feature views)

Allowed in `*View.swift`:

1. `AppScreen { … }` (or justified legacy layout during migration)
2. Organisms and molecules
3. Navigation, `@Query`, `@State`, view models

**Avoid in page files (for new code)**

- Raw padding/spacing numbers, raw corner radii, one-off `Color(…)` / `.foregroundStyle(.gray)`
- Custom nav bars duplicating `AppNavBar`
- Inline card chrome duplicating `AppCard` / `appCardStyle()`

---

## Banned patterns (review checklist)

| Pattern | Prefer |
|---------|--------|
| `Divider()` where spec calls for tokenized hairline | `AppDivider` |
| `.padding(16)` / `.cornerRadius(12)` in new UI | `AppSpacing.*` / `AppRadius.*` |
| `chevron.right` on `AppListRow`-style content | Context + row tap; no decorative chevron |
| New hex colours in Features | `AppColor` extension or asset + wrapper |

---

## Related docs

- `visual-language.md` — tone, hierarchy, Gym Test, light-first surfaces
- `design-principles.md` — product principles + token discipline
- `apple-hig.md` — accessibility and platform rules

---

## Changelog

| Date | Change |
|------|--------|
| 2026-03 | Initial doc: maps atomic layers to `Unit/UI/*`, aligns with `AppAtoms` / `AppScreen`. |
