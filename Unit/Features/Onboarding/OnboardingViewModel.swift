//
//  OnboardingViewModel.swift
//  Unit
//
//  Transient onboarding state. No SwiftData @Model — all writes happen
//  atomically in commit() when the user taps "Create My Cycle".
//

import Foundation
import Observation
import SwiftData

// MARK: - Supporting Types

struct OnboardingExercise: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
}

struct OnboardingBaseline {
    var weightKg: Double = 0
    var reps: Int = 8
}

// MARK: - ViewModel

@Observable
final class OnboardingViewModel {

    // MARK: Path

    enum SetupPath { case build, sample }
    var setupPath: SetupPath = .build

    // MARK: Units

    /// "kg" or "lb". Written to AppStorage("unitSystem") after commit.
    var unitSystem: String = "kg"

    // MARK: Split

    var dayCount: Int = 3
    var dayNames: [String] = ["Day 1", "Day 2", "Day 3"]
    var dayExercises: [[OnboardingExercise]] = [[], [], []]

    // MARK: Baselines

    var baselines: [UUID: OnboardingBaseline] = [:]

    // MARK: Progression

    var globalIncrementKg: Double = 2.5

    // MARK: Start Date

    enum StartOption { case today, nextMonday, custom }
    var startOption: StartOption = .today
    var customDate: Date = Date()

    // MARK: - Computed Helpers

    var startDate: Date {
        let cal = Calendar.current
        switch startOption {
        case .today:
            return cal.startOfDay(for: Date())
        case .nextMonday:
            let weekday = cal.component(.weekday, from: Date())
            let days = weekday == 2 ? 7 : (9 - weekday) % 7
            return cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: Date())) ?? Date()
        case .custom:
            return cal.startOfDay(for: customDate)
        }
    }

    var weightUnitLabel: String { unitSystem }

    /// Display a kg value in the user's chosen unit.
    func displayWeight(_ kg: Double) -> Double {
        unitSystem == "lb" ? kg * 2.20462 : kg
    }

    /// Convert a user-entered display value back to kg for storage.
    func storeWeightKg(_ displayValue: Double) -> Double {
        unitSystem == "lb" ? displayValue / 2.20462 : displayValue
    }

    var incrementDisplay: Double {
        unitSystem == "lb" ? globalIncrementKg * 2.20462 : globalIncrementKg
    }

    var incrementStep: Double { unitSystem == "lb" ? 2.5 : 1.25 }
    var incrementMin: Double { unitSystem == "lb" ? 2.5 : 1.25 }
    var incrementMax: Double { unitSystem == "lb" ? 22.0 : 10.0 }

    func incrementDisplayLabel() -> String {
        let val = incrementDisplay
        let unit = unitSystem
        return "\(val.weightString) \(unit)"
    }

    func stepUp() {
        let step = unitSystem == "lb" ? 2.5 / 2.20462 : 1.25
        let max = unitSystem == "lb" ? 22.0 / 2.20462 : 10.0
        globalIncrementKg = min(max, globalIncrementKg + step)
    }

    func stepDown() {
        let step = unitSystem == "lb" ? 2.5 / 2.20462 : 1.25
        globalIncrementKg = max(step, globalIncrementKg - step)
    }

    // MARK: - Day Management

    func updateDayCount(_ newCount: Int) {
        let count = max(2, min(6, newCount))
        dayCount = count
        while dayNames.count < count { dayNames.append("Day \(dayNames.count + 1)") }
        if dayNames.count > count { dayNames = Array(dayNames.prefix(count)) }
        while dayExercises.count < count { dayExercises.append([]) }
        if dayExercises.count > count { dayExercises = Array(dayExercises.prefix(count)) }
    }

    // MARK: - Sample Seeding

    func seedSampleData() {
        dayCount = 3
        dayNames = ["Push", "Pull", "Legs"]

        let pushExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Bench Press"),
            OnboardingExercise(name: "Overhead Press"),
            OnboardingExercise(name: "Tricep Pushdown")
        ]
        let pullExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Barbell Row"),
            OnboardingExercise(name: "Lat Pulldown"),
            OnboardingExercise(name: "Pull-up")
        ]
        let legsExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Back Squat"),
            OnboardingExercise(name: "Romanian Deadlift"),
            OnboardingExercise(name: "Leg Press")
        ]
        dayExercises = [pushExs, pullExs, legsExs]

        // Intermediate baselines (stored in kg)
        let samples: [(OnboardingExercise, Double, Int)] = [
            (pushExs[0], 80, 8),
            (pushExs[1], 52.5, 8),
            (pushExs[2], 30, 12),
            (pullExs[0], 70, 8),
            (pullExs[1], 60, 10),
            (pullExs[2], 0, 8),
            (legsExs[0], 90, 5),
            (legsExs[1], 100, 8),
            (legsExs[2], 120, 10)
        ]
        for (ex, kg, reps) in samples {
            baselines[ex.id] = OnboardingBaseline(weightKg: kg, reps: reps)
        }
    }

    // MARK: - Validation

    var splitIsValid: Bool {
        dayNames.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var exercisesAreValid: Bool {
        dayExercises.allSatisfy { !$0.isEmpty }
    }

    var baselinesAreValid: Bool {
        for day in dayExercises {
            for ex in day {
                let b = baselines[ex.id]
                if (b?.reps ?? 0) < 1 { return false }
            }
        }
        return true
    }

    /// Indices of days that are missing at least one exercise baseline.
    var incompleteDayIndices: Set<Int> {
        var result = Set<Int>()
        for (i, day) in dayExercises.enumerated() {
            for ex in day {
                let b = baselines[ex.id]
                if (b?.reps ?? 0) < 1 { result.insert(i) }
            }
        }
        return result
    }

    // MARK: - Commit

    func commit(modelContext: ModelContext) throws {
        // 1. Resolve exercises (name lookup or create)
        var nameToExercise: [String: Exercise] = [:]
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        for ex in existing { nameToExercise[ex.displayName.lowercased()] = ex }

        var exerciseMap: [UUID: Exercise] = [:]
        for day in dayExercises {
            for onbEx in day {
                let key = onbEx.name.trimmingCharacters(in: .whitespaces).lowercased()
                if let match = nameToExercise[key] {
                    exerciseMap[onbEx.id] = match
                } else {
                    let ex = Exercise(displayName: onbEx.name.trimmingCharacters(in: .whitespaces))
                    modelContext.insert(ex)
                    exerciseMap[onbEx.id] = ex
                    nameToExercise[key] = ex
                }
            }
        }

        // 2. Create Split
        let splitName = dayNames.joined(separator: " / ")
        let split = Split(name: splitName)
        modelContext.insert(split)

        // 3. Create DayTemplates
        var templateIds: [UUID] = []
        for (i, name) in dayNames.enumerated() {
            let exerciseIds = dayExercises[i].compactMap { exerciseMap[$0.id]?.id }
            let tmpl = DayTemplate(name: name, splitId: split.id, orderedExerciseIds: exerciseIds)
            modelContext.insert(tmpl)
            templateIds.append(tmpl.id)
        }
        split.orderedTemplateIds = templateIds

        // 4. Create Cycle
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let cycleName = "\(splitName) Cycle 1 — \(fmt.string(from: startDate))"
        let cycle = Cycle(
            name: cycleName,
            splitId: split.id,
            startDate: startDate,
            weekCount: 8,
            globalIncrementKg: globalIncrementKg,
            isActive: true,
            isCompleted: false
        )
        modelContext.insert(cycle)

        // 5. ProgressionRules — one per exercise, deduplicated
        var seenExerciseIds = Set<UUID>()
        for day in dayExercises {
            for onbEx in day {
                guard let exercise = exerciseMap[onbEx.id] else { continue }
                guard !seenExerciseIds.contains(exercise.id) else { continue }
                seenExerciseIds.insert(exercise.id)
                let baseline = baselines[onbEx.id] ?? OnboardingBaseline()
                let rule = ProgressionRule(
                    cycleId: cycle.id,
                    exerciseId: exercise.id,
                    incrementKg: globalIncrementKg,
                    baseWeightKg: baseline.weightKg,
                    baseReps: max(1, baseline.reps)
                )
                modelContext.insert(rule)
            }
        }

        try modelContext.save()
    }
}

