# Unit

**The only gym logger that auto-adjusts your 8-week plan when you fail.**

Unit is an **Adaptive Periodization Engine** for iOS. It doesn't just record what you lifted — it computes what you should lift next, then recalibrates the entire plan the moment you miss a target.

## Core paradigm: Target vs. Actual

The 8-Week Cycle is the primary container. Before every set, the engine shows you the target weight. You log the actual. When you fail:

- **1–2 misses** → weight repeats next week
- **3 consecutive misses** → 10% automatic deload

No spreadsheets. No guesswork. The app is the coach.

## Tech stack

- **Swift 6** (strict concurrency)
- **SwiftUI** (NavigationStack)
- **SwiftData** (local-first; schema ready for CloudKit later)
- **iOS 18+**
- **Live Activities** (rest timer on Lock Screen / Dynamic Island)
- **Swift Charts** (tonnage heatmap, PR sparklines, rest day tonnage bars)

## Project structure

```
AtlasLog/
  AtlasLogApp.swift         — App entry, ModelContainer, PreviewSampleData
  ContentView.swift         — Tab navigation + AtlasTheme tokens
  Engine/
    ProgressionEngine.swift — Pure functional progression engine (all targets computed here)
  Models/
    Cycle.swift             — 8-week cycle container
    ProgressionRule.swift   — Per-exercise progression parameters
    WorkoutSession.swift    — Session (cycleId, weekNumber added)
    SetEntry.swift          — Set (rir, targetWeight, targetReps, metTarget added)
    DayTemplate.swift       — Split + DayTemplate
    Exercise.swift          — Exercise
  Features/
    Today/
      TodayView.swift       — Training Day / Rest Day / No Cycle context cards
      ActiveWorkoutView.swift — Target column, RIR stepper, failure modal, toast
    Cycles/
      CyclesView.swift      — 8-week list, empty state, past cycles
      WeekDetailView.swift  — Target vs. actual per exercise per week
      CreateCycleView.swift — Cycle creation with per-exercise overrides
      CycleSettingsView.swift — Increment, reset, danger zone
    Templates/              — Split and day template management
    History/
      HistoryView.swift     — Calendar heatmap + session list
      PRLibraryView.swift   — Epley/Brzycki e1RM library with sparklines
      SessionDetailView.swift
AtlasLogWidget/             — Widget Extension (rest timer Live Activity)
docs/                       — Strategy, design, positioning, HIG reference
```

## Data model (SwiftData)

- **Split** — id, name, orderedTemplateIds
- **Exercise** — id, displayName, aliases, notes, isBodyweight
- **DayTemplate** — id, name, splitId, orderedExerciseIds, lastPerformedDate
- **WorkoutSession** — id, date, templateId, isCompleted, overallFeeling, **cycleId**, **weekNumber**
- **SetEntry** — id, sessionId, exerciseId, weight, reps, rpe, **rir**, **targetWeight**, **targetReps**, **metTarget**, isWarmup, isCompleted, setIndex
- **Cycle** — id, name, splitId, startDate, weekCount, globalIncrementKg, isActive, isCompleted
- **ProgressionRule** — id, cycleId, exerciseId, incrementKg, baseWeightKg, baseReps, consecutiveFailures, isDeloaded, deloadPercent

**Rule**: Targets are always computed by `ProgressionEngine.swift`. Never stored per-week.

## Progression engine

```
Actual ≥ Target          → success, failures = 0, next week += increment
Actual < Target          → failure, failures += 1, next week repeats weight
3 consecutive failures   → 10% deload, failures = 0, isDeloaded = true
```

## Build and run

1. Open `AtlasLog.xcodeproj` in Xcode.
2. Select the **AtlasLog** scheme and a simulator or device (iOS 18+).
3. Build and run (⌘R).

The **AtlasLogWidgetExtension** target is built with the app and provides the rest timer Live Activity.

## Design and product

- **Product manifesto**: [docs/PRODUCT_MANIFESTO.md](docs/PRODUCT_MANIFESTO.md)
- **App positioning**: [docs/APP_POSITIONING.md](docs/APP_POSITIONING.md)
- **Use cases**: [docs/USE_CASES.md](docs/USE_CASES.md)
- **Apple HIG reference**: [docs/apple-hig.md](docs/apple-hig.md)
- **Design principles**: [docs/design-principles.md](docs/design-principles.md)
- **Visual language**: [docs/visual-language.md](docs/visual-language.md) (dark mode native, orange `#FF4400`)
- **Competitors**: [docs/competitors.md](docs/competitors.md), [docs/competitors-analysis.md](docs/competitors-analysis.md)
- **Goals**: [docs/goals.md](docs/goals.md)

## License

Proprietary.
