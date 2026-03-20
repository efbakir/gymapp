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
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Week date range header
                let range = cycle.dateRange(for: weekNumber)
                let fmt: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "MMM d"
                    return f
                }()
                Text("\(fmt.string(from: range.lowerBound)) – \(fmt.string(from: range.upperBound))")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.sm)

                if cycleRules.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        AppIcon.sliders.image(size: 32, weight: .light)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("No progression rules for this cycle.")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    ForEach(cycleRules, id: \.id) { rule in
                        exerciseCard(rule: rule)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
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

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(AppFont.sectionHeader.font)
                Spacer(minLength: 0)
                if rule.isDeloaded {
                    HStack(spacing: AppSpacing.xs) {
                        AppIcon.deload.image()
                        Text("Deload")
                    }
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.warning)
                }
            }

            // Target row
            if let target = weekTarget {
                HStack {
                    Text("Target")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer(minLength: 0)
                    Text("\(target.weightKg.weightString)kg × \(target.reps)")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue("Target: \(target.weightKg.weightString)kg × \(target.reps) reps")
            }

            // Actual sets
            if actualSets.isEmpty {
                Text("Not logged yet")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ForEach(actualSets.sorted(by: { $0.setIndex < $1.setIndex }), id: \.id) { entry in
                    let met = entry.targetWeight > 0 ? (entry.weight >= entry.targetWeight && entry.reps >= entry.targetReps) : true
                    HStack {
                        Text("Set \(entry.setIndex + 1)")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(width: 44, alignment: .leading)
                        Text("\(entry.weight.weightString)kg × \(entry.reps)")
                            .font(AppFont.body.font)
                            .monospacedDigit()
                        Spacer(minLength: 0)
                        (met ? AppIcon.checkmarkFilled : AppIcon.xmarkFilled).image()
                            .foregroundStyle(met ? AppColor.success : AppColor.error)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue("Set \(entry.setIndex + 1): \(entry.weight.weightString)kg × \(entry.reps). \(met ? "Met target." : "Missed target.")")
                }
            }
        }
        .appCardStyle()
    }

}
