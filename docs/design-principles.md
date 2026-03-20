# Unit — Design Principles

Principles that support “good design” and **always the one wins with the best UX**. These guide every screen and interaction.

---

## 1. Minimalism

- **What**: Only what’s needed to start a workout, follow a template, log sets, and run a rest timer. No social feed, no videos, no discovery.
- **Why**: Reduces cognitive load under physical stress (Gym Test). Users with their own program don’t need more; they need less.
- **Apply**: Remove any element that doesn’t serve “log this set” or “run this template.” Defaults and one-tap actions over extra screens.

---

## 2. Clarity

- **What**: Obvious what the screen is for, what each control does, and what state the workout is in (e.g. set completed, rest running).
- **Why**: Confusion during a workout leads to abandonment or wrong data.
- **Apply**: Clear labels, consistent hierarchy (e.g. exercise name → set rows → add set / complete set). Success feedback (e.g. checkmark) so the user knows the set was logged.

---

## 3. Speed (Gym Test)

- **What**: Log a set in **under 3 seconds**—the “Gym Test.” Defaults (last weight/reps), big tap targets, optional RPE, minimal steps.
- **Why**: Users are out of breath or under load; friction kills consistency.
- **Apply**: Pre-fill next set from previous. One-tap “same as last set” where useful. Primary CTA = complete set. Rest timer visible without leaving the screen (and on Lock Screen via Live Activity).

---

## 4. Consistency

- **What**: Same patterns everywhere: how sets are displayed, how templates are chosen, how history is shown. Same accent for primary actions and completed state.
- **Why**: Predictable UI is faster and less frustrating when tired.
- **Apply**: Reuse the same set row pattern, same card style for exercises, same navigation model (e.g. NavigationStack, no surprise modals for core flows).

---

## 5. Accessibility

- **What**: Legible text, sufficient contrast, tappable areas that meet minimum size, support Dynamic Type and VoiceOver where applicable.
- **Why**: Inclusive design and usability in bright gyms or with gloves/sweat.
- **Apply**: Large touch targets for “complete set” and rest timer. Avoid tiny steppers or links. Test with larger text sizes.

---

## 6. Atomic tokens & shared UI

- **What**: New and refactored UI uses the **atomic design system** — tokens (`AppColor`, `AppFont`, `AppSpacing`, `AppRadius`, `AppIcon`) in `Unit/UI/Atoms/AppAtoms.swift`, composed into molecules, organisms, and the `AppScreen` template. See `atomic-design-system.md`.
- **Why**: Fewer one-off styles means faster iteration, fewer bugs, and screens that stay readable under stress (Gym Test).
- **Apply**: Don’t add raw spacing, ad-hoc colors, or duplicate nav/card chrome in feature views when an atom or shared component already exists. Extend the atom or add a molecule/organism, then use it.

---

## Summary

| Principle | One-line |
|-----------|----------|
| Minimalism | Only what’s needed to log, track, and run a cycle. |
| Clarity | Obvious purpose, controls, and state — including Target vs. Actual. |
| Speed | Gym Test: log a set with RIR in under 3 seconds. |
| Consistency | Same patterns and tokens everywhere. |
| Accessibility | HIG-compliant: 44pt targets, 4.5:1 contrast, VoiceOver, Reduce Motion. |
| Atomic tokens | Use `AppAtoms` + `Unit/UI` layers; document changes in `atomic-design-system.md`. |

Every design decision should be checked against these; when in doubt, favor **speed** and **minimalism** for the active workout experience.
