//
//  ProgressionRule.swift
//  AtlasLog
//
//  SwiftData model: progression settings per exercise inside a cycle.
//

import Foundation
import SwiftData

@Model
final class ProgressionRule {
    var id: UUID
    var cycleId: UUID
    var exerciseId: UUID
    var incrementKg: Double
    var baseWeightKg: Double
    var baseReps: Int
    var isDeloaded: Bool

    init(
        id: UUID = UUID(),
        cycleId: UUID,
        exerciseId: UUID,
        incrementKg: Double = 2.5,
        baseWeightKg: Double,
        baseReps: Int,
        isDeloaded: Bool = false
    ) {
        self.id = id
        self.cycleId = cycleId
        self.exerciseId = exerciseId
        self.incrementKg = incrementKg
        self.baseWeightKg = baseWeightKg
        self.baseReps = baseReps
        self.isDeloaded = isDeloaded
    }

    func snapshot(weekCount: Int) -> ProgressionEngine.ProgressionRuleSnapshot {
        ProgressionEngine.ProgressionRuleSnapshot(
            baseWeightKg: baseWeightKg,
            baseReps: baseReps,
            incrementKg: incrementKg,
            weekCount: weekCount
        )
    }

    func buildOutcomes(from sessions: [WorkoutSession]) -> [ProgressionEngine.SessionOutcome] {
        sessions
            .filter { $0.cycleId == cycleId && $0.weekNumber > 0 && $0.isCompleted }
            .filter { session in
                session.setEntries.contains { $0.exerciseId == exerciseId && !$0.isWarmup && $0.isCompleted }
            }
            .map { session in
                let didFail = session.setEntries.contains { entry in
                    entry.exerciseId == exerciseId
                        && !entry.isWarmup
                        && entry.isCompleted
                        && ((entry.targetWeight > 0 && !entry.metTarget) || entry.rir == 0)
                }
                return ProgressionEngine.SessionOutcome(weekNumber: session.weekNumber, didFail: didFail)
            }
    }
}