// MARK: - Common Exercise Library (suggestions)

enum ExerciseLibrary {
    static let suggestions: [String] = [
        // Chest
        "Bench Press", "Incline Bench Press", "Dumbbell Flye", "Cable Fly",
        // Shoulders
        "Overhead Press", "Arnold Press", "Lateral Raise", "Front Raise",
        // Triceps
        "Tricep Pushdown", "Skull Crusher", "Close Grip Bench Press", "Overhead Tricep Extension",
        // Back
        "Pull-up", "Chin-up", "Barbell Row", "Dumbbell Row", "Lat Pulldown", "Cable Row", "T-Bar Row",
        // Biceps
        "Barbell Curl", "Dumbbell Curl", "Hammer Curl", "Preacher Curl", "Cable Curl",
        // Legs
        "Back Squat", "Front Squat", "Leg Press", "Hack Squat", "Lunge",
        "Romanian Deadlift", "Leg Curl", "Leg Extension", "Calf Raise",
        // Posterior chain
        "Deadlift", "Sumo Deadlift", "Hip Thrust", "Good Morning",
        // Core
        "Plank", "Ab Wheel Rollout", "Hanging Leg Raise", "Cable Crunch"
    ]

    static func filtered(by query: String) -> [String] {
        guard !query.isEmpty else { return suggestions }
        let q = query.lowercased()
        return suggestions.filter { $0.lowercased().contains(q) }
    }
}
