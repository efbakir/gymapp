//
//  Exercise.swift
//  Unit
//
//  SwiftData model: exercise definition (display name, aliases, bodyweight flag).
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var displayName: String
    var aliasesData: Data?
    var notes: String
    var isBodyweight: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        aliases: [String] = [],
        notes: String = "",
        isBodyweight: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.aliasesData = (try? JSONEncoder().encode(aliases)) ?? nil
        self.notes = notes
        self.isBodyweight = isBodyweight
    }

    var aliases: [String] {
        get {
            guard let data = aliasesData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            aliasesData = try? JSONEncoder().encode(newValue)
        }
    }
}
