//
//  ProgressionRule+Helpers.swift
//  Unit
//
//  Convenience extensions on ProgressionRule that bridge model data → engine types.
//  Single canonical location for snapshot creation and outcome extraction.
//

import Foundation

extension ProgressionRule {
    /// Build a ProgressionRuleSnapshot for use with ProgressionEngine.
    func snapshot(weekCount: Int) -> ProgressionEngine.ProgressionRuleSnapshot {
        ProgressionEngine.ProgressionRuleSnapshot(
            exerciseId: exerciseId,
            incrementKg: incrementKg,
            baseWeightKg: baseWeightKg,
            baseReps: baseReps,
            deloadPercent: deloadPercent,
            weekCount: weekCount
        )
    }

    /// Extract SessionOutcomes from completed sessions for this rule's exercise and cycle.
    func buildOutcomes(from sessions: [WorkoutSession]) -> [ProgressionEngine.SessionOutcome] {
        sessions
            .filter { $0.cycleId == cycleId && $0.weekNumber > 0 && $0.isCompleted }
            .compactMap { session -> ProgressionEngine.SessionOutcome? in
                let sets = session.setEntries.filter { $0.exerciseId == exerciseId && $0.isCompleted }
                guard let best = sets.max(by: { $0.weight < $1.weight }) else { return nil }
                return ProgressionEngine.SessionOutcome(
                    weekNumber: session.weekNumber,
                    exerciseId: exerciseId,
                    actualWeight: best.weight,
                    actualReps: best.reps,
                    targetWeight: best.targetWeight,
                    targetReps: best.targetReps
                )
            }
    }
}
