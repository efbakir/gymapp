# Apple HIG Reference — Atlas Log

Curated Human Interface Guidelines rules that directly govern Atlas Log decisions.

| Rule | HIG Requirement | Atlas Log Application |
|------|----------------|----------------------|
| **Touch Targets** | Minimum 44×44pt for all interactive elements | All set rows `frame(minHeight: 52)`, RIR capsules `frame(minHeight: 44)`, tab bar items (system default ≥44pt) |
| **Tab Bar** | Maximum 5 items; tabs navigate only — never trigger actions | 4 tabs (Home, Program, Cycles, History) ✓; no action tabs |
| **Typography** | SF Pro system font; Dynamic Type support; minimum 11pt | All text uses semantic styles (`.body`, `.headline`, `.caption`) via `AtlasTheme.Typography` |
| **Contrast** | 4.5:1 for normal text; 3:1 for large text (WCAG AA) | Verify `#FF4400` orange on dark background; failure row uses red + icon, not color alone |
| **Color as sole indicator** | Never rely on color alone to convey meaning | Failure row: red background + `xmark.circle.fill` icon + "Missed" label. Deload: orange + `arrow.down.circle.fill` icon + "Deload" text |
| **Dark Mode** | Use system semantic colors for all surfaces | All surfaces use `Color(.systemBackground)`, `Color(.systemGroupedBackground)`, `Color(uiColor: .separator)` |
| **Navigation** | `TabView` → `NavigationStack` → Sheets for modal tasks | Cycles tab → `WeekDetailView` (NavigationStack push) → `CreateCycleView` (sheet) ✓ |
| **Motion** | Respect Reduce Motion preference | All animated transitions guarded with `@Environment(\.accessibilityReduceMotion)`. Toast uses `.opacity` when reduce motion is on, `.move + .opacity` otherwise |
| **VoiceOver** | All interactive elements need accessible labels; custom views need `.accessibilityValue` | Set rows: `.accessibilityValue("Target: Xkg × Y reps. Actual: Akg × B reps")`. RIR buttons: `.accessibilityLabel("RIR 0 — failure")`. Heatmap cells: date + volume string |
| **Sheets** | Use `.presentationDetents` to size sheets appropriately | Failure modal: `.height(280)`. Projected week: `.medium`. Create Cycle: full screen |
| **Lists** | Minimum row height 44pt | All `SessionRow`, `SessionDetailView` rows: `frame(minHeight: 44)` |
| **Buttons** | Destructive actions require confirmation | "Reset Cycle" uses `.confirmationDialog` with `.destructive` role |
| **Forms** | Use `Form` for structured data entry | `CreateCycleView` and `CycleSettingsView` use SwiftUI `Form` |
| **Charts** | Use Charts framework (no third-party) | Tonnage bar chart in Rest Day Card, sparklines in PR Library, heatmap — all use Swift Charts |

---

## Accent Color Contrast Check

- Brand accent: `#FF4400` (rgb 255, 69, 0)
- On `Color(.systemBackground)` dark mode (approx `#1C1C1E`): contrast ratio ≈ 4.6:1 ✓
- Supplement with white text on accent backgrounds (e.g. "Start" CTA button)
- Ghost text (`Color.secondary`) on dark background: system-managed, always passes
- Red failure accent on `Color(.systemBackground)`: system red passes 4.5:1 on dark ✓

---

## Notes

- Never gate a11y behind a toggle — all accessibility attributes are always present
- `accessibilityHidden(true)` used only for decorative icons that are already described by adjacent text
- `accessibilityElement(children: .combine)` used on multi-element rows so VoiceOver reads them as a single unit
