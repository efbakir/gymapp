# Atlas Log — Agent Guidance

This file orients AI agents (e.g. Cursor) working on the Atlas Log codebase.

## What this project is

Atlas Log is a **high-performance, minimalist gym logger** for iOS. Users have their own programs and are tired of messy Notes or bloated trackers with videos and social. The product is a **structured, fast-entry tool** that prioritizes the **Gym Test**: logging a set under physical stress in **under 3 seconds**.

## Tech stack

- **Swift 6** (concurrency-safe), **SwiftUI** (NavigationStack), **SwiftData** (local-first, CloudKit-ready later).
- **iOS 18+** (Live Activities for rest timer).

## Where to look

| Topic | Location |
|-------|----------|
| Project rules (stack, Gym Test, model) | `.cursor/rules/atlas-log.mdc` |
| Design principles | `docs/design-principles.md` |
| Visual language (UI, colors, components) | `docs/visual-language.md` |
| Competitors | `docs/competitors.md`, `docs/competitors-analysis.md` |
| Cognitive / behavior / mental models | `docs/cognitive-principles.md`, `docs/behavior-change.md`, `docs/mental-models.md` |
| Values and goals | `docs/values.md`, `docs/goals.md` |
| Skills reference (OpenClaw-inspired) | `docs/skills-reference.md` |
| GPT custom instructions (UX/product execution) | `docs/custom-instructions.md` |

## Conventions

- Follow the SwiftData schema in `.cursor/rules/atlas-log.mdc` (Exercise, DayTemplate, WorkoutSession, SetEntry).
- Optimize for the Gym Test: defaults, one-tap set completion, optional RPE, large CTAs, rest timer (including Live Activity).
- Keep UI minimal and consistent with `docs/design-principles.md` and `docs/visual-language.md`.
- No social feed, no videos, no exercise discovery in core flow; user-defined templates and exercises only.
