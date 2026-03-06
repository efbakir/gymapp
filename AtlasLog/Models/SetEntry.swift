//
//  SetEntry.swift
//  AtlasLog
//
//  SwiftData model: one set (weight, reps, RPE, warmup, completed).
//

import Foundation
import SwiftData

@Model
final class SetEntry {
    var id: UUID
    var sessionId: UUID
    var exerciseId: UUID
    var weight: Double
    var reps: Int
    /// 1–10; 0 = not set. Kept for legacy data.
    var rpe: Double
    /// Reps In Reserve: 0–5; -1 = not set. Primary effort field for cycle-based sessions.
    var rir: Int
    /// Target weight snapshot written at session start (kg); 0 = no target
    var targetWeight: Double
    /// Target reps snapshot written at session start; 0 = no target
    var targetReps: Int
    /// True if actual weight × reps met or exceeded target (written at session completion)
    var metTarget: Bool
    var isWarmup: Bool
    var isCompleted: Bool
    var setIndex: Int

    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        exerciseId: UUID,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Double = 0,
        rir: Int = -1,
        targetWeight: Double = 0.0,
        targetReps: Int = 0,
        metTarget: Bool = false,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        setIndex: Int = 0
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.rir = rir
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.metTarget = metTarget
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.setIndex = setIndex
    }
}
