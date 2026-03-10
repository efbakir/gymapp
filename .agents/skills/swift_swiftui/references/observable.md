---
name: swift_swiftui_observable
description: @Observable macro, @Bindable, and migration from ObservableObject. Use this skill when users ask about iOS 17+ observation, @Observable, @Bindable, or migrating from ObservableObject.
license: Proprietary
compatibility: iOS 17+ / macOS 14+
metadata:
  version: "1.0"
  author: SwiftZilla
  website: https://swiftzilla.dev
---

# @Observable Macro — iOS 17+

The `@Observable` macro (SE-0395) is the modern replacement for `ObservableObject`. It provides fine-grained observation with less boilerplate and better performance.

## Overview

| | ObservableObject (iOS 14+) | @Observable (iOS 17+) |
|--|--|--|
| Conformance | `class Foo: ObservableObject` | `@Observable class Foo` |
| Property tracking | `@Published var x` on every property | Automatic — all stored properties tracked |
| View ownership | `@StateObject` | `@State` |
| View reference | `@ObservedObject` | `@Bindable` |
| Environment injection | `.environmentObject(obj)` | `.environment(obj)` |
| Environment read | `@EnvironmentObject var foo: Foo` | `@Environment(Foo.self) var foo` |
| Granularity | Per-object (any change re-renders) | Per-property (only changed properties trigger re-render) |

## @Observable

```swift
import Observation

@Observable
class CycleViewModel {
    var currentWeek = 1
    var isActive = false
    var sessionCount = 0

    // Computed properties are also observed
    var progress: Double { Double(currentWeek) / 8.0 }

    // Opt out of observation for a property
    @ObservationIgnored private var cache: [String: Any] = [:]

    func advance() {
        currentWeek = min(currentWeek + 1, 8)
        sessionCount += 1
    }
}
```

## @State — Owning an @Observable in a View

```swift
// ✅ Correct: @State owns the @Observable object
struct CycleView: View {
    @State private var vm = CycleViewModel()

    var body: some View {
        VStack {
            Text("Week \(vm.currentWeek)")
            ProgressView(value: vm.progress)
            Button("Advance") { vm.advance() }
        }
    }
}

// ❌ Wrong: Don't use @StateObject with @Observable
struct CycleView: View {
    @StateObject private var vm = CycleViewModel()  // Only for ObservableObject
}
```

## @Bindable — Two-Way Binding to @Observable

```swift
// ✅ Use @Bindable to get $binding syntax from @Observable
struct EditCycleView: View {
    @Bindable var vm: CycleViewModel  // Passed from parent

    var body: some View {
        Form {
            Toggle("Active", isOn: $vm.isActive)
            Stepper("Week \(vm.currentWeek)", value: $vm.currentWeek, in: 1...8)
        }
    }
}

// Parent passes the @Observable object directly
struct ParentView: View {
    @State private var vm = CycleViewModel()

    var body: some View {
        EditCycleView(vm: vm)
    }
}
```

## @Environment — Sharing @Observable App-Wide

```swift
// Inject — no EnvironmentKey or EnvironmentValues extension needed
@main
struct GymApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .modelContainer(for: [Cycle.self, WorkoutSession.self])
        }
    }
}

// Read — use type-based lookup (no key path)
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Text("User: \(appModel.username)")
    }
}

// ⚠️ Binding from @Environment @Observable requires @Bindable local
struct SettingsEditView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var model = appModel  // Local @Bindable for binding
        TextField("Username", text: $model.username)
    }
}
```

## Migration from ObservableObject

### Before (ObservableObject)

```swift
class WorkoutStore: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    @Published var isLoading = false

    func load() async {
        isLoading = true
        sessions = await fetchSessions()
        isLoading = false
    }
}

struct WorkoutListView: View {
    @StateObject private var store = WorkoutStore()

    var body: some View {
        List(store.sessions) { s in Text(s.name) }
    }
}

struct WorkoutDetailView: View {
    @ObservedObject var store: WorkoutStore

    var body: some View {
        ProgressView(value: store.isLoading ? 1 : 0)
    }
}
```

### After (@Observable)

```swift
@Observable
class WorkoutStore {
    var sessions: [WorkoutSession] = []  // No @Published needed
    var isLoading = false

    func load() async {
        isLoading = true
        sessions = await fetchSessions()
        isLoading = false
    }
}

struct WorkoutListView: View {
    @State private var store = WorkoutStore()  // @State, not @StateObject

    var body: some View {
        List(store.sessions) { s in Text(s.name) }
    }
}

struct WorkoutDetailView: View {
    var store: WorkoutStore  // Plain property — or @Bindable if you need $bindings

    var body: some View {
        ProgressView(value: store.isLoading ? 1 : 0)
    }
}
```

## Performance Notes

- `@Observable` uses **per-property** tracking — a view only re-renders when a property it *reads* changes
- `ObservableObject` triggers re-render on any `@Published` change — coarser granularity
- Prefer `@Observable` for complex models with many properties

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `@StateObject` with @Observable | Wrong wrapper for @Observable | Use `@State` |
| `@ObservedObject` with @Observable | Wrong wrapper for @Observable | Use `@Bindable` or plain property |
| `@EnvironmentObject` with @Observable | Wrong injection/read for @Observable | Use `.environment(obj)` + `@Environment(Type.self)` |
| Cannot get `$binding` from `@Environment` | @Environment doesn't expose Binding | Create local `@Bindable var x = envObject` first |
| `@ObservationIgnored` on computed property | Only valid on stored properties | Remove — computed properties aren't tracked anyway |
