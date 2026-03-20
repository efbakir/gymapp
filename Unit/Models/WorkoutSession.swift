//
//  WorkoutSession.swift
//  Unit
//
//  SwiftData model: one instance of a template performed on a date.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var templateId: UUID
    var isCompleted: Bool = false
    /// 1–5, optional; 0 or nil = not set
    var overallFeeling: Int
    /// Nil for legacy sessions not part of a cycle
    var cycleId: UUID?
    /// 0 = legacy (no cycle); 1–8 = week number within the cycle
    var weekNumber: Int

    @Relationship(deleteRule: .cascade)
    var setEntries: [SetEntry] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        templateId: UUID,
        isCompleted: Bool = false,
        overallFeeling: Int = 0,
        cycleId: UUID? = nil,
        weekNumber: Int = 0
    ) {
        self.id = id
        self.date = date
        self.templateId = templateId
        self.isCompleted = isCompleted
        self.overallFeeling = overallFeeling
        self.cycleId = cycleId
        self.weekNumber = weekNumber
    }
}
