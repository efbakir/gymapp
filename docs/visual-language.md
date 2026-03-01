# Atlas Log — Visual Language

Inspired by [Cash App](https://cash.app/) and the referenced collage: a high-performance, minimalist look that supports the Gym Test and feels focused and modern.

---

## 1. Color

- **Backgrounds**: Prefer clean white or very light grey. High contrast so content and accent read clearly in bright gyms.
- **Primary accent**: One strong **bright orange/red** primary color for actions (e.g. “Complete set,” “Start rest”), completed state, and key highlights. The accent should carry through CTAs, selection states, and success indicators, similar to how Cash App’s foundations use a single vivid brand color across surfaces ([design.cash.app/foundations](https://design.cash.app/foundations)).
- **Supportive neutrals**: Primary text black or near-black; secondary (hints, labels) in grey. No low-contrast grey-on-white for critical info.
- **Secondary accents**: Optional subtle secondary color (e.g. soft warm grey or muted blue) for progress or charts; it must not compete with the bright orange/red primary.

---

## 2. Typography

- **Hierarchy**: Large, bold for critical numbers (e.g. weight, reps) and main headings (e.g. exercise name, “Push A”). Medium for subheadings and action labels. Regular/light and smaller for secondary info (e.g. “Set 3,” “Last: 80 kg × 5”).
- **Font**: System font (San Francisco) for consistency and accessibility. Prefer Dynamic Type–friendly styles.
- **Rule**: The most important thing on screen (e.g. current set to log, rest countdown) should be the most prominent.

---

## 3. Layout and structure

- **Whitespace**: Generous spacing so content breathes. Avoid cramped set lists.
- **Cards**: Group content in rounded-rectangle cards (e.g. one card per exercise, or one per set row) with subtle shadow or border. Clearly segment “this exercise” vs “this set.”
- **Navigation**: Consistent top bar (title, back/close where needed). Bottom bar or floating action for primary actions (e.g. “Start rest,” “Complete set”) so they’re thumb-friendly.

---

## 4. Components and patterns

- **Primary CTA**: Rounded, filled with accent color (e.g. “Complete set,” “Start workout”). High visibility and large tap target.
- **Secondary actions**: Outlined or text-only with accent color (e.g. “Skip RPE,” “Edit”).
- **Inputs**: Large tappable areas for weight/reps. Pre-filled defaults. Optional RPE as picker (1–10) or compact control, not required.
- **Success feedback**: Clear confirmation after logging a set (e.g. checkmark, brief state change). No ambiguous “did it save?”
- **Modals / sheets**: Use bottom sheets or modals for focused tasks (e.g. edit set, pick template) so the user stays in context without full-screen jumps.

---

## 5. Iconography

- **Style**: Simple, consistent (e.g. SF Symbols). Line or flat; avoid decorative detail.
- **Color**: Icons in black/grey; accent for active or primary (e.g. play for rest timer when running).
- **Use**: Rest timer, add set, complete set, templates, history. No clutter.

---

## 6. Rest timer and Live Activity

- **In-app**: Rest timer visible on the active workout screen: big countdown or “Rest: 1:30” with start/pause. Same accent for “running.”
- **Live Activity**: When rest is running, show countdown on Lock Screen and in Dynamic Island so the user can put the phone down. Minimal, legible, same visual language (accent, clear numbers).

---

## 7. What we’re not doing (yet)

- No full design system (tokens, component library) in v1—enough structure to keep UI consistent and to guide future tokens.
- No dark mode requirement in v1 (can be added later with same principles).
- No illustrations or marketing imagery in-app; focus on data and actions.

---

## Summary

| Element | Guideline |
|--------|-----------|
| Color | Light backgrounds, one strong accent, black/grey text. |
| Type | Clear hierarchy; critical numbers and headings prominent. |
| Layout | Cards, whitespace, consistent nav and bottom actions. |
| CTAs | Primary = accent, filled, large; secondary = outline/text. |
| Feedback | Clear success state (e.g. checkmark) after logging. |
| Rest timer | Big in-app; same language in Live Activity. |

This visual language supports the **Gym Test** (fast, clear, low friction) and aligns with the design principles in [design-principles.md](design-principles.md).
