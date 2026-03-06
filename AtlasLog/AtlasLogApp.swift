//
//  AtlasLogApp.swift
//  AtlasLog
//
//  Adaptive Periodization Engine — iOS 18+, Swift 6, SwiftUI, SwiftData.
//

import SwiftUI
import SwiftData

@main
struct AtlasLogApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            Cycle.self,
            ProgressionRule.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

enum PreviewSampleData {
    @MainActor
    static func makePreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            Cycle.self,
            ProgressionRule.self,
            configurations: config
        )
        seedIfNeeded(in: container.mainContext)
        return container
    }

    @MainActor
    static func seedIfNeeded(in modelContext: ModelContext) {
        if let existing = try? modelContext.fetch(FetchDescriptor<Split>()), !existing.isEmpty {
            return
        }

        // Exercises
        let bench = Exercise(displayName: "Barbell Bench Press", aliases: ["Bench", "Chest"])
        let inclineDB = Exercise(displayName: "DB Bench", aliases: ["Chest", "Incline DB"])
        let overheadPress = Exercise(displayName: "Overhead Press", aliases: ["OHP"])
        let row = Exercise(displayName: "Barbell Row", aliases: ["Bent Row"])
        let latPulldown = Exercise(displayName: "Lat Pulldown", aliases: ["Pulldown"])
        let squat = Exercise(displayName: "Back Squat", aliases: ["Squat"])
        let rdl = Exercise(displayName: "Romanian Deadlift", aliases: ["RDL"])

        [bench, inclineDB, overheadPress, row, latPulldown, squat, rdl].forEach { modelContext.insert($0) }

        // Split
        let split = Split(name: "Push / Pull / Legs")
        modelContext.insert(split)

        let push = DayTemplate(name: "Push", splitId: split.id, orderedExerciseIds: [bench.id, inclineDB.id, overheadPress.id])
        let pull = DayTemplate(name: "Pull", splitId: split.id, orderedExerciseIds: [row.id, latPulldown.id])
        let legs = DayTemplate(name: "Legs", splitId: split.id, orderedExerciseIds: [squat.id, rdl.id])
        split.orderedTemplateIds = [push.id, pull.id, legs.id]
        [push, pull, legs].forEach { modelContext.insert($0) }

        // Sessions
        let cal = Calendar.current
        let now = Date()

        let pushSession = WorkoutSession(
            date: cal.date(byAdding: .day, value: -8, to: now) ?? now,
            templateId: push.id, isCompleted: true, overallFeeling: 4
        )
        let pullSession = WorkoutSession(
            date: cal.date(byAdding: .day, value: -5, to: now) ?? now,
            templateId: pull.id, isCompleted: true, overallFeeling: 5
        )
        let legsSession = WorkoutSession(
            date: cal.date(byAdding: .day, value: -2, to: now) ?? now,
            templateId: legs.id, isCompleted: true, overallFeeling: 4
        )
        [pushSession, pullSession, legsSession].forEach { modelContext.insert($0) }

        let entries: [SetEntry] = [
            makeSet(session: pushSession, exercise: bench, weight: 92.5, reps: 5, index: 0),
            makeSet(session: pushSession, exercise: bench, weight: 95, reps: 4, index: 1),
            makeSet(session: pushSession, exercise: inclineDB, weight: 50, reps: 8, index: 0),
            makeSet(session: pushSession, exercise: overheadPress, weight: 55, reps: 6, index: 0),
            makeSet(session: pullSession, exercise: row, weight: 80, reps: 6, index: 0),
            makeSet(session: pullSession, exercise: latPulldown, weight: 70, reps: 10, index: 0),
            makeSet(session: legsSession, exercise: squat, weight: 100, reps: 5, index: 0),
            makeSet(session: legsSession, exercise: squat, weight: 102.5, reps: 4, index: 1),
            makeSet(session: legsSession, exercise: rdl, weight: 120, reps: 6, index: 0)
        ]
        entries.forEach { modelContext.insert($0) }

        push.lastPerformedDate = pushSession.date
        pull.lastPerformedDate = pullSession.date
        legs.lastPerformedDate = legsSession.date

        // Seed 1 active Cycle + ProgressionRules for push exercises
        let cycle = Cycle(
            name: "PPL Cycle 1 — March 2026",
            splitId: split.id,
            startDate: cal.date(byAdding: .weekOfYear, value: -2, to: now) ?? now,
            weekCount: 8,
            globalIncrementKg: 2.5,
            isActive: true,
            isCompleted: false
        )
        modelContext.insert(cycle)

        let pushRules: [(Exercise, Double, Int)] = [
            (bench, 92.5, 5),
            (inclineDB, 50.0, 8),
            (overheadPress, 55.0, 6)
        ]
        for (exercise, baseWeight, baseReps) in pushRules {
            let rule = ProgressionRule(
                cycleId: cycle.id,
                exerciseId: exercise.id,
                incrementKg: 2.5,
                baseWeightKg: baseWeight,
                baseReps: baseReps
            )
            modelContext.insert(rule)
        }

        // Also add rules for pull + legs
        let pullRules: [(Exercise, Double, Int)] = [
            (row, 80.0, 6),
            (latPulldown, 70.0, 10)
        ]
        for (exercise, baseWeight, baseReps) in pullRules {
            modelContext.insert(ProgressionRule(cycleId: cycle.id, exerciseId: exercise.id, incrementKg: 2.5, baseWeightKg: baseWeight, baseReps: baseReps))
        }
        let legsRules: [(Exercise, Double, Int)] = [
            (squat, 100.0, 5),
            (rdl, 120.0, 5)
        ]
        for (exercise, baseWeight, baseReps) in legsRules {
            modelContext.insert(ProgressionRule(cycleId: cycle.id, exerciseId: exercise.id, incrementKg: 2.5, baseWeightKg: baseWeight, baseReps: baseReps))
        }

        try? modelContext.save()
    }

    private static func makeSet(
        session: WorkoutSession,
        exercise: Exercise,
        weight: Double,
        reps: Int,
        index: Int
    ) -> SetEntry {
        let set = SetEntry(
            sessionId: session.id,
            exerciseId: exercise.id,
            weight: weight,
            reps: reps,
            isWarmup: false,
            isCompleted: true,
            setIndex: index
        )
        set.session = session
        return set
    }
}
