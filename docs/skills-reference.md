# Unit — Skills Reference

The [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) list targets OpenClaw agents, not Cursor. This doc lists skills we use as **reference** for concepts, patterns, and “what we can learn.” No installation of those skills into Cursor—we document takeaways for Unit.

---

## iOS & macOS Development

| Skill | What we can learn |
|-------|--------------------|
| **apple-hig** | Apple Human Interface Guidelines for iOS/macOS/watchOS—layout, navigation, accessibility. Use when reviewing UI for HIG alignment. |
| **swift-concurrency-expert** | Swift 6 concurrency (actors, Sendable, MainActor). Use for SwiftData and any background work. |
| **swiftui-empty-app-init** | Minimal SwiftUI app structure. Reference for project bootstrap. |
| **swiftui-performance-audit** | SwiftUI performance (body evaluation, @State, list performance). Keep active workout list and queries efficient. |
| **swiftui-ui-patterns** | Best practices and patterns for SwiftUI views. Align with our visual language and design principles. |
| **swiftui-view-refactor** | How to structure and refactor SwiftUI views. Keep views focused and testable. |
| **instruments-profiling** | Profiling native iOS/macOS apps. Use if we hit performance issues. |
| **ios-simulator** | Automating iOS Simulator (simctl, idb). Helpful for testing and CI. |
| **healthkit-sync** | HealthKit data patterns. Future: optional HealthKit export or read (e.g. body weight). |

---

## Health & Fitness

| Skill | What we can learn |
|-------|--------------------|
| **hevy** | Hevy’s workout data model and API. Reinforces our schema (workouts, exercises, sets) and ideas for defaults/history. |
| **workout** (workout-cli) | Track workouts, log sets, manage exercises and templates. Close to our domain; reinforces template + set logging. |
| **workout-logger** | Log workouts, progress, suggestions. Ideas for progress display and session completion. |
| **ranked-gym** | Gamification (XP, levels). We stay minimal; reference for “what to avoid” or future light engagement (e.g. streaks only). |
| **muscle-gain** | Weight progression, protein tracking. We focus on set logging; progression can be a future feature. |
| **strava** | Activity and stats. Reference for history/analytics presentation, not for social. |

---

## Design & UX

| Skill | What we can learn |
|-------|--------------------|
| **apple-hig** | (See above.) Primary reference for iOS visual and interaction standards. |

Our **design principles** and **visual language** docs (see [design-principles.md](design-principles.md), [visual-language.md](visual-language.md)) are the source of truth; these skills reinforce or contrast with them.

---

## Summary

- **Use**: apple-hig for HIG; swift-concurrency-expert for Swift 6; swiftui-performance-audit and swiftui-ui-patterns for view structure; hevy and workout for domain model and logging flow.
- **Don’t**: Install OpenClaw skills into Cursor; they’re for a different agent. We only extract patterns and document them here and in Cursor rules.
