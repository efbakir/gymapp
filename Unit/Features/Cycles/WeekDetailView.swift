//
//  WeekDetailView.swift
//  Unit
//
//  Shows target vs. actual for every exercise in a given cycle week.
//

import SwiftUI
import SwiftData

struct WeekDetailView: View {
    let cycle: Cycle
    let weekNumber: Int
    let rules: [ProgressionRule]
    let exercises: [Exercise]
    let sessions: [WorkoutSession]

    private var cycleRules: [ProgressionRule] {
        rules.filter { $0.cycleId == cycle.id }
    }

    private var weekSessions: [WorkoutSession] {
        sessions.filter { $0.cycleId == cycle.id && $0.weekNumber == weekNumber && $0.isCompleted }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Week date range header
                let range = cycle.dateRange(for: weekNumber)
                let fmt: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "MMM d"
                    return f
                }()
                Text("\(fmt.string(from: range.lowerBound)) – \(fmt.string(from: range.upperBound))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.xs)

                if cycleRules.isEmpty {
                    Text("No progression rules for this cycle.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(cycleRules, id: \.id) { rule in
                        exerciseCard(rule: rule)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Week \(weekNumber)")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Exercise Card

    private func exerciseCard(rule: ProgressionRule) -> some View {
        let allTargets = ProgressionEngine.computeTargets(
            rule: rule.snapshot(weekCount: cycle.weekCount),
            outcomes: rule.buildOutcomes(from: sessions)
        )
        let weekTarget = allTargets.first(where: { $0.weekNumber == weekNumber })

        let name = exercises.first(where: { $0.id == rule.exerciseId })?.displayName ?? "Exercise"
        let actualSets = weekSessions.flatMap { $0.setEntries }.filter { $0.exerciseId == rule.exerciseId && $0.isCompleted }

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(Theme.Typography.title)
                Spacer(minLength: 0)
                if rule.isDeloaded {
                    Label("Deload", systemImage: "arrow.down.circle.fill")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.deload)
                }
            }

            // Target row
            if let target = weekTarget {
                HStack {
                    Text("Target")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.ghostText)
                    Spacer(minLength: 0)
                    Text("\(target.weightKg.weightString)kg × \(target.reps)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.ghostText)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue("Target: \(target.weightKg.weightString)kg × \(target.reps) reps")
            }

            // Actual sets
            if actualSets.isEmpty {
                Text("Not logged yet")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                ForEach(actualSets.sorted(by: { $0.setIndex < $1.setIndex }), id: \.id) { entry in
                    let met = entry.targetWeight > 0 ? (entry.weight >= entry.targetWeight && entry.reps >= entry.targetReps) : true
                    HStack {
                        Text("Set \(entry.setIndex + 1)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 44, alignment: .leading)
                        Text("\(entry.weight.weightString)kg × \(entry.reps)")
                            .font(Theme.Typography.body)
                            .monospacedDigit()
                        Spacer(minLength: 0)
                        Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(met ? Theme.Colors.accent : Theme.Colors.failure)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue("Set \(entry.setIndex + 1): \(entry.weight.weightString)kg × \(entry.reps). \(met ? "Met target." : "Missed target.")")
                }
            }
        }
        .cardStyle()
    }

}
