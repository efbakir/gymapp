//
//  DayTemplate.swift
//  AtlasLog
//
//  SwiftData models: split and program day with ordered exercise IDs.
//

import Foundation
import SwiftData

@Model
final class Split {
    var id: UUID
    var name: String
    var orderedTemplateIdsData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        orderedTemplateIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.orderedTemplateIdsData = (try? JSONEncoder().encode(orderedTemplateIds.map { $0.uuidString })) ?? nil
    }

    var orderedTemplateIds: [UUID] {
        get {
            guard let data = orderedTemplateIdsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded.compactMap { UUID(uuidString: $0) }
        }
        set {
            orderedTemplateIdsData = try? JSONEncoder().encode(newValue.map { $0.uuidString })
        }
    }
}

@Model
final class DayTemplate {
    var id: UUID
    var name: String
    var splitId: UUID?
    var orderedExerciseIdsData: Data?
    var lastPerformedDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        splitId: UUID? = nil,
        orderedExerciseIds: [UUID] = [],
        lastPerformedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.splitId = splitId
        self.orderedExerciseIdsData = (try? JSONEncoder().encode(orderedExerciseIds.map { $0.uuidString })) ?? nil
        self.lastPerformedDate = lastPerformedDate
    }

    var orderedExerciseIds: [UUID] {
        get {
            guard let data = orderedExerciseIdsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded.compactMap { UUID(uuidString: $0) }
        }
        set {
            orderedExerciseIdsData = try? JSONEncoder().encode(newValue.map { $0.uuidString })
        }
    }
}
