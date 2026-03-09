//
//  ProgressionEngine.swift
//  Unit
//
//  Pure target computation logic for adaptive periodization.
//

import Foundation

enum ProgressionEngine {
    struct WeekTarget: Equatable {
        let weekNumber: Int
        let weightKg: Double
        let reps: Int
    }

    struct SessionOutcome: Equatable {
        let weekNumber: Int
        let didFail: Bool
    }

    struct ProgressionRuleSnapshot: Equatable {
        let baseWeightKg: Double
        let baseReps: Int
        let incrementKg: Double
        let weekCount: Int
    }

    static func target(
        for weekNumber: Int,
        rule: ProgressionRuleSnapshot,
        outcomes: [SessionOutcome]
    ) -> WeekTarget? {
        computeTargets(rule: rule, outcomes: outcomes).first(where: { $0.weekNumber == weekNumber })
    }

    static func computeTargets(
        rule: ProgressionRuleSnapshot,
        outcomes: [SessionOutcome]
    ) -> [WeekTarget] {
        guard rule.weekCount > 0 else { return [] }
        let failuresByWeek = Set(outcomes.filter(\.didFail).map(\.weekNumber))

        return (1...rule.weekCount).map { week in
            let failedWeeksBefore = failuresByWeek.filter { $0 < week }.count
            let nominalWeight = rule.baseWeightKg + (Double(week - 1) * rule.incrementKg)
            let adjustedWeight = max(0.0, nominalWeight - (Double(failedWeeksBefore) * rule.incrementKg))
            return WeekTarget(weekNumber: week, weightKg: adjustedWeight, reps: rule.baseReps)
        }
    }
}
