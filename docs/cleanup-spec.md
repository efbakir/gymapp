# Unit App Cleanup Specification

This document outlines all proposed changes for code cleanup, design system consolidation, and UI consistency fixes. Review and approve before implementation.

---

## Overview

| Category | Changes |
|----------|---------|
| Duplicate Files | 2 files to delete |
| Theme Rename | `AtlasTheme` → `Theme` (492+ references across 18 files) |
| Component Extraction | 12 embedded components to extract |
| UI Inconsistencies | 8 fixes required |
| File Restructure | New `/Unit/Theme/` and `/Unit/Components/` directories |

---

## 1. Duplicate Files to Delete

### 1.1 `Unit/Features/Today/CyclesView.swift` (DELETE)

**Reason**: Stale stub file. The real implementation lives at `Unit/Features/Cycles/CyclesView.swift` (307 lines vs 51 lines).

```
DELETE: Unit/Features/Today/CyclesView.swift
KEEP:   Unit/Features/Cycles/CyclesView.swift
```

### 1.2 `Unit/Models/ProgressionEngine.swift` (DELETE)

**Reason**: Outdated version (49 lines). The canonical implementation lives at `Unit/Engine/ProgressionEngine.swift` (123 lines) with full deload logic and proper `SessionOutcome` type.

```
DELETE: Unit/Models/ProgressionEngine.swift
KEEP:   Unit/Engine/ProgressionEngine.swift
```

---

## 2. Theme Rename: AtlasTheme → Theme

### 2.1 Rationale

"AtlasTheme" is unclear naming that doesn't convey meaning. Renaming to simply `Theme` improves clarity and follows SwiftUI conventions.

### 2.2 Files Affected (18 files, 492+ references)

| File | Count |
|------|-------|
| ActiveWorkoutView.swift | 107 |
| TodayView.swift | 63 |
| CyclesView.swift | 58 |
| ExerciseProgressView.swift | 38 |
| ExercisesListView.swift | 34 |
| HistoryView.swift | 31 |
| TemplatesView.swift | 29 |
| WeekDetailView.swift | 22 |
| CreateCycleView.swift | 21 |
| SessionDetailView.swift | 20 |
| TemplateDetailView.swift | 20 |
| AddTemplateView.swift | 13 |
| CyclesView.swift (Today/) | 10 |
| CycleSettingsView.swift | 9 |
| PRLibraryView.swift | 7 |
| ContentView.swift | 6 |
| SettingsView.swift | 2 |

### 2.3 Rename Mapping

```swift
// BEFORE
AtlasTheme.Colors.accent       → Theme.Colors.accent
AtlasTheme.Colors.background   → Theme.Colors.background
AtlasTheme.Colors.card         → Theme.Colors.card
AtlasTheme.Colors.textPrimary  → Theme.Colors.textPrimary
AtlasTheme.Colors.textSecondary → Theme.Colors.textSecondary
AtlasTheme.Colors.border       → Theme.Colors.border
AtlasTheme.Colors.ghostText    → Theme.Colors.ghostText
AtlasTheme.Colors.accentSoft   → Theme.Colors.accentSoft
AtlasTheme.Colors.progress     → Theme.Colors.progress
AtlasTheme.Colors.failureAccent → Theme.Colors.failure
AtlasTheme.Colors.deloadBadge  → Theme.Colors.deload
AtlasTheme.Colors.elevatedBackground → Theme.Colors.elevated

AtlasTheme.Spacing.xxs         → Theme.Spacing.xxs
AtlasTheme.Spacing.xs          → Theme.Spacing.xs
AtlasTheme.Spacing.sm          → Theme.Spacing.sm
AtlasTheme.Spacing.md          → Theme.Spacing.md
AtlasTheme.Spacing.lg          → Theme.Spacing.lg
AtlasTheme.Spacing.xl          → Theme.Spacing.xl
AtlasTheme.Spacing.xxl         → Theme.Spacing.xxl

AtlasTheme.Radius.sm           → Theme.Radius.sm
AtlasTheme.Radius.md           → Theme.Radius.md
AtlasTheme.Radius.lg           → Theme.Radius.lg

AtlasTheme.Typography.hero     → Theme.Typography.hero
AtlasTheme.Typography.sectionTitle → Theme.Typography.title
AtlasTheme.Typography.body     → Theme.Typography.body
AtlasTheme.Typography.caption  → Theme.Typography.caption
AtlasTheme.Typography.metric   → Theme.Typography.metric

atlasCardStyle()               → cardStyle()
AtlasScaleButtonStyle          → ScaleButtonStyle
```

### 2.4 New Theme File Location

Move theme definition from `ContentView.swift` to dedicated file:

```
NEW: Unit/Theme/Theme.swift
```

---

## 3. Component Extraction Plan

### 3.1 New Directory Structure

