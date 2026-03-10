//
//  CreateCycleView.swift
//  Unit
//
//  Sheet for creating a new 8-week training cycle with per-exercise progression rules.
//

import SwiftUI
import SwiftData

struct CreateCycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    // Form state
    @State private var cycleName: String = ""
    @State private var selectedSplitId: UUID?
    @State private var startDate: Date = Date()
    @State private var weekCount: Int = 8
    @State private var globalIncrementKg: Double = 2.5
    @State private var showAdvanced = false
    @State private var perExerciseOverrides: [UUID: ExerciseOverride] = [:]

    // Goal state
    @State private var showGoal = false
    @State private var goalExerciseId: UUID?
    @State private var goalWeightKg: Double = 100
    @State private var goalReps: Int = 5

    struct ExerciseOverride {
        var baseWeightKg: Double
        var incrementKg: Double
        var baseReps: Int
    }

    private var selectedSplit: Split? {
        splits.first(where: { $0.id == selectedSplitId })
    }

    private var exercisesInSplit: [Exercise] {
        guard let split = selectedSplit else { return [] }
        let templateIds = Set(split.orderedTemplateIds)
        let tmplExerciseIds = templates
            .filter { templateIds.contains($0.id) }
            .flatMap { $0.orderedExerciseIds }
        var seen = Set<UUID>()
        return tmplExerciseIds.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return exercises.first(where: { $0.id == id })
        }
    }

    private var canCreate: Bool {
        !cycleName.trimmingCharacters(in: .whitespaces).isEmpty && selectedSplitId != nil
    }

    private var goalExercise: Exercise? {
        goalExerciseId.flatMap { id in exercises.first(where: { $0.id == id }) }
    }

    private var goalEstimateText: String? {
        guard let exId = goalExerciseId,
              let override = perExerciseOverrides[exId] else { return nil }
        let current = override.baseWeightKg
        let increment = override.incrementKg
        guard increment > 0, goalWeightKg > current else { return nil }
        let delta = goalWeightKg - current
        let cyclesNeeded = Int(ceil(delta / (increment * Double(weekCount))))
        let isAggressive = delta > 30 && cyclesNeeded <= 2
        let warning = isAggressive ? " — aggressive jump, consider starting lower" : ""
        return "At +\(increment.weightString)kg/week, you'll reach \(goalWeightKg.weightString)kg in ~\(cyclesNeeded) cycle\(cyclesNeeded == 1 ? "" : "s")\(warning)"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Step 1: Split
                Section("1. Pick a Split") {
                    if splits.isEmpty {
                        Text("No splits found. Create a split in Program first.")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } else {
                        ForEach(splits, id: \.id) { split in
                            Button {
                                selectedSplitId = split.id
                                autofillCycleName(split: split)
                                seedOverrides()
                            } label: {
                                HStack {
                                    Text(split.name)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                    if selectedSplitId == split.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }

                // Step 2: Name
                Section("2. Cycle Name") {
                    TextField("e.g. PPL Cycle 1 — March 2026", text: $cycleName)
                        .frame(minHeight: 44)
                }

                // Step 3: Start Date
                Section("3. Start Date") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                }

                // Step 4: Global Increment
                Section("4. Default Weekly Increment") {
                    Stepper(
                        value: $globalIncrementKg,
                        in: 0.5...10.0,
                        step: 0.5
                    ) {
                        HStack {
                            Text("Increment")
                            Spacer()
                            Text("\(globalIncrementKg.weightString) kg")
                                .foregroundStyle(Theme.Colors.accent)
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 44)
                }

                // Step 5: Per-exercise overrides (advanced, collapsed)
                Section {
                    DisclosureGroup("Per-Exercise Overrides (Advanced)", isExpanded: $showAdvanced) {
                        if exercisesInSplit.isEmpty {
                            Text("Select a split above to configure per-exercise targets.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } else {
                            ForEach(exercisesInSplit, id: \.id) { exercise in
                                exerciseOverrideRow(exercise)
                            }
                        }
                    }
                }

                // Step 6: Goal awareness (optional)
                Section {
                    DisclosureGroup("Goal Lift (Optional)", isExpanded: $showGoal) {
                        if exercisesInSplit.isEmpty {
                            Text("Select a split above to choose a goal lift.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } else {
                            Picker("Exercise", selection: $goalExerciseId) {
                                Text("None").tag(Optional<UUID>.none)
                                ForEach(exercisesInSplit, id: \.id) { ex in
                                    Text(ex.displayName).tag(Optional(ex.id))
                                }
                            }
                            .frame(minHeight: 44)

                            if goalExerciseId != nil {
                                HStack {
                                    Text("Target weight")
                                    Spacer()
                                    Stepper(
                                        value: $goalWeightKg,
                                        in: 0...500,
                                        step: 2.5
                                    ) {
                                        Text("\(goalWeightKg.weightString)kg")
                                            .monospacedDigit()
                                    }
                                }
                                .frame(minHeight: 44)

                                HStack {
                                    Text("Target reps")
                                    Spacer()
                                    Stepper(value: $goalReps, in: 1...20) {
                                        Text("\(goalReps) reps")
                                    }
                                }
                                .frame(minHeight: 44)

                                if let estimate = goalEstimateText {
                                    Text(estimate)
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.accent)
                                        .padding(.vertical, Theme.Spacing.xxs)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create Cycle") {
                        createCycle()
                    }
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(canCreate ? Theme.Colors.accent : Color.gray)
                    .disabled(!canCreate)
                }
            }
            .onAppear {
                if let first = splits.first {
                    selectedSplitId = first.id
                    autofillCycleName(split: first)
                    seedOverrides()
                }
            }
        }
    }

    // MARK: - Per-Exercise Row

    private func exerciseOverrideRow(_ exercise: Exercise) -> some View {
        let override = Binding<ExerciseOverride>(
            get: { perExerciseOverrides[exercise.id] ?? ExerciseOverride(baseWeightKg: 60, incrementKg: globalIncrementKg, baseReps: 5) },
            set: { perExerciseOverrides[exercise.id] = $0 }
        )

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(exercise.displayName)
                .font(Theme.Typography.title)

            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading) {
                    Text("Base Weight (kg)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Stepper(
                        value: override.baseWeightKg,
                        in: 0...300,
                        step: 2.5
                    ) {
                        Text("\(override.wrappedValue.baseWeightKg.weightString)")
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .leading) {
                    Text("Increment (kg)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Stepper(
                        value: override.incrementKg,
                        in: 0.5...10,
                        step: 0.5
                    ) {
                        Text("+\(override.wrappedValue.incrementKg.weightString)")
                            .monospacedDigit()
                    }
                }
            }
            .frame(minHeight: 44)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Actions

    private func autofillCycleName(split: Split) {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        cycleName = "\(split.name) Cycle 1 — \(fmt.string(from: startDate))"
    }

    private func seedOverrides() {
        // Build a single flat list of completed sets once, then group by exerciseId
        let allSets = sessions.flatMap { $0.setEntries }.filter(\.isCompleted)
        let byExercise = Dictionary(grouping: allSets, by: \.exerciseId)

        for exercise in exercisesInSplit {
            guard perExerciseOverrides[exercise.id] == nil else { continue }
            let sets = byExercise[exercise.id] ?? []
            let recentWeight = sets.max(by: { $0.weight < $1.weight })?.weight ?? 60.0
            let recentReps = sets.first?.reps ?? 5
            perExerciseOverrides[exercise.id] = ExerciseOverride(
                baseWeightKg: recentWeight,
                incrementKg: globalIncrementKg,
                baseReps: recentReps
            )
        }
    }

    private func createCycle() {
        guard let splitId = selectedSplitId else { return }

        let cycle = Cycle(
            name: cycleName.trimmingCharacters(in: .whitespaces),
            splitId: splitId,
            startDate: startDate,
            weekCount: weekCount,
            globalIncrementKg: globalIncrementKg,
            isActive: true,
            isCompleted: false
        )
        modelContext.insert(cycle)

        // Deactivate any previously active cycle
        // (handled by the new cycle's isActive flag being the source of truth)

        // Insert ProgressionRule for each exercise in the split
        for exercise in exercisesInSplit {
            let override = perExerciseOverrides[exercise.id]
            let rule = ProgressionRule(
                cycleId: cycle.id,
                exerciseId: exercise.id,
                incrementKg: override?.incrementKg ?? globalIncrementKg,
                baseWeightKg: override?.baseWeightKg ?? 60.0,
                baseReps: override?.baseReps ?? 5
            )
            modelContext.insert(rule)
        }

        try? modelContext.save()
        dismiss()
    }

}

#Preview {
    CreateCycleView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
