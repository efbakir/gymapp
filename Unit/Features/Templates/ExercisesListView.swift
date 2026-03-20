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
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(exercise.displayName)
                                .font(AppFont.body.font)
                            if exercise.isBodyweight {
                                Text("BW")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        if !exercise.aliases.isEmpty {
                            Text(exercise.aliases.joined(separator: " • "))
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            .onDelete(perform: deleteExercises)
            .listRowBackground(AppColor.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background.ignoresSafeArea())
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
                    AppIcon.addCircle.image()
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
                .listRowBackground(AppColor.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background.ignoresSafeArea())
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
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(exercise.displayName)
                        .font(AppFont.largeTitle.font)
                    Text("Brzycki 1RM and session volume")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .appCardStyle()

                if summaries.isEmpty {
                    Text("No logged sessions yet.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .appCardStyle()
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Estimated 1RM Trend")
                            .font(AppFont.sectionHeader.font)
                        Chart(trendAscending) { item in
                            LineMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AppColor.textPrimary)
                            PointMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AppColor.textPrimary)
                        }
                        .frame(height: 180)
                    }
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Session Volume")
                            .font(AppFont.sectionHeader.font)
                        Chart(trendAscending) { item in
                            BarMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("Volume", item.totalVolume)
                            )
                            .foregroundStyle(AppColor.accentSoft)
                        }
                        .frame(height: 160)
                    }
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Past Sessions")
                            .font(AppFont.sectionHeader.font)

                        ForEach(summaries) { summary in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    Text(summary.templateName)
                                        .font(AppFont.body.font)
                                    Spacer(minLength: 0)
                                    Text(summary.sessionDate, style: .date)
                                        .font(AppFont.caption.font)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                Text("Top set: \(summary.topSetText)")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                                Text("Est. 1RM: \(formatWeight(summary.estimatedOneRM)) kg • Volume: \(Int(summary.totalVolume))")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppSpacing.sm)

                            if summary.id != summaries.last?.id {
                                AppDivider()
                            }
                        }
                    }
                    .appCardStyle()
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
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
}
