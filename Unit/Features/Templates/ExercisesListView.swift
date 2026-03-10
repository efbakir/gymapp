//
//  ExercisesListView.swift
//  Unit
//
//  Exercise library with aliases and exercise-level progress review.
//

import Charts
import SwiftUI
import SwiftData

struct ExercisesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @State private var showingAddExercise = false
    @State private var query = ""

    private var filteredExercises: [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return exercises }
        let needle = trimmed.lowercased()
        return exercises.filter { exercise in
            if exercise.displayName.lowercased().contains(needle) {
                return true
            }
            return exercise.aliases.contains { $0.lowercased().contains(needle) }
        }
    }

    var body: some View {
        List {
            ForEach(filteredExercises, id: \.id) { exercise in
                NavigationLink(value: exercise) {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            Text(exercise.displayName)
                                .font(AtlasTheme.Typography.body)
                            if exercise.isBodyweight {
                                Text("BW")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            }
                        }
                        if !exercise.aliases.isEmpty {
                            Text(exercise.aliases.joined(separator: " • "))
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        }
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            .onDelete(perform: deleteExercises)
            .listRowBackground(AtlasTheme.Colors.card)
        }
        .scrollContentBackground(.hidden)
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Exercises")
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .searchable(text: $query, prompt: "Search by name or alias")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add exercise")
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView()
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredExercises[index])
        }
        try? modelContext.save()
    }
}

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var aliasesText = ""
    @State private var isBodyweight = false

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                    TextField("Aliases (comma separated)", text: $aliasesText)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                }
                Section("Options") {
                    Toggle("Bodyweight", isOn: $isBodyweight)
                        .frame(minHeight: 44)
                }
                .listRowBackground(AtlasTheme.Colors.card)
            }
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let aliases = aliasesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let exercise = Exercise(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            aliases: aliases,
            isBodyweight: isBodyweight
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}

private struct ExerciseSessionSummary: Identifiable {
    let id: UUID
    let sessionDate: Date
    let templateName: String
    let topSetText: String
    let estimatedOneRM: Double
    let totalVolume: Double
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    private var summaries: [ExerciseSessionSummary] {
        sessions.compactMap { session in
            let entries = session.setEntries
                .filter { $0.exerciseId == exercise.id && $0.isCompleted }
                .sorted { $0.setIndex < $1.setIndex }

            guard !entries.isEmpty else { return nil }

            let oneRMs = entries.map { estimateOneRM(weight: $0.weight, reps: $0.reps) }
            let topOneRM = oneRMs.max() ?? 0
            let totalVolume = entries.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            let topSet = entries.max { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.reps < rhs.reps
                }
                return lhs.weight < rhs.weight
            }

            return ExerciseSessionSummary(
                id: session.id,
                sessionDate: session.date,
                templateName: templateName(for: session.templateId),
                topSetText: topSet.map { "\(formatWeight($0.weight)) kg × \($0.reps)" } ?? "-",
                estimatedOneRM: topOneRM,
                totalVolume: totalVolume
            )
        }
    }

    private var trendAscending: [ExerciseSessionSummary] {
        summaries.sorted { $0.sessionDate < $1.sessionDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                    Text(exercise.displayName)
                        .font(AtlasTheme.Typography.hero)
                    Text("Brzycki 1RM and session volume")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
                .atlasCardStyle()

                if summaries.isEmpty {
                    Text("No logged sessions yet.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .atlasCardStyle()
                } else {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Estimated 1RM Trend")
                            .font(AtlasTheme.Typography.sectionTitle)
                        Chart(trendAscending) { item in
                            LineMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AtlasTheme.Colors.accent)
                            PointMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AtlasTheme.Colors.accent)
                        }
                        .frame(height: 180)
                    }
                    .atlasCardStyle()

                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Session Volume")
                            .font(AtlasTheme.Typography.sectionTitle)
                        Chart(trendAscending) { item in
                            BarMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("Volume", item.totalVolume)
                            )
                            .foregroundStyle(AtlasTheme.Colors.accentSoft)
                        }
                        .frame(height: 160)
                    }
                    .atlasCardStyle()

                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Past Sessions")
                            .font(AtlasTheme.Typography.sectionTitle)

                        ForEach(summaries) { summary in
                            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                                HStack {
                                    Text(summary.templateName)
                                        .font(AtlasTheme.Typography.body)
                                    Spacer(minLength: 0)
                                    Text(summary.sessionDate, style: .date)
                                        .font(AtlasTheme.Typography.caption)
                                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                }
                                Text("Top set: \(summary.topSetText)")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                Text("Est. 1RM: \(formatWeight(summary.estimatedOneRM)) kg • Volume: \(Int(summary.totalVolume))")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AtlasTheme.Spacing.xs)

                            if summary.id != summaries.last?.id {
                                Divider()
                            }
                        }
                    }
                    .atlasCardStyle()
                }
            }
            .padding(AtlasTheme.Spacing.md)
        }
        .background(AtlasTheme.Colors.background)
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func templateName(for templateId: UUID) -> String {
        templates.first { $0.id == templateId }?.name ?? "Custom"
    }

    private func estimateOneRM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        let denominator = 1.0278 - (0.0278 * Double(reps))
        guard denominator > 0 else { return 0 }
        return weight / denominator
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

#Preview {
    NavigationStack {
        ExercisesListView()
            .modelContainer(PreviewSampleData.makePreviewContainer())
    }
    .preferredColorScheme(.dark)
}
