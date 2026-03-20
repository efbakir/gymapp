//
//  OnboardingView.swift
//  Unit
//
//  Root coordinator for the onboarding flow. Uses NavigationStack so the
//  user can navigate back at any point without losing their data.
//

import SwiftUI
import SwiftData

enum OnboardingPreferencesKeys {
    static let dayCount = "onboarding.dayCount"
    static let dayNames = "onboarding.dayNames"
    static let compoundIncrementKg = "onboarding.compoundIncrementKg"
    static let isolationIncrementKg = "onboarding.isolationIncrementKg"
    static let globalIncrementKg = compoundIncrementKg
    static let startOption = "onboarding.startOption"
    static let customStartDate = "onboarding.customStartDate"
}

enum OnboardingPreferences {
    static func save(from viewModel: OnboardingViewModel, defaults: UserDefaults = .standard) {
        defaults.set(viewModel.dayCount, forKey: OnboardingPreferencesKeys.dayCount)
        defaults.set(viewModel.dayNames, forKey: OnboardingPreferencesKeys.dayNames)
        defaults.set(viewModel.compoundIncrementKg, forKey: OnboardingPreferencesKeys.compoundIncrementKg)
        defaults.set(viewModel.isolationIncrementKg, forKey: OnboardingPreferencesKeys.isolationIncrementKg)
        defaults.set(rawStartOption(from: viewModel.startOption), forKey: OnboardingPreferencesKeys.startOption)
        defaults.set(viewModel.customDate.timeIntervalSince1970, forKey: OnboardingPreferencesKeys.customStartDate)
    }

    static func load(into viewModel: OnboardingViewModel, defaults: UserDefaults = .standard) {
        let storedDayCount = defaults.integer(forKey: OnboardingPreferencesKeys.dayCount)
        if storedDayCount > 0 {
            viewModel.updateDayCount(storedDayCount)
        }

        if let names = defaults.stringArray(forKey: OnboardingPreferencesKeys.dayNames), !names.isEmpty {
            viewModel.updateDayCount(max(2, min(6, names.count)))
            for index in viewModel.dayNames.indices {
                if index < names.count {
                    viewModel.dayNames[index] = names[index]
                }
            }
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.compoundIncrementKg) != nil {
            viewModel.compoundIncrementKg = defaults.double(forKey: OnboardingPreferencesKeys.compoundIncrementKg)
        } else if defaults.object(forKey: OnboardingPreferencesKeys.globalIncrementKg) != nil {
            viewModel.compoundIncrementKg = defaults.double(forKey: OnboardingPreferencesKeys.globalIncrementKg)
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.isolationIncrementKg) != nil {
            viewModel.isolationIncrementKg = defaults.double(forKey: OnboardingPreferencesKeys.isolationIncrementKg)
        }

        if let rawOption = defaults.string(forKey: OnboardingPreferencesKeys.startOption) {
            viewModel.startOption = startOption(from: rawOption)
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.customStartDate) != nil {
            let timestamp = defaults.double(forKey: OnboardingPreferencesKeys.customStartDate)
            viewModel.customDate = Date(timeIntervalSince1970: timestamp)
        }
    }

    private static func rawStartOption(from option: OnboardingViewModel.StartOption) -> String {
        switch option {
        case .today:
            return "today"
        case .nextMonday:
            return "nextMonday"
        case .custom:
            return "custom"
        }
    }

    private static func startOption(from rawValue: String) -> OnboardingViewModel.StartOption {
        switch rawValue {
        case "nextMonday":
            return .nextMonday
        case "custom":
            return .custom
        default:
            return .today
        }
    }
}

// MARK: - Route

enum OnboardingRoute: Hashable {
    case path
    case importMethod
    case programImport
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
    @State private var didLoadPreferences = false

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingSplashView {
                path.append(OnboardingRoute.path)
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                destinationView(route)
            }
        }
        .tint(AppColor.accent)
        .environment(vm)
        .alert("Something went wrong", isPresented: $commitError) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text("Could not save your cycle. Please try again.")
        }
        .onAppear {
            guard !didLoadPreferences else { return }
            vm.unitSystem = storedUnitSystem
            OnboardingPreferences.load(into: vm)
            didLoadPreferences = true
        }
    }

    // MARK: - Route → View

    @ViewBuilder
    private func destinationView(_ route: OnboardingRoute) -> some View {
        switch route {
        case .path:
            OnboardingPathView(progressStep: 1, progressTotal: totalRequiredSteps) {
                vm.setupPath = .build
                path.append(OnboardingRoute.importMethod)
            }

        case .importMethod:
            OnboardingImportMethodView(progressStep: 2, progressTotal: totalRequiredSteps) { method in
                vm.importMethod = method
                path.append(nextRoute(after: OnboardingRoute.importMethod))
            }

        case .programImport:
            OnboardingProgramImportView(
                progressStep: 3,
                progressTotal: totalRequiredSteps
            ) {
                path.append(OnboardingRoute.baselines)
            }

        case .splitBuilder:
            OnboardingSplitBuilderView(progressStep: 3, progressTotal: totalRequiredSteps) {
                path.append(OnboardingRoute.exercises)
            }

        case .exercises:
            OnboardingExercisesView(progressStep: 4, progressTotal: totalRequiredSteps) {
                path.append(OnboardingRoute.baselines)
            }

        case .baselines:
            OnboardingBaselinesView(progressStep: vm.importMethod == .manual ? 5 : 4, progressTotal: totalRequiredSteps) {
                path.append(nextRoute(after: .baselines))
            }

        case .progression:
            OnboardingProgressionView(progressStep: vm.importMethod == .manual ? 6 : 5, progressTotal: totalRequiredSteps) {
                path.append(OnboardingRoute.cycleStart)
            }

        case .cycleStart:
            OnboardingCycleStartView(
                progressStep: vm.importMethod == .manual ? 7 : 6,
                progressTotal: totalRequiredSteps
            ) {
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
        switch route {
        case .importMethod:
            return vm.importMethod == .manual ? .splitBuilder : .programImport
        case .baselines:
            return .progression
        default:
            return .signIn
        }
    }

    private var totalRequiredSteps: Int {
        vm.importMethod == .manual ? 7 : 6
    }

    // MARK: - Commit

    private func commitCycle() {
        do {
            try vm.commit(modelContext: modelContext)
            storedUnitSystem = vm.unitSystem
            OnboardingPreferences.save(from: vm)
            path.append(OnboardingRoute.signIn)
        } catch {
            commitError = true
        }
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}
