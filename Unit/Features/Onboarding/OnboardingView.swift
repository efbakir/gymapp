//
//  OnboardingView.swift
//  Unit
//
//  Root coordinator for the onboarding flow. Uses NavigationStack so the
//  user can navigate back at any point without losing their data.
//

import SwiftUI
import SwiftData

// MARK: - Route

enum OnboardingRoute: Hashable {
    case path
    case units
    case splitBuilder
    case exercises
    case baselines
    case progression
    case cycleStart
    case signIn
}

// MARK: - Root View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("unitSystem") private var storedUnitSystem: String = "kg"

    @State private var vm = OnboardingViewModel()
    @State private var path = NavigationPath()
    @State private var commitError: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingSplashView {
                path.append(OnboardingRoute.path)
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                destinationView(route)
            }
        }
        .tint(AtlasTheme.Colors.accent)
        .environment(vm)
        .alert("Something went wrong", isPresented: $commitError) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text("Could not save your cycle. Please try again.")
        }
    }

    // MARK: - Route → View

    @ViewBuilder
    private func destinationView(_ route: OnboardingRoute) -> some View {
        switch route {
        case .path:
            OnboardingPathView { selectedPath in
                vm.setupPath = selectedPath
                if selectedPath == .sample { vm.seedSampleData() }
                path.append(OnboardingRoute.units)
            }

        case .units:
            OnboardingUnitsView {
                path.append(nextRoute(after: .units))
            }

        case .splitBuilder:
            OnboardingSplitBuilderView {
                path.append(OnboardingRoute.exercises)
            }

        case .exercises:
            OnboardingExercisesView {
                path.append(OnboardingRoute.baselines)
            }

        case .baselines:
            OnboardingBaselinesView {
                path.append(nextRoute(after: .baselines))
            }

        case .progression:
            OnboardingProgressionView {
                path.append(OnboardingRoute.cycleStart)
            }

        case .cycleStart:
            OnboardingCycleStartView {
                commitCycle()
            }

        case .signIn:
            OnboardingSignInView {
                finishOnboarding()
            }
        }
    }

    // MARK: - Path Logic

    private func nextRoute(after route: OnboardingRoute) -> OnboardingRoute {
        switch (route, vm.setupPath) {
        case (.units, .build):      return .splitBuilder
        case (.units, .sample):     return .baselines
        case (.baselines, .build):  return .progression
        case (.baselines, .sample): return .cycleStart
        default:                    return .signIn
        }
    }

    // MARK: - Commit

    private func commitCycle() {
        do {
            try vm.commit(modelContext: modelContext)
            storedUnitSystem = vm.unitSystem
            path.append(OnboardingRoute.signIn)
        } catch {
            commitError = true
        }
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}
