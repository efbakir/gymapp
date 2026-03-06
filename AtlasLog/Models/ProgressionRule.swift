//
//  ProgressionRule.swift
//  AtlasLog
//
//  SwiftData model: per-exercise progression parameters within a cycle.
//  Targets are always computed by ProgressionEngine — never stored per-week.
//

import Foundation
import SwiftData

@Model
final class ProgressionRule {
    var id: UUID
    var cycleId: UUID
    var exerciseId: UUID
    /// Weight increment applied on success (kg)
    var incrementKg: Double
    /// Starting weight for Week 1 (kg)
    var baseWeightKg: Double
    /// Target reps for all sets in this cycle
    var baseReps: Int
    /// Number of consecutive failed weeks (0–3; resets after deload)
    var consecutiveFailures: Int
    /// True if the current week is a deload
    var isDeloaded: Bool
    /// Fraction to reduce weight on deload (default 0.10 = 10%)
    var deloadPercent: Double

    init(
        id: UUID = UUID(),
        cycleId: UUID,
        exerciseId: UUID,
        incrementKg: Double = 2.5,
        baseWeightKg: Double,
        baseReps: Int = 5,
        consecutiveFailures: Int = 0,
        isDeloaded: Bool = false,
        deloadPercent: Double = 0.10
    ) {
        self.id = id
        self.cycleId = cycleId
        self.exerciseId = exerciseId
        self.incrementKg = incrementKg
        self.baseWeightKg = baseWeightKg
        self.baseReps = baseReps
        self.consecutiveFailures = consecutiveFailures
        self.isDeloaded = isDeloaded
        self.deloadPercent = deloadPercent
    }
}