```
Unit/
├── Components/
│   ├── Cards/
│   │   ├── TrainingDayCard.swift
│   │   ├── RestDayCard.swift
│   │   ├── NoCycleCard.swift
│   │   └── DayCard.swift
│   ├── Inputs/
│   │   ├── MetricInputField.swift
│   │   └── RIRStepper.swift
│   ├── Rows/
│   │   ├── CompletedSetRow.swift
│   │   ├── SessionRow.swift
│   │   └── ExerciseTargetRow.swift
│   ├── Feedback/
│   │   ├── Toast.swift
│   │   └── ProgressRing.swift
│   └── Timer/
│       ├── RestTimerPanel.swift
│       └── RestTimerManager.swift
├── Theme/
│   └── Theme.swift
```

### 3.2 Components to Extract

| Component | Current Location | Lines | Priority |
|-----------|-----------------|-------|----------|
| `Theme` | ContentView.swift | ~65 | HIGH |
| `ExerciseLoggingCard` | ActiveWorkoutView.swift | ~145 | HIGH |
| `MetricInputField` | ActiveWorkoutView.swift | ~25 | HIGH |
| `RIRStepper` | ActiveWorkoutView.swift | ~45 | HIGH |
| `CompletedSetRow` | ActiveWorkoutView.swift | ~70 | HIGH |
| `RestTimerPanel` | ActiveWorkoutView.swift | ~30 | MEDIUM |
| `RestTimerManager` | ActiveWorkoutView.swift | ~60 | MEDIUM |
| `TrainingDayCard` | TodayView.swift | ~40 | MEDIUM |
| `RestDayCard` | TodayView.swift | ~45 | MEDIUM |
| `NoCycleCard` | TodayView.swift | ~15 | LOW |
| `DayCardView` | TodayView.swift | ~50 | MEDIUM |
| `ProgressRing` | CyclesView.swift | ~20 | LOW |
| `CalendarHeatmap` | HistoryView.swift | ~60 | LOW |
| `SessionRow` | HistoryView.swift | ~30 | Already public |

---

## 4. UI Inconsistencies to Fix

### 4.1 Button Heights

**Current State**: Mixed `44pt`, `52pt`, `height: 44`, `minHeight: 44`

**Fix**: Standardize to:
- Primary CTA: `52pt` (filled accent buttons)
- Secondary/text buttons: `44pt` minimum touch target
- Stepper buttons: `44pt`

| Location | Current | Target |
|----------|---------|--------|
| "Start Session" button | 44 | 52 |
| "End Workout" button | 52 | 52 (correct) |
| "Done" button (set logging) | 44 | 44 (correct) |
| "Create Split" button | 52 | 52 (correct) |
| Feeling buttons | 44x44 | 44x44 (correct) |

### 4.2 Card Background Inconsistency

**Current State**: Most use `.atlasCardStyle()` but some inline the background

**Fix**: All cards must use the view modifier

**Files to update**:
- `AddSplitView.swift`: TextField uses inline `AtlasTheme.Colors.card`
- `MetricInputField`: Uses inline `AtlasTheme.Colors.background`
- `TargetColumn`: Uses inline `AtlasTheme.Colors.background`

### 4.3 Input Field Styling

**Current State**: Inconsistent border treatment

| Location | Has Border | Border Color |
|----------|------------|--------------|
| MetricInputField | Yes | `AtlasTheme.Colors.border` |
| AddSplitView TextField | Yes | `AtlasTheme.Colors.border` |
| SplitDetailView TextField | No | — |
| CreateCycleView TextField | Yes | `AtlasTheme.Colors.border` |

**Fix**: All text inputs use consistent styling:
```swift
.overlay(
    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
        .stroke(Theme.Colors.border, lineWidth: 0.5)
)
```

### 4.4 Week Badge Styling

**Current State**: "Week X" badge appears differently

| Location | Style |
|----------|-------|
| ActiveWorkoutView header | `accentSoft` bg + `textSecondary` text |
| SessionRow | `accentSoft` bg + `accent` text |
| WeekRowView | Custom border treatment |

**Fix**: Create unified `WeekBadge` component:
```swift
struct WeekBadge: View {
    let weekNumber: Int
    let isActive: Bool
    
    var body: some View {
        Text("Week \(weekNumber)")
            .font(Theme.Typography.caption)
            .foregroundStyle(isActive ? Theme.Colors.accent : Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(Theme.Colors.accentSoft)
            .clipShape(Capsule())
    }
}
```

### 4.5 List vs ScrollView

**Current State**: Inconsistent container usage

| Screen | Container | Background |
|--------|-----------|------------|
| TodayView | ScrollView | `Theme.Colors.background` |
| HistoryView | List (insetGrouped) | System |
| TemplatesView | List | System |
| CyclesView | ScrollView | `Theme.Colors.background` |
| SettingsView | Form | System |

