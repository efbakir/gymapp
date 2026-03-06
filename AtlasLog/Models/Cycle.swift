//
//  Cycle.swift
//  AtlasLog
//
//  SwiftData model: 8-week training cycle — the primary user container.
//

import Foundation
import SwiftData

@Model
final class Cycle {
    var id: UUID
    var name: String
    var splitId: UUID
    var startDate: Date
    /// Number of weeks in this cycle (default 8)
    var weekCount: Int
    /// Default increment applied globally when no per-exercise rule overrides (kg)
    var globalIncrementKg: Double
    var isActive: Bool
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        splitId: UUID,
        startDate: Date = Date(),
        weekCount: Int = 8,
        globalIncrementKg: Double = 2.5,
        isActive: Bool = true,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.splitId = splitId
        self.startDate = startDate
        self.weekCount = weekCount
        self.globalIncrementKg = globalIncrementKg
        self.isActive = isActive
        self.isCompleted = isCompleted
    }

    /// The date range for a given 1-indexed week number.
    func dateRange(for weekNumber: Int) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let weekOffset = weekNumber - 1
        let start = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate) ?? startDate
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return start...end
    }

    /// The current week number (1-indexed), clamped to weekCount.
    var currentWeekNumber: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let week = (days / 7) + 1
        return min(max(week, 1), weekCount)
    }
}
