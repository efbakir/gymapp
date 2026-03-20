# Apple HIG Reference — Unit

Curated Human Interface Guidelines rules that directly govern Unit decisions.

| Rule | HIG Requirement | Unit Application |
|------|----------------|----------------------|
| **Touch Targets** | Minimum 44×44pt for all interactive elements | All set rows `frame(minHeight: 52)`, RIR capsules `frame(minHeight: 44)`, tab bar items (system default ≥44pt) |
| **Tab Bar** | Maximum 5 items; tabs navigate only — never trigger actions | 4 tabs (Home, Program, Cycles, History) ✓; no action tabs |
| **Typography** | SF Pro system font; Dynamic Type support; minimum 11pt | New/refactored UI uses `AppFont` from `Unit/UI/Atoms/AppAtoms.swift`; legacy screens may still use older theme types during migration |
| **Contrast** | 4.5:1 for normal text; 3:1 for large text (WCAG AA) | Verify primary text on `AppColor.background` / `AppColor.cardBackground`; failure states use red + icon + label, not color alone |
| **Color as sole indicator** | Never rely on color alone to convey meaning | Failure row: red background + `xmark.circle.fill` icon + "Missed" label. Deload: orange + `arrow.down.circle.fill` icon + "Deload" text |
| **Appearance** | Respect system appearance where applicable | Light-first product baseline via `AppColor`; prefer tokens over hardcoded `.black` / `.white` in new UI |
| **Navigation** | `TabView` → `NavigationStack` → Sheets for modal tasks | Cycles tab → `WeekDetailView` (NavigationStack push) → `CreateCycleView` (sheet) ✓ |
| **Motion** | Respect Reduce Motion preference | All animated transitions guarded with `@Environment(\.accessibilityReduceMotion)`. Toast uses `.opacity` when reduce motion is on, `.move + .opacity` otherwise |
| **VoiceOver** | All interactive elements need accessible labels; custom views need `.accessibilityValue` | Set rows: `.accessibilityValue("Target: Xkg × Y reps. Actual: Akg × B reps")`. RIR buttons: `.accessibilityLabel("RIR 0 — failure")`. Heatmap cells: date + volume string |
| **Sheets** | Use `.presentationDetents` to size sheets appropriately | Failure modal: `.height(280)`. Projected week: `.medium`. Create Cycle: full screen |
| **Lists** | Minimum row height 44pt | All `SessionRow`, `SessionDetailView` rows: `frame(minHeight: 44)` |
| **Buttons** | Destructive actions require confirmation | "Reset Cycle" uses `.confirmationDialog` with `.destructive` role |
| **Forms** | Use `Form` for structured data entry | `CreateCycleView` and `CycleSettingsView` use SwiftUI `Form` |
| **Charts** | Use Charts framework (no third-party) | Tonnage bar chart in Rest Day Card, sparklines in PR Library, heatmap — all use Swift Charts |

---

## Contrast checks (light baseline)

- **Primary CTA**: `AppPrimaryButton` uses accent fill + white label — verify ≥ 4.5:1 for the label on the accent background.
- **Body text**: `AppColor.textPrimary` on `AppColor.background` / `AppColor.cardBackground` should meet WCAG AA for workout flows.
- **Secondary text**: `AppColor.textSecondary` on page/card surfaces — verify readability in bright gym lighting.
- **Failure / error**: system red tones from `AppColor.error` — pair with icon + copy, not color alone.

---

## Notes

- Never gate a11y behind a toggle — all accessibility attributes are always present
- `accessibilityHidden(true)` used only for decorative icons that are already described by adjacent text
- `accessibilityElement(children: .combine)` used on multi-element rows so VoiceOver reads them as a single unit
