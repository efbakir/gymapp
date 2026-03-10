//
//  OnboardingBaselinesView.swift
//  Unit
//
//  Screen 6 — Week 1 baselines: weight + reps per exercise.
//  Most critical onboarding screen — this is what the engine uses to compute
//  targets for week 1.
//

import SwiftUI

struct OnboardingBaselinesView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onContinue: () -> Void

    @State private var selectedDayIndex: Int = 0

    var body: some View {
        OnboardingShell(
            title: "Week 1 starting point",
            ctaLabel: vm.setupPath == .sample ? "These look right" : "Continue",
            ctaEnabled: vm.baselinesAreValid,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {

                Text("Enter what you can currently do — not your max.")
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)

                // Day tab strip (only if > 1 day)
                if vm.dayCount > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            ForEach(0..<vm.dayCount, id: \.self) { i in
                                BaselineDayTab(
                                    name: vm.dayNames[i],
                                    isSelected: selectedDayIndex == i,
                                    isIncomplete: vm.incompleteDayIndices.contains(i)
                                ) {
                                    selectedDayIndex = i
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // Exercise baseline rows
                let dayExs = vm.dayExercises[safe: selectedDayIndex] ?? []

                if dayExs.isEmpty {
                    Text("No exercises in this day.")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                } else {
                    // Header
                    HStack {
                        Text("Exercise")
                            .font(AtlasTheme.Typography.overline)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .tracking(1.0)
                        Spacer()
                        Text("Weight")
                            .font(AtlasTheme.Typography.overline)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .tracking(1.0)
                            .frame(width: 72, alignment: .center)
                        Text("Reps")
                            .font(AtlasTheme.Typography.overline)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .tracking(1.0)
                            .frame(width: 52, alignment: .center)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)

                    VStack(spacing: AtlasTheme.Spacing.xxs) {
                        ForEach(dayExs) { ex in
                            BaselineRow(exercise: ex)
                        }
                    }
                }
            }
        }
        .environment(vm)
    }
}

// MARK: - Baseline Row

private struct BaselineRow: View {
    @Environment(OnboardingViewModel.self) private var vm
    let exercise: OnboardingExercise

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    private var baseline: OnboardingBaseline {
        vm.baselines[exercise.id] ?? OnboardingBaseline()
    }

    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            Text(exercise.name)
                .font(AtlasTheme.Typography.body)
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Weight field
            HStack(spacing: 3) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .focused($weightFocused)
                    .frame(width: 52)
                    .onChange(of: weightText) { _, new in
                        let val = Double(new.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let kg = vm.storeWeightKg(val)
                        var b = vm.baselines[exercise.id] ?? OnboardingBaseline()
                        b.weightKg = kg
                        vm.baselines[exercise.id] = b
                    }
                Text(vm.weightUnitLabel)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
            .frame(width: 72, alignment: .trailing)

            // Reps field
            TextField("8", text: $repsText)
                .keyboardType(.numberPad)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .focused($repsFocused)
                .frame(width: 52)
                .onChange(of: repsText) { _, new in
                    let val = Int(new) ?? 0
                    var b = vm.baselines[exercise.id] ?? OnboardingBaseline()
                    b.reps = val
                    vm.baselines[exercise.id] = b
                }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .frame(minHeight: 52)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .onAppear {
            let b = vm.baselines[exercise.id]
            if let b {
                let display = vm.displayWeight(b.weightKg)
                weightText = display == 0 ? "" : display.weightString
                repsText = b.reps > 0 ? "\(b.reps)" : ""
            }
        }
    }
}

// MARK: - Baseline Day Tab

private struct BaselineDayTab: View {
    let name: String
    let isSelected: Bool
    let isIncomplete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(.footnote, design: .rounded).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AtlasTheme.Colors.textPrimary : AtlasTheme.Colors.textSecondary)
                if isIncomplete {
                    Circle()
                        .fill(AtlasTheme.Colors.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.sm)
            .padding(.vertical, AtlasTheme.Spacing.xs)
            .background(isSelected ? AtlasTheme.Colors.card : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        OnboardingBaselinesView { }
            .environment({
                let vm = OnboardingViewModel()
                vm.seedSampleData()
                return vm
            }())
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
