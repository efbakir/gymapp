//
//  SettingsView.swift
//  Unit
//
//  Settings tab with onboarding preferences.
//

import SwiftUI

struct SettingsView: View {
    private let shouldShowCloseButton: Bool

    @AppStorage("unitSystem") private var unitSystem: String = "kg"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(OnboardingPreferencesKeys.dayCount) private var onboardingDayCount = 3
    @AppStorage(OnboardingPreferencesKeys.compoundIncrementKg) private var onboardingCompoundIncrementKg = 2.5
    @AppStorage(OnboardingPreferencesKeys.isolationIncrementKg) private var onboardingIsolationIncrementKg = 1.25
    @AppStorage(OnboardingPreferencesKeys.startOption) private var onboardingStartOption = "today"
    @AppStorage(OnboardingPreferencesKeys.customStartDate) private var onboardingCustomStartDate = Date().timeIntervalSince1970
    @State private var onboardingDayNames: [String] = []
    @Environment(\.dismiss) private var dismiss

    init(showsCloseButton: Bool = true) {
        self.shouldShowCloseButton = showsCloseButton
    }

    private func incrementDisplayValue(_ incrementKg: Double) -> Double {
        unitSystem == "lb" ? incrementKg * 2.20462 : incrementKg
    }

    private var incrementStepKg: Double {
        unitSystem == "lb" ? 2.5 / 2.20462 : 1.25
    }

    private var incrementUnitLabel: String {
        unitSystem == "lb" ? "lb" : "kg"
    }

    private var customStartDateBinding: Binding<Date> {
        Binding<Date>(
            get: { Date(timeIntervalSince1970: onboardingCustomStartDate) },
            set: { onboardingCustomStartDate = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        NavigationStack {
            AppScreen(
                title: "Settings",
                leadingAction: shouldShowCloseButton ? NavAction(icon: .back, action: { dismiss() }) : nil
            ) {
                SettingsSection(title: "Onboarding Questions") {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Weight unit")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            Picker("Weight Unit", selection: $unitSystem) {
                                Text("kg").tag("kg")
                                Text("lb").tag("lb")
                            }
                            .pickerStyle(.segmented)
                            .frame(minHeight: 44)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Days per week")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            AppStepper(value: "\(onboardingDayCount)", onDecrement: {
                                onboardingDayCount = max(2, onboardingDayCount - 1)
                                syncDayNamesToDayCount()
                            }, onIncrement: {
                                onboardingDayCount = min(6, onboardingDayCount + 1)
                                syncDayNamesToDayCount()
                            })
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Day names")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            ForEach(Array(onboardingDayNames.enumerated()), id: \.offset) { index, _ in
                                TextField("Day \(index + 1)", text: dayNameBinding(for: index))
                                    .font(AppFont.body.font)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .frame(height: 44)
                                    .background(AppColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Compound increment")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            AppStepper(value: "\(incrementDisplayValue(onboardingCompoundIncrementKg).weightString) \(incrementUnitLabel)", onDecrement: {
                                onboardingCompoundIncrementKg = max(incrementStepKg, onboardingCompoundIncrementKg - incrementStepKg)
                            }, onIncrement: {
                                onboardingCompoundIncrementKg += incrementStepKg
                            })
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Isolation increment")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            AppStepper(value: "\(incrementDisplayValue(onboardingIsolationIncrementKg).weightString) \(incrementUnitLabel)", onDecrement: {
                                onboardingIsolationIncrementKg = max(0, onboardingIsolationIncrementKg - incrementStepKg)
                            }, onIncrement: {
                                onboardingIsolationIncrementKg += incrementStepKg
                            })
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Cycle start")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            Picker("Cycle Start", selection: $onboardingStartOption) {
                                Text("Today").tag("today")
                                Text("Next Mon").tag("nextMonday")
                                Text("Custom").tag("custom")
                            }
                            .pickerStyle(.segmented)
                            .frame(minHeight: 44)

                            if onboardingStartOption == "custom" {
                                DatePicker(
                                    "Custom Start Date",
                                    selection: customStartDateBinding,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .tint(AppColor.accent)
                                .frame(minHeight: 44)
                            }
                        }

                        AppPrimaryButton("Run Onboarding Again") {
                            hasCompletedOnboarding = false
                        }
                        .padding(.top, AppSpacing.sm)
                }
            }
            .tint(AppColor.accent)
            .onAppear {
                loadDayNames()
            }
        }
    }

    private func loadDayNames() {
        if let stored = UserDefaults.standard.stringArray(forKey: OnboardingPreferencesKeys.dayNames), !stored.isEmpty {
            onboardingDayNames = stored
        } else {
            onboardingDayNames = defaultDayNames(for: onboardingDayCount)
        }
        syncDayNamesToDayCount()
    }

    private func syncDayNamesToDayCount() {
        if onboardingDayNames.count > onboardingDayCount {
            onboardingDayNames = Array(onboardingDayNames.prefix(onboardingDayCount))
        } else if onboardingDayNames.count < onboardingDayCount {
            onboardingDayNames.append(contentsOf: defaultDayNames(for: onboardingDayCount).dropFirst(onboardingDayNames.count))
        }
        UserDefaults.standard.set(onboardingDayNames, forKey: OnboardingPreferencesKeys.dayNames)
    }

    private func defaultDayNames(for dayCount: Int) -> [String] {
        (1...max(2, min(6, dayCount))).map { "Day \($0)" }
    }

    private func dayNameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < onboardingDayNames.count else { return "" }
                return onboardingDayNames[index]
            },
            set: { newValue in
                guard index < onboardingDayNames.count else { return }
                onboardingDayNames[index] = newValue
                UserDefaults.standard.set(onboardingDayNames, forKey: OnboardingPreferencesKeys.dayNames)
            }
        )
    }
}

#Preview {
    SettingsView()
}
