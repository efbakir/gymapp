//
//  ProgressionEngine.swift
//  AtlasLog
//
//  Pure functional progression engine. No @Model, no SwiftUI imports.
//  All value types — concurrency-safe by construction.
//
//  Rule: All target calculations must go through ProgressionEngine.swift.
//  No view or ViewModel may compute targets directly.
//

import Foundation

enum ProgressionEngine {

    // MARK: - Value Types

    struct WeekTarget {
        let weekNumber: Int
        let weightKg: Double
        let reps: Int
        let isDeload: Bool
    }

    struct SessionOutcome {
        let weekNumber: Int
        let exerciseId: UUID
        let actualWeight: Double
        let actualReps: Int
        let targetWeight: Double
        let targetReps: Int

        var metTarget: Bool {
            actualWeight >= targetWeight && actualReps >= targetReps
        }
    }

    struct ProgressionRuleSnapshot {
        let exerciseId: UUID
        let incrementKg: Double
        let baseWeightKg: Double
        let baseReps: Int
        let deloadPercent: Double
        let weekCount: Int
    }

    // MARK: - Cascading Failure State

    struct FailureState {
        var consecutiveFailures: Int
        var currentWeight: Double
        var isDeloaded: Bool
    }

    // MARK: - Core API

    /// Compute all weekly targets for a rule, given historical outcomes.
    static func computeTargets(
        rule: ProgressionRuleSnapshot,
        outcomes: [SessionOutcome]
    ) -> [WeekTarget] {
        var targets: [WeekTarget] = []
        var state = FailureState(
            consecutiveFailures: 0,
            currentWeight: rule.baseWeightKg,
            isDeloaded: false
        )

        for week in 1...rule.weekCount {
            let isDeload = state.isDeloaded
            let target = WeekTarget(
                weekNumber: week,
                weightKg: state.currentWeight.rounded(to: 0.5),
                reps: rule.baseReps,
                isDeload: isDeload
            )
            targets.append(target)

            // Advance state based on the outcome for this week, if known.
            if let outcome = outcomes.first(where: { $0.weekNumber == week }) {
                let (newFailures, shouldDeload, newWeight) = processSessionComplete(
                    currentFailures: state.consecutiveFailures,
                    metTarget: outcome.metTarget,
                    deloadPercent: rule.deloadPercent,
                    currentWeight: state.currentWeight,
                    incrementKg: rule.incrementKg
                )
                state.consecutiveFailures = newFailures
                state.isDeloaded = shouldDeload
                state.currentWeight = newWeight
            } else {
                // No outcome yet — project forward optimistically (all success assumed)
                state.consecutiveFailures = 0
                state.isDeloaded = false
                state.currentWeight += rule.incrementKg
            }
        }

        return targets
    }

    /// Process a single completed session and return updated failure tracking.
    ///
    /// - Returns: (newConsecutiveFailures, shouldDeload, newWeightForNextWeek)
    static func processSessionComplete(
        currentFailures: Int,
        metTarget: Bool,
        deloadPercent: Double,
        currentWeight: Double,
        incrementKg: Double
    ) -> (newFailures: Int, shouldDeload: Bool, newWeight: Double) {
        if metTarget {
            // Success: reset failures, advance weight
            return (0, false, currentWeight + incrementKg)
        }

        let newFailures = currentFailures + 1

        if newFailures >= 3 {
            // 3 consecutive failures → 10% deload, reset counter
            let deloadedWeight = (currentWeight * (1.0 - deloadPercent)).rounded(to: 0.5)
            return (0, true, deloadedWeight)
        }

        // 1–2 failures → repeat same weight
        return (newFailures, false, currentWeight)
    }

    // MARK: - Target for a Specific Week

    /// Convenience: return the target for a specific week number.
    static func target(
        for weekNumber: Int,
        rule: ProgressionRuleSnapshot,
        outcomes: [SessionOutcome]
    ) -> WeekTarget? {
        let all = computeTargets(rule: rule, outcomes: outcomes)
        return all.first { $0.weekNumber == weekNumber }
    }
}

// MARK: - Double Rounding Helper

extension Double {
    /// Round to the nearest `increment` (e.g. 0.5, 1.25, 2.5 kg plates).
    func rounded(to increment: Double) -> Double {
        guard increment > 0 else { return self }
        return (self / increment).rounded() * increment
    }
}
