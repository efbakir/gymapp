//
//  Cycle.swift
//  Unit
//
//  SwiftData model: 8-week training cycle container.
//

import Foundation
import SwiftData

@Model
final class Cycle {
    var id: UUID
    var name: String
    var splitId: UUID?
    var startDate: Date
    var weekCount: Int
    var globalIncrementKg: Double
    var isActive: Bool
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        splitId: UUID? = nil,
        startDate: Date = Date(),
        weekCount: Int = 8,
        globalIncrementKg: Double = 2.5,
        isActive: Bool = false,
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

    var currentWeekNumber: Int {
        guard weekCount > 0 else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Date()).day ?? 0
        let week = max(1, (days / 7) + 1)
        return min(week, weekCount)
    }

    func dateRange(for weekNumber: Int) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: max(0, (weekNumber - 1) * 7), to: calendar.startOfDay(for: startDate)) ?? startDate
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return start...end
    }
}
