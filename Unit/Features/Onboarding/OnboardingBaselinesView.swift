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
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void

    @State private var selectedDayIndex: Int = 0
    @State private var replacementTarget: ExerciseReplacementTarget?

    private var ctaLabel: String {
        guard vm.dayNames.indices.contains(selectedDayIndex) else { return "Continue" }
        if selectedDayIndex < vm.dayCount - 1 {
            return "Next — \(vm.dayNames[selectedDayIndex + 1])"
        }
        return "These look right"
    }

    private var ctaEnabled: Bool {
        vm.baselineIsValid(forDay: selectedDayIndex)
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Week 1 starting point",
            ctaLabel: ctaLabel,
            ctaEnabled: ctaEnabled,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: handleContinue
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {

                Text("Enter what you can currently do — not your max.")
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)

                // Day tab strip (only if > 1 day)
                if vm.dayCount > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
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
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    // Header
                    HStack(alignment: .bottom) {
                        Text("Exercise")
                            .font(AppFont.overline)
                            .foregroundStyle(AppColor.textSecondary)
                            .tracking(1.0)

                        Spacer()

                        VStack(alignment: .center, spacing: 6) {
                            Text("Weight")
                                .font(AppFont.overline)
                                .foregroundStyle(AppColor.textSecondary)
                                .tracking(1.0)

                            Picker("Weight Unit", selection: $vm.unitSystem) {
                                Text("kg").tag("kg")
                                Text("lb").tag("lb")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 104)
                        }

                        Text("Reps")
                            .font(AppFont.overline)
                            .foregroundStyle(AppColor.textSecondary)
                            .tracking(1.0)
                            .frame(width: 52, alignment: .center)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    VStack(spacing: AppSpacing.xs) {
                        ForEach(dayExs) { ex in
                            BaselineRow(
                                exercise: ex,
                                onReplace: {
                                    replacementTarget = ExerciseReplacementTarget(dayIndex: selectedDayIndex, exerciseID: ex.id)
                                }
                            )
                        }
                    }
                }
            }
        }
        .environment(vm)
        .sheet(item: $replacementTarget) { target in
            ExerciseReplacementSheet(target: target)
                .environment(vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func handleContinue() {
        if selectedDayIndex < vm.dayCount - 1 {
            selectedDayIndex += 1
        } else {
            onContinue()
        }
    }
}

// MARK: - Baseline Row

private struct BaselineRow: View {
    @Environment(OnboardingViewModel.self) private var vm
    let exercise: OnboardingExercise
    let onReplace: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    private var isBodyweight: Bool {
        vm.isBodyweightExercise(named: exercise.name)
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Text(exercise.name)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Button(action: onReplace) {
                    AppIcon.swap.image(size: 12, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppColor.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Weight field
            HStack(spacing: 3) {
                if isBodyweight {
                    Text("BW")
                        .font(AppFont.label.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(AppFont.label.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .focused($weightFocused)
                        .submitLabel(.next)
                        .onSubmit {
                            weightFocused = false
                            repsFocused = true
                        }
                        .frame(width: 52)
                        .onChange(of: weightText) { _, new in
                            let val = Double(new.replacingOccurrences(of: ",", with: ".")) ?? 0
                            let kg = vm.storeWeightKg(val)
                            var b = vm.baselines[exercise.id] ?? OnboardingBaseline()
                            b.weightKg = kg
                            vm.baselines[exercise.id] = b
                        }
                    Text(vm.weightUnitLabel)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .frame(width: 72, alignment: .trailing)

            // Reps field
            TextField("8", text: $repsText)
                .keyboardType(.numberPad)
                .font(AppFont.label.font)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .focused($repsFocused)
                .submitLabel(.done)
                .onSubmit {
                    repsFocused = false
                }
                .frame(width: 52)
                .onChange(of: repsText) { _, new in
                    let val = Int(new) ?? 0
                    var b = vm.baselines[exercise.id] ?? OnboardingBaseline()
                    b.reps = val
                    vm.baselines[exercise.id] = b
                }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(minHeight: 52)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if weightFocused && !isBodyweight {
                    Button("Next") {
                        weightFocused = false
                        repsFocused = true
                    }
                } else if repsFocused {
                    Button("Done") {
                        repsFocused = false
                    }
                }
            }
        }
        .onAppear {
            syncFieldsFromBaseline()
        }
        .onChange(of: vm.unitSystem) { _, _ in
            syncFieldsFromBaseline()
        }
        .onChange(of: vm.baselines[exercise.id]?.weightKg) { _, _ in
            syncFieldsFromBaseline()
        }
        .onChange(of: vm.baselines[exercise.id]?.reps) { _, _ in
            syncFieldsFromBaseline()
        }
    }

    private func syncFieldsFromBaseline() {
        let b = vm.baselines[exercise.id]
        if isBodyweight {
            weightText = ""
        } else if let b {
            let display = vm.displayWeight(b.weightKg)
            weightText = display == 0 ? "" : display.weightString
        } else {
            weightText = ""
        }

        if let b {
            repsText = b.reps > 0 ? "\(b.reps)" : ""
        } else {
            repsText = ""
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
                    .font(isSelected ? AppFont.captionBold.font : AppFont.caption.font)
                    .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                if isIncomplete {
                    Circle()
                        .fill(AppColor.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColor.cardBackground : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseReplacementTarget: Identifiable {
    let dayIndex: Int
    let exerciseID: UUID

    var id: String {
        "\(dayIndex)-\(exerciseID.uuidString)"
    }
}

private struct ExerciseReplacementSheet: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    let target: ExerciseReplacementTarget

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    private var targetIndex: Int? {
        guard vm.dayExercises.indices.contains(target.dayIndex) else { return nil }
        return vm.dayExercises[target.dayIndex].firstIndex(where: { $0.id == target.exerciseID })
    }

    private var currentName: String {
        guard let targetIndex else { return "" }
        return vm.dayExercises[target.dayIndex][targetIndex].name
    }

    private var filteredSuggestions: [String] {
        guard vm.dayExercises.indices.contains(target.dayIndex) else { return [] }
        let existing = vm.dayExercises[target.dayIndex]
            .filter { $0.id != target.exerciseID }
            .map { $0.name.lowercased() }
        return ExerciseLibrary.filtered(by: query)
            .filter { !existing.contains($0.lowercased()) }
    }

    private var showCustomOption: Bool {
        guard vm.dayExercises.indices.contains(target.dayIndex) else { return false }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let alreadySuggested = ExerciseLibrary.suggestions.contains { $0.lowercased() == trimmed.lowercased() }
        let duplicateInDay = vm.dayExercises[target.dayIndex]
            .contains { $0.id != target.exerciseID && $0.name.lowercased() == trimmed.lowercased() }
        return !alreadySuggested && !duplicateInDay
    }

    var body: some View {
        ZStack {
            AppColor.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: AppSpacing.sm) {
                    AppIcon.search.image()
                        .foregroundStyle(AppColor.textSecondary)
                    TextField("Replace \(currentName)", text: $query)
                        .focused($isSearchFocused)
                        .foregroundStyle(AppColor.textPrimary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                replaceExercise(with: trimmed)
                            }
                        }
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            AppIcon.xmarkFilled.image()
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .padding(AppSpacing.md)

                AppDivider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if showCustomOption {
                            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                            Button {
                                replaceExercise(with: trimmed)
                            } label: {
                                HStack {
                                    AppIcon.swap.image()
                                        .foregroundStyle(AppColor.accent)
                                    Text("Swap to \"\(trimmed)\"")
                                        .font(AppFont.body.font)
                                        .foregroundStyle(AppColor.textPrimary)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .frame(height: 48)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            AppDivider()
                                .padding(.horizontal, AppSpacing.md)
                        }

                        ForEach(filteredSuggestions, id: \.self) { name in
                            Button {
                                replaceExercise(with: name)
                            } label: {
                                Text(name)
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, AppSpacing.md)
                                    .frame(height: 48)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            AppDivider()
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func replaceExercise(with newName: String) {
        guard let targetIndex,
              vm.dayExercises.indices.contains(target.dayIndex) else {
            return
        }

        vm.dayExercises[target.dayIndex][targetIndex].name = newName

        if vm.isBodyweightExercise(named: newName) {
            var baseline = vm.baselines[target.exerciseID] ?? OnboardingBaseline()
            baseline.weightKg = 0
            vm.baselines[target.exerciseID] = baseline
        }

        dismiss()
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
        OnboardingBaselinesView(progressStep: 4, progressTotal: 6) { }
            .environment({
                let vm = OnboardingViewModel()
                vm.seedSampleData()
                return vm
            }())
    }
    .tint(AppColor.accent)
}
