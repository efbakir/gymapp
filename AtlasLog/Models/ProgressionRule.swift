//
//  ProgressionRule.swift
//  Unit
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
    /// Fractional deload amount after repeated failures. 0.10 = 10%
    var deloadPercent: Double
    var consecutiveFailures: Int
    var isDeloaded: Bool

    init(
        id: UUID = UUID(),
        cycleId: UUID,
        exerciseId: UUID,
        incrementKg: Double = 2.5,
        baseWeightKg: Double,
        baseReps: Int,
        deloadPercent: Double = 0.10,
        consecutiveFailures: Int = 0,
        isDeloaded: Bool = false
    ) {
        self.id = id
        self.cycleId = cycleId
        self.exerciseId = exerciseId
        self.incrementKg = incrementKg
        self.baseWeightKg = baseWeightKg
        self.baseReps = baseReps
        self.deloadPercent = deloadPercent
        self.consecutiveFailures = consecutiveFailures
        self.isDeloaded = isDeloaded
    }
}