**Fix**: 
- Keep `List`/`Form` for screens with native iOS patterns (Settings, History sessions, Templates)
- Use `ScrollView` for custom card layouts (Today, Cycles)
- Ensure background color is consistent when using ScrollView

### 4.6 Divider Usage

**Current State**: Inconsistent

| Location | Has Divider |
|----------|-------------|
| TrainingDayCard | Yes |
| RestDayCard | Yes |
| DayCardView | Yes |
| ExerciseLoggingCard | No |
| SessionRow | No |

**Fix**: Dividers only within cards when separating distinct content sections. Remove from:
- Cards with only header + stats (no separation needed)

### 4.7 Toast Component

**Current State**: Inline toast in ActiveWorkoutView only

**Fix**: Extract to reusable `Toast` component that can be used anywhere:

```swift
struct Toast: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(Theme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())
    }
}
```

### 4.8 "Missed" Label Duplication

**Current State**: `CompletedSetRow` shows both "Missed" label AND xmark icon

```swift
Label("Missed", systemImage: "xmark.circle.fill")
// ...
Image(systemName: isFailed ? "xmark.circle.fill" : "checkmark.circle.fill")
```

**Fix**: Show either label OR icon, not both. The current pattern shows the xmark twice.

---

## 5. Code Quality Fixes

### 5.1 File Size Reduction

| File | Current Lines | Target | Method |
|------|---------------|--------|--------|
| ActiveWorkoutView.swift | 887 | ~350 | Extract 6 components |
| TodayView.swift | 529 | ~250 | Extract 5 components |
| CyclesView.swift | 307 | ~200 | Extract 2 components |
| HistoryView.swift | 310 | ~180 | Extract 2 components |

### 5.2 ViewModel Consistency

**Current State**: Only some views use ViewModels

| View | Has ViewModel |
|------|---------------|
| TodayView | Yes (`TodayDashboardViewModel`) |
| ActiveWorkoutView | Yes (`ActiveWorkoutViewModel`) |
| HistoryView | No |
| TemplatesView | No |
| CyclesView | No |
| SettingsView | No |

**Recommendation**: Keep current pattern — ViewModels only for complex computation. Simple CRUD views don't need them.

### 5.3 Import Cleanup

Remove unused imports where present:
- `import Charts` — only needed in HistoryView, ExerciseProgressView
- `import ActivityKit` — only needed in ActiveWorkoutView

---

## 6. Implementation Order

1. **Delete duplicate files** (2 files)
2. **Create Theme.swift** and move theme definition
3. **Rename AtlasTheme → Theme** across all files
4. **Extract components** (start with highest priority)
5. **Fix UI inconsistencies**
6. **Update documentation** to reflect new naming

---

## 7. Files Changed Summary

### Deleted (2)
- `Unit/Features/Today/CyclesView.swift`
- `Unit/Models/ProgressionEngine.swift`

### Created (14)
- `Unit/Theme/Theme.swift`
- `Unit/Components/Cards/TrainingDayCard.swift`
- `Unit/Components/Cards/RestDayCard.swift`
- `Unit/Components/Cards/NoCycleCard.swift`
- `Unit/Components/Cards/DayCard.swift`
- `Unit/Components/Inputs/MetricInputField.swift`
- `Unit/Components/Inputs/RIRStepper.swift`
- `Unit/Components/Rows/CompletedSetRow.swift`
- `Unit/Components/Rows/ExerciseTargetRow.swift`
- `Unit/Components/Feedback/Toast.swift`
- `Unit/Components/Feedback/ProgressRing.swift`
- `Unit/Components/Feedback/WeekBadge.swift`
- `Unit/Components/Timer/RestTimerPanel.swift`
- `Unit/Components/Timer/RestTimerManager.swift`

### Modified (18)
All Swift files with AtlasTheme references will be updated with new naming.

---

## 8. Design System After Cleanup

### Final Component Count

| Role | Count | Components |
|------|-------|------------|
| Background levels | 3 | `background`, `elevated`, `card` |
| Accent colors | 1 | `accent` (#FF4400) |
| State colors | 2 | `failure` (red), `deload` (orange) |
| Text hierarchy | 3 | `textPrimary`, `textSecondary`, `ghostText` |
| Button variants | 2 | Primary (filled), Secondary (text) |
| Card variants | 1 | `cardStyle()` modifier |
| Input variants | 1 | `MetricInputField` |
| Badge variants | 1 | `WeekBadge` |

---

## Approval Required

Please review this specification and confirm:

1. **Duplicate deletion** — OK to delete the two stale files?
2. **Theme rename** — OK to rename AtlasTheme → Theme?
3. **Component extraction** — OK to create the new directory structure?
4. **UI fixes** — Any items you want to skip or modify?

Once approved, I will implement all changes.
