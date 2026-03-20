//
//  UnitApp.swift
//  Unit
//
//  Adaptive Periodization Engine — iOS 18+, Swift 6, SwiftUI, SwiftData.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct UnitApp: App {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.atlaslog.app",
        category: "SwiftData"
    )

    private static let schema = Schema([
            Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            Cycle.self,
            ProgressionRule.self
        ])

    var sharedModelContainer: ModelContainer = Self.makeSharedModelContainer()

    private static func makeSharedModelContainer() -> ModelContainer {
        let isRunningPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isRunningPreviews {
            return makeInMemoryContainer(orDieWith: "Could not create preview ModelContainer.")
        }

        do {
            let storeURL = try persistentStoreURL()
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            return try makePersistentContainer(configuration: configuration)
        } catch {
            logger.error("Persistent ModelContainer failed. Falling back to in-memory store. Error: \(String(describing: error), privacy: .public)")
            return makeInMemoryContainer(orDieWith: "Could not create fallback ModelContainer.")
        }
    }

    private static func makePersistentContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("Persistent store open failed. Resetting local store. Error: \(String(describing: error), privacy: .public)")
            resetStoreFiles(at: configuration.url)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    private static func makeInMemoryContainer(orDieWith message: String) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("\(message) \(error)")
        }
    }

    private static func persistentStoreURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("Unit", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        return directoryURL.appendingPathComponent("Unit.store")
    }

    private static func resetStoreFiles(at storeURL: URL) {
        let fileManager = FileManager.default
        let sidecarURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in sidecarURLs where fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                logger.error("Failed to remove store file at \(url.path, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }

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
        guard let container = buildContainer(config: config) else {
            preconditionFailure("Preview container creation failed.")
        }
        seedIfNeeded(in: container.mainContext)
        return container
    }

    @MainActor
    private static func buildContainer(config: ModelConfiguration) -> ModelContainer? {
        try? ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            Cycle.self,
            ProgressionRule.self,
            configurations: config
        )
    }

    @MainActor
    static func seedIfNeeded(in modelContext: ModelContext) {
        if let existing = try? modelContext.fetch(FetchDescriptor<Split>()), !existing.isEmpty {
            return
        }

        // MARK: - Exercises (full PPL roster)
        let bench      = Exercise(displayName: "Barbell Bench Press", aliases: ["Bench", "Chest"])
        let inclineDB  = Exercise(displayName: "Incline DB Press", aliases: ["Incline", "Chest"])
        let ohp        = Exercise(displayName: "Overhead Press", aliases: ["OHP", "Press"])
        let tricepPD   = Exercise(displayName: "Tricep Pushdown", aliases: ["Pushdown"])
        let lateralR   = Exercise(displayName: "Lateral Raise", aliases: ["Laterals"])
        let row        = Exercise(displayName: "Barbell Row", aliases: ["Bent Row"])
        let pulldown   = Exercise(displayName: "Lat Pulldown", aliases: ["Pulldown"])
        let cableRow   = Exercise(displayName: "Cable Row", aliases: ["Seated Row"])
        let bicepCurl  = Exercise(displayName: "Barbell Curl", aliases: ["Bicep Curl", "Curl"])
        let squat      = Exercise(displayName: "Back Squat", aliases: ["Squat"])
        let rdl        = Exercise(displayName: "Romanian Deadlift", aliases: ["RDL"])
        let legPress   = Exercise(displayName: "Leg Press", aliases: ["Leg Press"])
        let calfRaise  = Exercise(displayName: "Calf Raise", aliases: ["Calves"])

        let allExercises = [bench, inclineDB, ohp, tricepPD, lateralR,
                            row, pulldown, cableRow, bicepCurl,
                            squat, rdl, legPress, calfRaise]
        allExercises.forEach { modelContext.insert($0) }

        // MARK: - Split
        let split = Split(name: "Push / Pull / Legs")
        modelContext.insert(split)

        let push = DayTemplate(name: "Push A", splitId: split.id,
                               orderedExerciseIds: [bench.id, inclineDB.id, ohp.id, tricepPD.id, lateralR.id])
        let pull = DayTemplate(name: "Pull A", splitId: split.id,
                               orderedExerciseIds: [row.id, pulldown.id, cableRow.id, bicepCurl.id])
        let legs = DayTemplate(name: "Legs A", splitId: split.id,
                               orderedExerciseIds: [squat.id, rdl.id, legPress.id, calfRaise.id])
        split.orderedTemplateIds = [push.id, pull.id, legs.id]
        [push, pull, legs].forEach { modelContext.insert($0) }

        // MARK: - Active Cycle
        let cal = Calendar.current
        let now = Date()

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

        // Progression rules
        let pushRules: [(Exercise, Double, Int)] = [
            (bench,   95.0, 5), (inclineDB, 30.0, 10), (ohp, 62.5, 6),
            (tricepPD, 40.0, 12), (lateralR, 15.0, 15)
        ]
        let pullRules: [(Exercise, Double, Int)] = [
            (row, 82.5, 6), (pulldown, 72.5, 10), (cableRow, 60.0, 12), (bicepCurl, 42.5, 10)
        ]
        let legsRules: [(Exercise, Double, Int)] = [
            (squat, 102.5, 5), (rdl, 120.0, 6), (legPress, 160.0, 10), (calfRaise, 80.0, 15)
        ]
        for (ex, base, reps) in pushRules + pullRules + legsRules {
            modelContext.insert(ProgressionRule(cycleId: cycle.id, exerciseId: ex.id,
                                               incrementKg: 2.5, baseWeightKg: base, baseReps: reps))
        }

        // MARK: - Historical sessions (6 weeks × 3 sessions = ~18 sessions)
        var allEntries: [SetEntry] = []

        func addSession(templateId: UUID, daysAgo: Int, feeling: Int,
                        sets: [(Exercise, Double, Int, Int)]) {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let session = WorkoutSession(date: date, templateId: templateId,
                                         isCompleted: true, overallFeeling: feeling,
                                         cycleId: cycle.id, weekNumber: max(1, (42 - daysAgo) / 7))
            modelContext.insert(session)
            for (ex, weight, reps, idx) in sets {
                let entry = SetEntry(sessionId: session.id, exerciseId: ex.id,
                                     weight: weight, reps: reps,
                                     isWarmup: false, isCompleted: true, setIndex: idx)
                entry.session = session
                allEntries.append(entry)
            }
        }

        // Week 1
        addSession(templateId: push.id, daysAgo: 42, feeling: 4, sets: [
            (bench,95,5,0),(bench,95,5,1),(bench,90,5,2),(bench,90,5,3),
            (inclineDB,30,10,0),(inclineDB,30,10,1),(inclineDB,27.5,10,2),
            (ohp,62.5,6,0),(ohp,62.5,6,1),(ohp,60,6,2),
            (tricepPD,40,12,0),(tricepPD,40,12,1),(tricepPD,37.5,12,2),
            (lateralR,15,15,0),(lateralR,15,15,1),(lateralR,12.5,15,2)
        ])
        addSession(templateId: pull.id, daysAgo: 40, feeling: 5, sets: [
            (row,82.5,6,0),(row,82.5,6,1),(row,80,6,2),(row,80,6,3),
            (pulldown,72.5,10,0),(pulldown,72.5,10,1),(pulldown,70,10,2),
            (cableRow,60,12,0),(cableRow,60,12,1),(cableRow,57.5,12,2),
            (bicepCurl,42.5,10,0),(bicepCurl,42.5,10,1),(bicepCurl,40,10,2)
        ])
        addSession(templateId: legs.id, daysAgo: 38, feeling: 4, sets: [
            (squat,102.5,5,0),(squat,102.5,5,1),(squat,100,5,2),(squat,100,5,3),
            (rdl,120,6,0),(rdl,120,6,1),(rdl,117.5,6,2),
            (legPress,160,10,0),(legPress,160,10,1),(legPress,155,10,2),
            (calfRaise,80,15,0),(calfRaise,80,15,1),(calfRaise,80,15,2)
        ])
        // Week 2
        addSession(templateId: push.id, daysAgo: 35, feeling: 5, sets: [
            (bench,97.5,5,0),(bench,97.5,5,1),(bench,95,4,2),(bench,92.5,4,3),
            (inclineDB,32.5,10,0),(inclineDB,32.5,10,1),(inclineDB,30,9,2),
            (ohp,65,6,0),(ohp,65,5,1),(ohp,62.5,6,2),
            (tricepPD,42.5,12,0),(tricepPD,42.5,11,1),(tricepPD,40,12,2),
            (lateralR,15,15,0),(lateralR,15,15,1),(lateralR,15,14,2)
        ])
        addSession(templateId: pull.id, daysAgo: 33, feeling: 4, sets: [
            (row,85,6,0),(row,85,5,1),(row,82.5,6,2),(row,80,6,3),
            (pulldown,75,10,0),(pulldown,75,9,1),(pulldown,72.5,10,2),
            (cableRow,62.5,12,0),(cableRow,62.5,11,1),(cableRow,60,12,2),
            (bicepCurl,45,10,0),(bicepCurl,45,9,1),(bicepCurl,42.5,10,2)
        ])
        addSession(templateId: legs.id, daysAgo: 31, feeling: 3, sets: [
            (squat,105,5,0),(squat,105,5,1),(squat,102.5,5,2),(squat,100,4,3),
            (rdl,122.5,6,0),(rdl,122.5,5,1),(rdl,120,6,2),
            (legPress,165,10,0),(legPress,165,9,1),(legPress,160,10,2),
            (calfRaise,82.5,15,0),(calfRaise,82.5,15,1),(calfRaise,80,15,2)
        ])
        // Week 3
        addSession(templateId: push.id, daysAgo: 28, feeling: 4, sets: [
            (bench,100,5,0),(bench,100,5,1),(bench,97.5,5,2),(bench,95,4,3),
            (inclineDB,35,10,0),(inclineDB,35,10,1),(inclineDB,32.5,9,2),
            (ohp,67.5,6,0),(ohp,67.5,5,1),(ohp,65,6,2),
            (tricepPD,45,12,0),(tricepPD,45,11,1),(tricepPD,42.5,12,2),
            (lateralR,17.5,15,0),(lateralR,17.5,14,1),(lateralR,15,15,2)
        ])
        addSession(templateId: pull.id, daysAgo: 26, feeling: 5, sets: [
            (row,87.5,6,0),(row,87.5,6,1),(row,85,6,2),(row,82.5,6,3),
            (pulldown,77.5,10,0),(pulldown,77.5,10,1),(pulldown,75,10,2),
            (cableRow,65,12,0),(cableRow,65,12,1),(cableRow,62.5,11,2),
            (bicepCurl,47.5,10,0),(bicepCurl,47.5,10,1),(bicepCurl,45,9,2)
        ])
        addSession(templateId: legs.id, daysAgo: 24, feeling: 4, sets: [
            (squat,107.5,5,0),(squat,107.5,5,1),(squat,105,5,2),(squat,102.5,5,3),
            (rdl,125,6,0),(rdl,125,6,1),(rdl,122.5,5,2),
            (legPress,170,10,0),(legPress,170,10,1),(legPress,165,9,2),
            (calfRaise,85,15,0),(calfRaise,85,15,1),(calfRaise,82.5,14,2)
        ])
        // Week 4 (most recent)
        addSession(templateId: push.id, daysAgo: 14, feeling: 5, sets: [
            (bench,102.5,5,0),(bench,102.5,5,1),(bench,100,5,2),(bench,97.5,5,3),
            (inclineDB,37.5,10,0),(inclineDB,37.5,10,1),(inclineDB,35,9,2),
            (ohp,70,5,0),(ohp,70,5,1),(ohp,67.5,5,2),
            (tricepPD,47.5,12,0),(tricepPD,47.5,11,1),(tricepPD,45,12,2),
            (lateralR,20,14,0),(lateralR,20,13,1),(lateralR,17.5,14,2)
        ])
        addSession(templateId: pull.id, daysAgo: 12, feeling: 5, sets: [
            (row,90,6,0),(row,90,6,1),(row,87.5,6,2),(row,85,6,3),
            (pulldown,80,10,0),(pulldown,80,10,1),(pulldown,77.5,9,2),
            (cableRow,67.5,12,0),(cableRow,67.5,12,1),(cableRow,65,11,2),
            (bicepCurl,50,10,0),(bicepCurl,50,9,1),(bicepCurl,47.5,10,2)
        ])
        addSession(templateId: legs.id, daysAgo: 10, feeling: 4, sets: [
            (squat,110,5,0),(squat,110,5,1),(squat,107.5,5,2),(squat,105,4,3),
            (rdl,127.5,6,0),(rdl,127.5,5,1),(rdl,125,6,2),
            (legPress,175,10,0),(legPress,175,9,1),(legPress,170,10,2),
            (calfRaise,87.5,15,0),(calfRaise,87.5,15,1),(calfRaise,85,14,2)
        ])

        allEntries.forEach { modelContext.insert($0) }

        // Update last performed dates
        push.lastPerformedDate = cal.date(byAdding: .day, value: -14, to: now)
        pull.lastPerformedDate = cal.date(byAdding: .day, value: -12, to: now)
        legs.lastPerformedDate = cal.date(byAdding: .day, value: -10, to: now)

        try? modelContext.save()
    }
}
