//
//  OnboardingExercisesView.swift
//  Unit
//
//  Screen 5 — Add exercises per training day.
//  Search or type to add. Minimum 1 exercise per day.
//

import SwiftUI

struct OnboardingExercisesView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onContinue: () -> Void

    @State private var selectedDayIndex: Int = 0
    @State private var showingAddSheet: Bool = false

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Add exercises",
            ctaLabel: "Continue",
            ctaEnabled: vm.exercisesAreValid,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {

                // Day tab strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
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
                let dayExs = vm.dayExercises[selectedDayIndex]

                if dayExs.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: AtlasTheme.Spacing.xs) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 28))
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            Text("No exercises yet")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, AtlasTheme.Spacing.xl)
                        Spacer()
                    }
                } else {
                    VStack(spacing: AtlasTheme.Spacing.xxs) {
                        ForEach(dayExs) { ex in
                            HStack {
                                Text(ex.name)
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                Spacer()
                                Button {
                                    vm.dayExercises[selectedDayIndex].removeAll { $0.id == ex.id }
                                    vm.baselines.removeValue(forKey: ex.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                        .padding(8)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal, AtlasTheme.Spacing.md)
                            .frame(height: 48)
                            .background(AtlasTheme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                        }
                    }
                }

                // Add exercise button
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add exercise")
                            .font(AtlasTheme.Typography.body)
                    }
                    .foregroundStyle(AtlasTheme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AtlasTheme.Colors.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
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
                    .font(.system(.footnote, design: .rounded).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AtlasTheme.Colors.textPrimary : AtlasTheme.Colors.textSecondary)
                if hasWarning {
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
            AtlasTheme.Colors.elevatedBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    TextField("Search or type exercise name", text: $query)
                        .focused($isSearchFocused)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                        .submitLabel(.done)
                        .onSubmit {
                            let trimmed = query.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { addExercise(name: trimmed) }
                        }
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(AtlasTheme.Spacing.sm)
                .background(AtlasTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                .padding(AtlasTheme.Spacing.md)

                Divider()
                    .background(AtlasTheme.Colors.border)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Custom entry option
                        if showCustomOption {
                            let trimmed = query.trimmingCharacters(in: .whitespaces)
                            Button {
                                addExercise(name: trimmed)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AtlasTheme.Colors.accent)
                                    Text("Add \"\(trimmed)\"")
                                        .font(AtlasTheme.Typography.body)
                                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                }
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .frame(height: 48)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .background(AtlasTheme.Colors.border)
                        }

                        // Library suggestions
                        ForEach(filteredSuggestions, id: \.self) { name in
                            Button {
                                addExercise(name: name)
                            } label: {
                                Text(name)
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, AtlasTheme.Spacing.md)
                                    .frame(height: 48)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .background(AtlasTheme.Colors.border)
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
        OnboardingExercisesView { }
            .environment({
                let vm = OnboardingViewModel()
                vm.seedSampleData()
                return vm
            }())
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
