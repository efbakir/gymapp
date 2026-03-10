---
name: swift_swiftui
description: SwiftUI framework concepts including property wrappers, state management, @Observable macro, SwiftData integration, and reactive UI patterns. Targets iOS 17+ / iOS 18+.
license: Proprietary
compatibility: SwiftUI 1.0+ (iOS 17+ patterns preferred)
metadata:
  version: "2.0"
  author: SwiftZilla
  website: https://swiftzilla.dev
---

# SwiftUI

This skill covers SwiftUI framework concepts for building declarative user interfaces, with emphasis on iOS 17+ patterns (`@Observable`, `@Bindable`) and SwiftData integration.

## Overview

SwiftUI is Apple's modern declarative framework for building user interfaces across all Apple platforms using a reactive, state-driven approach. As of iOS 17+, the `@Observable` macro replaces `ObservableObject` as the primary way to build observable view models. SwiftData integrates with `@Query` and `@Environment(\.modelContext)`.

## Available References

- [Property Wrappers](./references/property_wrappers.md) - @State, @Binding, @Environment, @Observable, @Bindable, @Query, legacy @ObservedObject/@StateObject
- [Observable Macro](./references/observable.md) - Deep dive on @Observable, @Bindable, and migration from ObservableObject

## iOS Version Guidance

| Pattern | Minimum OS | Notes |
|---------|-----------|-------|
| `@Observable` + `@Bindable` | iOS 17+ | **Preferred for new code** |
| `@Query` + `@Environment(\.modelContext)` | iOS 17+ | SwiftData integration |
| `ObservableObject` + `@StateObject` | iOS 14+ | Legacy; still valid |
| `@State` / `@Binding` / `@Environment` | iOS 13+ | Unchanged, still used |

## Quick Reference

### State Management Decision Tree (iOS 17+)

```
Need local mutable state?
├── YES → Is it a value type?
│   ├── YES → Use @State
│   └── NO → Use @State with @Observable class
└── NO → Shared from parent?
    ├── YES → Is it a value type?
    │   ├── YES → Use @Binding
    │   └── NO → Use @Bindable (iOS 17+) or @ObservedObject (iOS 14+)
    └── NO → App-wide / environment?
        ├── YES → Use @Environment (injected @Observable or system value)
        └── NO → SwiftData query?
            ├── YES → Use @Query
            └── NO → Use @EnvironmentObject (legacy fallback)
```

### Property Wrappers

| Wrapper | iOS | Owns Data | Data Type | Use For |
|---------|-----|-----------|-----------|---------|
| `@State` | 13+ | Yes | Value type | Local UI state |
| `@Binding` | 13+ | No | Value type | Shared state with parent |
| `@Environment` | 13+ | No | Any | System values, injected @Observable |
| `@Observable` | 17+ | — | Class macro | Observable view models |
| `@Bindable` | 17+ | No | @Observable class | Two-way binding to observable |
| `@Query` | 17+ | Yes | SwiftData @Model | SwiftData fetch + live updates |
| `@StateObject` | 14+ | Yes | ObservableObject | Owned legacy view models |
| `@ObservedObject` | 14+ | No | ObservableObject | Injected legacy view models |
| `@EnvironmentObject` | 13+ | No | ObservableObject | Legacy shared state |

### Common Usage Patterns (iOS 17+)

```swift
// Local value state — unchanged
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        Button("Count: \(count)") { count += 1 }
    }
}

// Shared value state — unchanged
struct ParentView: View {
    @State private var isOn = false

    var body: some View {
        ChildView(isOn: $isOn)
    }
}

struct ChildView: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("Enable", isOn: $isOn)
    }
}

// Observable view model (iOS 17+ — preferred over ObservableObject)
@Observable
class WorkoutViewModel {
    var sets: [SetEntry] = []
    var isActive = false
}

struct WorkoutView: View {
    @State private var vm = WorkoutViewModel()  // @State, not @StateObject

    var body: some View {
        List(vm.sets) { set in Text(set.label) }
    }
}

// Two-way binding into @Observable (iOS 17+)
struct EditView: View {
    @Bindable var vm: WorkoutViewModel

    var body: some View {
        Toggle("Active", isOn: $vm.isActive)
    }
}

// Injecting @Observable via environment (iOS 17+)
struct RootView: View {
    @State private var appModel = AppModel()

    var body: some View {
        ContentView()
            .environment(appModel)
    }
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel  // No key path needed

    var body: some View {
        Text(appModel.username)
    }
}

// SwiftData: query + model context
struct ExerciseListView: View {
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Environment(\.modelContext) private var context

    var body: some View {
        List(exercises) { ex in Text(ex.displayName) }
        Button("Add") {
            context.insert(Exercise(displayName: "New"))
        }
    }
}

// Environment system values — unchanged
struct ThemeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text(colorScheme == .dark ? "Dark" : "Light")
    }
}
```

## Best Practices

1. **Prefer @Observable over ObservableObject** — Simpler syntax, no @Published needed, iOS 17+
2. **Use @State to own @Observable objects** — Not @StateObject (that's only for ObservableObject)
3. **Use @Bindable for two-way binding into @Observable** — Replaces the @ObservedObject binding pattern
4. **Inject @Observable via .environment()** — Accessed with `@Environment(Type.self)`, no EnvironmentKey needed
5. **Use @Query for SwiftData** — Automatically reflects model changes; supports sort, filter, limit
6. **Keep @State minimal** — Only store what's needed for UI
7. **Use @Environment for system values** — colorScheme, dismiss, locale, modelContext
8. **All property wrappers require @MainActor** — Access only from main thread

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Using @StateObject with @Observable class | Use `@State` instead |
| Using @ObservedObject with @Observable class | Use `@Bindable` instead |
| Using @EnvironmentObject with @Observable | Use `@Environment(Type.self)` instead |
| Initializing @State directly | Use `_property = State(initialValue:)` in custom init |
| Mutating on background thread | Use @MainActor or dispatch to main |
| Passing @State instead of Binding | Use `$property` to get Binding |
| @Query without modelContainer | Add `.modelContainer(for:)` to App or root view |
