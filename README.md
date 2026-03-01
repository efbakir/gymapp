# Atlas Log

High-performance, minimalist gym logger for iOS. Log your program in under 3 seconds per set (the **Gym Test**)—no social feed, no videos, no clutter.

## Tech stack

- **Swift 6** (strict concurrency)
- **SwiftUI** (NavigationStack)
- **SwiftData** (local-first; schema ready for CloudKit later)
- **iOS 18+**
- **Live Activities** (rest timer on Lock Screen / Dynamic Island)

## Project structure

- **AtlasLog/** – Main app (Today, Templates, History; active workout; rest timer with Live Activity)
- **AtlasLogWidget/** – Widget Extension for rest timer Live Activity
- **docs/** – Strategy: competitors, design principles, visual language, cognitive/behavior, mental models, values, goals

## Data model (SwiftData)

- **Split** – id, name, orderedTemplateIds
- **Exercise** – id, displayName, aliases, notes, isBodyweight
- **DayTemplate** – id, name, splitId, orderedExerciseIds, lastPerformedDate
- **WorkoutSession** – id, date, templateId, isCompleted, overallFeeling (1–5)
- **SetEntry** – id, sessionId, exerciseId, weight, reps, rpe, isWarmup, isCompleted, setIndex

## Build and run

1. Open `AtlasLog.xcodeproj` in Xcode.
2. Select the **AtlasLog** scheme and a simulator or device (iOS 18+).
3. Build and run (⌘R).

The **AtlasLogWidgetExtension** target is built with the app and provides the rest timer Live Activity.

## Design and product

- **Design principles**: [docs/design-principles.md](docs/design-principles.md)
- **Visual language**: [docs/visual-language.md](docs/visual-language.md) (Cash App–inspired)
- **Competitors**: [docs/competitors.md](docs/competitors.md), [docs/competitors-analysis.md](docs/competitors-analysis.md)
- **Goals**: [docs/goals.md](docs/goals.md)

## License

Proprietary.
