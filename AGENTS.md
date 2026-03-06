# Atlas Log — Agent Guidance

This file orients AI agents (e.g. Claude Code, Cursor) working on the Atlas Log codebase.

## What this project is

Atlas Log is an **Adaptive Periodization Engine** for iOS. The primary user container is the **8-Week Cycle**. The core UI paradigm is **Target vs. Actual** — the app computes the target weight before every set, then adjusts future weeks automatically when the user fails.

The **Gym Test** still applies: logging a set (weight, reps, RIR) in **under 3 seconds** under physical stress.

## Tech stack

- **Swift 6** (concurrency-safe), **SwiftUI** (NavigationStack), **SwiftData** (local-first, CloudKit-ready later).
- **iOS 18+** (Live Activities for rest timer).
- **Charts framework** (Swift Charts — no third-party charting).

## Where to look

| Topic | Location |
|-------|----------|
| Design principles | `docs/design-principles.md` |
| Visual language (dark mode, colors, components) | `docs/visual-language.md` |
| Product manifesto | `docs/PRODUCT_MANIFESTO.md` |
| App positioning | `docs/APP_POSITIONING.md` |
| Use cases | `docs/USE_CASES.md` |
| Apple HIG reference | `docs/apple-hig.md` |
| Competitors | `docs/competitors.md`, `docs/competitors-analysis.md` |
| Cognitive / behavior / mental models | `docs/cognitive-principles.md`, `docs/behavior-change.md`, `docs/mental-models.md` |
| Values and goals | `docs/values.md`, `docs/goals.md` |
| GPT/AI custom instructions (UX/product execution) | `docs/custom-instructions.md` |

## Project structure

| Folder | Contents |
|--------|----------|
| `AtlasLog/Models/` | SwiftData models: Split, Exercise, DayTemplate, WorkoutSession, SetEntry, Cycle, ProgressionRule |
| `AtlasLog/Engine/` | `ProgressionEngine.swift` — pure functional progression logic |
| `AtlasLog/Features/Today/` | TodayView, ActiveWorkoutView (target column, RIR stepper, failure modal, toast) |
| `AtlasLog/Features/Cycles/` | CyclesView, WeekDetailView, CreateCycleView, CycleSettingsView |
| `AtlasLog/Features/Templates/` | Split and day template management |
| `AtlasLog/Features/History/` | HistoryView (heatmap), SessionDetailView, PRLibraryView |

## Critical rules

- **All target calculations must go through `ProgressionEngine.swift`. No view or ViewModel may compute targets directly.**
- Follow SwiftData schema (see `AtlasLog/Models/`). New optional fields with defaults use lightweight migration automatically — no `VersionedSchema` needed.
- Optimize for the Gym Test: defaults, one-tap set completion, RIR stepper (not RPE menu), large CTAs.
- Dark mode native: use system semantic colors (`Color(.systemBackground)`, `Color(.systemGroupedBackground)`, `Color(uiColor: .separator)`). No hardcoded white surfaces or black borders.
- HIG compliance: all interactive elements ≥ 44pt; never color alone for meaning; guard animated transitions with `@Environment(\.accessibilityReduceMotion)`.
- No social feed, no videos, no exercise discovery in core flow.

## Conventions

- `AtlasTheme` in `ContentView.swift` is the single source of design tokens. Add new tokens there.
- `PreviewSampleData` in `AtlasLogApp.swift` seeds 1 Cycle + ProgressionRules. Keep it up to date when adding models.
- Engine types (`WeekTarget`, `SessionOutcome`, `ProgressionRuleSnapshot`) are pure value types — no `@Model`, no SwiftUI imports in `ProgressionEngine.swift`.
