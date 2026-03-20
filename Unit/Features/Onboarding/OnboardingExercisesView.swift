//
//  OnboardingExercisesView.swift
//  Unit
//
//  Screen 5 — Add exercises per training day.
//  Search or type to add. Minimum 1 exercise per day.
//

import SwiftUI
import UniformTypeIdentifiers

struct OnboardingExercisesView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void

    @State private var selectedDayIndex: Int = 0
    @State private var showingAddSheet: Bool = false
    @FocusState private var focusedExerciseID: UUID?
    @State private var draggedExerciseID: UUID?

    private func exerciseNameBinding(dayIndex: Int, exerciseIndex: Int) -> Binding<String> {
        Binding(
            get: {
                guard vm.dayExercises.indices.contains(dayIndex),
                      vm.dayExercises[dayIndex].indices.contains(exerciseIndex) else {
                    return ""
                }
                return vm.dayExercises[dayIndex][exerciseIndex].name
            },
            set: { newValue in
                guard vm.dayExercises.indices.contains(dayIndex),
                      vm.dayExercises[dayIndex].indices.contains(exerciseIndex) else {
                    return
                }
                vm.dayExercises[dayIndex][exerciseIndex].name = newValue
            }
        )
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Add exercises",
            ctaLabel: "Continue",
            ctaEnabled: vm.exercisesAreValid,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {

                // Day tab strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<vm.dayCount, id: \.self) { i in
                            DayTab(
                                name: vm.dayNames[i],
                                isSelected: selectedDayIndex == i,
                                hasWarning: vm.dayExercises[i].isEmpty
                            ) {
                                selectedDayIndex = i
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }

                // Exercise list for selected day
                let dayExs = vm.dayExercises.indices.contains(selectedDayIndex) ? vm.dayExercises[selectedDayIndex] : []

                if dayExs.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: AppSpacing.sm) {
                            AppIcon.dumbbell.image(size: 28, weight: .semibold)
                                .foregroundStyle(AppColor.textSecondary)
                            Text("No exercises yet")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(.vertical, AppSpacing.xl)
                        Spacer()
                    }
                } else {
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(Array(dayExs.enumerated()), id: \.element.id) { exerciseIndex, ex in
                            HStack {
                                AppIcon.reorder.image(size: 14, weight: .semibold)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .frame(width: 20, height: 20)
                                    .onDrag {
                                        draggedExerciseID = ex.id
                                        return NSItemProvider(object: ex.id.uuidString as NSString)
                                    }

                                TextField("Exercise name", text: exerciseNameBinding(dayIndex: selectedDayIndex, exerciseIndex: exerciseIndex))
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .focused($focusedExerciseID, equals: ex.id)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                Spacer()
                                Button {
                                    vm.dayExercises[selectedDayIndex].removeAll { $0.id == ex.id }
                                    vm.baselines.removeValue(forKey: ex.id)
                                    if focusedExerciseID == ex.id {
                                        focusedExerciseID = nil
                                    }
                                } label: {
                                    AppIcon.close.image(size: 12, weight: .semibold)
                                        .foregroundStyle(AppColor.textSecondary)
                                        .padding(8)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .frame(height: 48)
                            .background(AppColor.cardBackground)
                            .contentShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .stroke(focusedExerciseID == ex.id ? AppColor.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                            .onTapGesture {
                                focusedExerciseID = ex.id
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: ExerciseReorderDropDelegate(
                                    targetExerciseID: ex.id,
                                    exercises: $vm.dayExercises[selectedDayIndex],
                                    draggedExerciseID: $draggedExerciseID
                                )
                            )
                        }
                    }
                }

                // Add exercise button
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        AppIcon.add.image(size: 14, weight: .semibold)
                        Text("Add exercise")
                            .font(AppFont.body.font)
                    }
                    .foregroundStyle(AppColor.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColor.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ExerciseSearchSheet(dayIndex: selectedDayIndex)
                .environment(vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedDayIndex) { _, _ in
            focusedExerciseID = nil
            draggedExerciseID = nil
        }
        .onChange(of: vm.dayCount) { _, newValue in
            if selectedDayIndex >= newValue {
                selectedDayIndex = max(0, newValue - 1)
            }
            focusedExerciseID = nil
            draggedExerciseID = nil
        }
    }
}

private struct ExerciseReorderDropDelegate: DropDelegate {
    let targetExerciseID: UUID
    @Binding var exercises: [OnboardingExercise]
    @Binding var draggedExerciseID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedExerciseID,
              draggedExerciseID != targetExerciseID,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggedExerciseID }),
              let toIndex = exercises.firstIndex(where: { $0.id == targetExerciseID }) else {
            return
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            let movedExercise = exercises.remove(at: fromIndex)
            exercises.insert(movedExercise, at: toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedExerciseID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Day Tab

private struct DayTab: View {
    let name: String
    let isSelected: Bool
    let hasWarning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(name)
                    .font(isSelected ? AppFont.captionBold.font : AppFont.caption.font)
                    .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                if hasWarning {
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

// MARK: - Exercise Search Sheet

struct ExerciseSearchSheet: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let dayIndex: Int

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredSuggestions: [String] {
        let existing = vm.dayExercises[dayIndex].map { $0.name.lowercased() }
        return ExerciseLibrary.filtered(by: query).filter { !existing.contains($0.lowercased()) }
    }

    private var showCustomOption: Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return false }
        return !ExerciseLibrary.suggestions.contains(where: { $0.lowercased() == q.lowercased() })
            && !vm.dayExercises[dayIndex].contains(where: { $0.name.lowercased() == q.lowercased() })
    }

    var body: some View {
        ZStack {
            AppColor.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AppSpacing.sm) {
                    AppIcon.search.image()
                        .foregroundStyle(AppColor.textSecondary)
                    TextField("Search or type exercise name", text: $query)
                        .focused($isSearchFocused)
                        .foregroundStyle(AppColor.textPrimary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            let trimmed = query.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { addExercise(name: trimmed) }
                        }
                    if !query.isEmpty {
                        Button { query = "" } label: {
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
                        // Custom entry option
                        if showCustomOption {
                            let trimmed = query.trimmingCharacters(in: .whitespaces)
                            Button {
                                addExercise(name: trimmed)
                            } label: {
                                HStack {
                                    AppIcon.addCircle.image()
                                        .foregroundStyle(AppColor.accent)
                                    Text("Add \"\(trimmed)\"")
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

                        // Library suggestions
                        ForEach(filteredSuggestions, id: \.self) { name in
                            Button {
                                addExercise(name: name)
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
        .onAppear { isSearchFocused = true }
    }

    private func addExercise(name: String) {
        let ex = OnboardingExercise(name: name)
        vm.dayExercises[dayIndex].append(ex)
        query = ""
        dismiss()
    }
}

#Preview {
    NavigationStack {
        OnboardingExercisesView(progressStep: 3, progressTotal: 6) { }
            .environment({
                let vm = OnboardingViewModel()
                vm.seedSampleData()
                return vm
            }())
    }
    .tint(AppColor.accent)
}
