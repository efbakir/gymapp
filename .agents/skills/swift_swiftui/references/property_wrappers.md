---
name: swift_swiftui_property_wrappers
description: SwiftUI property wrappers including @State, @Binding, @ObservedObject, @StateObject, @Environment. Use this skill when users ask about SwiftUI state management, property wrappers, or reactive UI updates.
license: Proprietary
compatibility: SwiftUI 1.0+
metadata:
  version: "1.0"
  author: SwiftZilla
  website: https://swiftzilla.dev
---

# SwiftUI - Property Wrappers

This skill covers SwiftUI property wrappers for state management, including @State, @Binding, @ObservedObject, @StateObject, and @Environment.

## Key Concepts

### Property Wrapper Overview

Property wrappers add behavior to properties. iOS 17+ preferred wrappers are marked ★:
- **@State** - View-local mutable state (value types or @Observable classes)
- **@Binding** - Two-way reference to external state
- **@Observable** ★ - Macro turning a class into an observable model (iOS 17+)
- **@Bindable** ★ - Two-way binding to an @Observable class property (iOS 17+)
- **@Environment** - Shared values from the environment; accepts @Observable types directly (iOS 17+)
- **@Query** ★ - SwiftData fetch with live updates (iOS 17+)
- **@StateObject** - Owned ObservableObject that survives view recreation (iOS 14+, legacy)
- **@ObservedObject** - External ObservableObject that notifies changes (iOS 14+, legacy)
- **@Published** - Notifies ObservableObject observers of changes (legacy, not needed with @Observable)

### State Ownership Model

| Wrapper | iOS | Owns Data | Data Type | Lifetime |
|---------|-----|-----------|-----------|----------|
| `@State` | 13+ | Yes | Value type or @Observable | View lifetime |
| `@Binding` | 13+ | No | Value type | Parent's lifetime |
| `@Bindable` | 17+ | No | @Observable class | Parent's lifetime |
| `@Environment` | 13+ | No | Any / @Observable | App / ancestor lifetime |
| `@Query` | 17+ | Yes | SwiftData @Model | SwiftData store lifetime |
| `@StateObject` | 14+ | Yes | ObservableObject | View lifetime (legacy) |
| `@ObservedObject` | 14+ | No | ObservableObject | Parent's lifetime (legacy) |

## Code Examples

### @State - Local State

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
    
    // Custom initializer
    init(initialCount: Int) {
        _count = State(initialValue: initialCount)
    }
}
```

### @Binding - Shared State

```swift
struct ToggleView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("Enable Feature", isOn: $isOn)
    }
}

struct ParentView: View {
    @State private var featureEnabled = false
    
    var body: some View {
        ToggleView(isOn: $featureEnabled)
    }
}
```

### @ObservedObject - External State

```swift
class ViewModel: ObservableObject {
    @Published var count = 0
    @Published var message = ""
    
    func increment() {
        count += 1
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Button("Increment") {
                viewModel.increment()
            }
        }
    }
}
```

### @StateObject - Owned Reference

```swift
struct PersistentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Button("Increment") {
                viewModel.increment()
            }
        }
    }
}
```

### @Observable - Observable Model (iOS 17+)

```swift
// No ObservableObject, no @Published — just @Observable
@Observable
class CycleViewModel {
    var currentWeek = 1
    var isActive = false
    var sessions: [WorkoutSession] = []
}

// Owned by a view — use @State (not @StateObject!)
struct CycleView: View {
    @State private var vm = CycleViewModel()

    var body: some View {
        Text("Week \(vm.currentWeek)")
    }
}

// Passed in from parent — use @Bindable for two-way binding
struct EditCycleView: View {
    @Bindable var vm: CycleViewModel

    var body: some View {
        Toggle("Active", isOn: $vm.isActive)
        Stepper("Week \(vm.currentWeek)", value: $vm.currentWeek, in: 1...8)
    }
}
```

### @Environment - Shared Values

```swift
// System environment values (key path syntax)
struct ThemeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text(colorScheme == .dark ? "Dark Mode" : "Light Mode")
        Button("Dismiss") { dismiss() }
    }
}

// SwiftData model context
struct AddExerciseView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        Button("Add") {
            context.insert(Exercise(displayName: "Squat"))
        }
    }
}

// Injecting and reading an @Observable type (iOS 17+)
// Inject with .environment(object) — no EnvironmentKey needed
struct RootView: View {
    @State private var appModel = AppModel()

    var body: some View {
        ContentView().environment(appModel)
    }
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel  // Type-based lookup

    var body: some View { Text(appModel.username) }
}
```

### @Query - SwiftData Fetch (iOS 17+)

```swift
struct ExerciseListView: View {
    // Fetches all Exercise models, sorted by displayName, live-updating
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    // Filtered + sorted query
    @Query(
        filter: #Predicate<WorkoutSession> { $0.cycleId != nil },
        sort: \WorkoutSession.date,
        order: .reverse
    )
    private var cycleSessions: [WorkoutSession]

    @Environment(\.modelContext) private var context

    var body: some View {
        List(exercises) { ex in Text(ex.displayName) }
    }
}
```

### Custom Property Wrapper

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct SettingsView: View {
    @UserDefault(key: "username", defaultValue: "Guest")
    var username: String
    
    var body: some View {
        TextField("Username", text: $username)
    }
}
```

## Best Practices Summary

1. **Prefer @Observable over ObservableObject** — No @Published boilerplate, iOS 17+
2. **Use @State to own @Observable objects** — `@State private var vm = MyViewModel()`
3. **Use @Bindable for two-way binding to @Observable** — Replaces @ObservedObject pattern
4. **Inject @Observable via .environment(object)** — Read with `@Environment(Type.self)`
5. **Use @Query for SwiftData** — Automatic live updates, supports sort/filter/limit
6. **Use @Binding to share value state** — Pass `$property` to child views
7. **Keep @State minimal** — Only store what's needed for UI
8. **Access on main thread** — All property wrappers require @MainActor
9. **Use underscore for custom init** — `_property = State(initialValue:)`
10. **Use @Environment for system values** — colorScheme, dismiss, locale, modelContext

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Using @StateObject with @Observable | Use `@State` instead |
| Using @ObservedObject with @Observable | Use `@Bindable` instead |
| Using @EnvironmentObject with @Observable | Use `@Environment(Type.self)` instead |
| Initializing @State directly in init | Use `_count = State(initialValue:)` |
| Creating @ObservedObject in view init | Use @StateObject (legacy) or @State + @Observable |
| Mutating @State on background thread | Use @MainActor or dispatch to main |
| Passing @State down instead of Binding | Use `$property` to get Binding |
| Not marking ObservableObject with @Published | Add @Published (legacy) or migrate to @Observable |
| Missing modelContainer for @Query | Add `.modelContainer(for:)` to App or root view |

## When to Use Which (iOS 17+)

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
            └── NO → Use @EnvironmentObject (legacy)
```
