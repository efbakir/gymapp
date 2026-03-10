//
//  TodayView.swift
//  Unit
//
//  Home: Adaptive context card (training day / rest day / no cycle) + day cards for quick start.
//

import SwiftUI
import SwiftData

// MARK: - HomeContext

enum HomeContext {
    case trainingDay(weekNumber: Int, templateName: String, targets: [ExerciseTarget], lastSessionDate: Date?, cycleName: String)
    case restDay(nextSession: String, nextSessionTiming: String)
    case noCycle
}

struct ExerciseTarget {
    let exerciseName: String
    let weightKg: Double
    let reps: Int
    let deltaKg: Double       // today target minus last actual
    let lastWeightKg: Double? // actual from last same-template session
    let lastReps: Int?        // reps from last same-template session
}

// MARK: - TodayView

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var cycles: [Cycle]
    @Query private var rules: [ProgressionRule]

    @State private var viewModel = TodayDashboardViewModel()
    @State private var showSubscribe = false
    @State private var showHistory = false

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    private var activeCycle: Cycle? {
        cycles.first(where: { $0.isActive && !$0.isCompleted })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    ActiveWorkoutView(session: session)
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if activeSession == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSubscribe = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Subscribe")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .foregroundStyle(AtlasTheme.Colors.accent)
                            .frame(minWidth: 90, minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AtlasTheme.Colors.secondaryButton)
                        }
                        .accessibilityLabel("Open history")
                    }
                }
            }
            .sheet(isPresented: $showSubscribe) {
                SubscribeView()
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AtlasTheme.Colors.sheet)
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AtlasTheme.Colors.sheet)
            }
            .toolbar(activeSession == nil ? .visible : .hidden, for: .tabBar)
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                contextCard
            }
            .padding(AtlasTheme.Spacing.md)
        }
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
    }

    // MARK: - Context Card

    @ViewBuilder
    private var contextCard: some View {
        let ctx = viewModel.currentCycleContext(
            activeCycle: activeCycle,
            rules: rules,
            sessions: sessions,
            templates: templates,
            exercises: exercises
        )
        switch ctx {
        case .trainingDay(let week, let name, let targets, let lastDate, let cycleName):
            TrainingDayCard(weekNumber: week, templateName: name, cycleName: cycleName, targets: targets, lastSessionDate: lastDate) {
                startWorkout(named: name)
            }
        case .restDay(let next, let timing):
            RestDayCard(nextSession: next, nextSessionTiming: timing)
        case .noCycle:
            NoCycleCard()
        }
    }

    // MARK: - Actions

    private func startWorkout(named name: String) {
        guard let template = templates.first(where: { $0.name == name }) else { return }
        startWorkout(template)
    }

    private func startWorkout(_ template: DayTemplate) {
        let cycle = activeCycle
        let weekNum = cycle?.currentWeekNumber ?? 0
        let session = WorkoutSession(
            date: Date(),
            templateId: template.id,
            isCompleted: false,
            overallFeeling: 0,
            cycleId: cycle?.id,
            weekNumber: weekNum
        )
        modelContext.insert(session)
        template.lastPerformedDate = session.date
        try? modelContext.save()
    }
}

// MARK: - Training Day Card

private struct TrainingDayCard: View {
    let weekNumber: Int
    let templateName: String
    let cycleName: String
    let targets: [ExerciseTarget]
    let lastSessionDate: Date?
    let onStart: () -> Void

    private var subtitleLabel: String {
        guard let date = lastSessionDate else { return "First session" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "Last · \(fmt.string(from: date))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {

            // Cycle badge
            HStack(spacing: AtlasTheme.Spacing.xs) {
                Text("WEEK \(weekNumber) OF 8")
                    .font(AtlasTheme.Typography.overline)
                    .tracking(1.0)
                    .foregroundStyle(AtlasTheme.Colors.accent)
                Text("·")
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .font(AtlasTheme.Typography.overline)
                Text(cycleName.uppercased())
                    .font(AtlasTheme.Typography.overline)
                    .tracking(1.0)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            // Title row
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                Text(templateName)
                    .font(AtlasTheme.Typography.hero)
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                Text(subtitleLabel)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }

            // Targets
            if !targets.isEmpty {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text("TODAY'S TARGETS")
                        .font(AtlasTheme.Typography.overline)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .tracking(1.0)
                    ForEach(targets, id: \.exerciseName) { target in
                        ExerciseTargetRow(target: target)
                    }
                }
            }

            // Start button — full width at bottom of card
            Button(action: onStart) {
                Text("Start Session")
                    .atlasCTAStyle()
            }
            .buttonStyle(.plain)
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

private struct ExerciseTargetRow: View {
    let target: ExerciseTarget

    var body: some View {
        HStack(alignment: .center, spacing: AtlasTheme.Spacing.xs) {
            // Exercise name
            Text(target.exerciseName)
                .font(AtlasTheme.Typography.body)
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: last row + today row
            VStack(alignment: .trailing, spacing: 2) {
                // Last + delta on one line
                if let lastKg = target.lastWeightKg, let lastReps = target.lastReps {
                    HStack(spacing: AtlasTheme.Spacing.xxs) {
                        Text("Last \(lastKg.weightString) × \(lastReps)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .monospacedDigit()
                        if target.deltaKg > 0 {
                            Text("+\(target.deltaKg.weightString)kg")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AtlasTheme.Colors.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                }
                // Today target
                Text("\(target.weightKg.weightString)kg × \(target.reps)")
                    .font(AtlasTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rest Day Card

private struct RestDayCard: View {
    let nextSession: String
    let nextSessionTiming: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("REST DAY")
                .font(AtlasTheme.Typography.overline)
                .tracking(1.0)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            Text(nextSession)
                .font(AtlasTheme.Typography.hero)
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
            Text(nextSessionTiming)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
        }
        .atlasCardStyle()
    }
}

// MARK: - No Cycle Card

private struct NoCycleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("NO ACTIVE CYCLE")
                .font(AtlasTheme.Typography.overline)
                .tracking(1.0)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            Text("Set up your program")
                .font(AtlasTheme.Typography.hero)
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
            Text("Create a split, add exercises, and start an 8-week cycle to unlock auto-progression targets.")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                .lineSpacing(3)
                .padding(.bottom, AtlasTheme.Spacing.xs)
            NavigationLink {
                TemplatesView()
            } label: {
                Text("Go to Program")
                    .atlasCTAStyle()
            }
            .buttonStyle(.plain)
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class TodayDashboardViewModel {

    func currentCycleContext(
        activeCycle: Cycle?,
        rules: [ProgressionRule],
        sessions: [WorkoutSession],
        templates: [DayTemplate],
        exercises: [Exercise]
    ) -> HomeContext {
        guard let cycle = activeCycle else { return .noCycle }

        let weekNum = cycle.currentWeekNumber
        let splitTemplates = templates.filter { $0.splitId == cycle.splitId }

        let templateForToday: DayTemplate? = {
            guard !splitTemplates.isEmpty else { return nil }
            let cycleSessionCount = sessions.filter { $0.cycleId == cycle.id && $0.isCompleted }.count
            let templateIds = splitTemplates.map { $0.id }
            let idx = cycleSessionCount % templateIds.count
            return templates.first { $0.id == templateIds[idx] }
        }()

        guard let template = templateForToday else {
            return restDayContext(sessions: sessions, templates: templates)
        }

        let lastSession = sessions.first { $0.templateId == template.id && $0.isCompleted }

        let targets: [ExerciseTarget] = template.orderedExerciseIds.compactMap { exId -> ExerciseTarget? in
            guard let exercise = exercises.first(where: { $0.id == exId }),
                  let rule = rules.first(where: { $0.exerciseId == exId && $0.cycleId == cycle.id }) else {
                return nil
            }
            let snapshot = rule.snapshot(weekCount: cycle.weekCount)
            let outcomes = rule.buildOutcomes(from: sessions)
            let allTargets = ProgressionEngine.computeTargets(rule: snapshot, outcomes: outcomes)
            guard let weekTarget = allTargets.first(where: { $0.weekNumber == weekNum }) else { return nil }

            let lastSet = lastSession?.setEntries
                .filter { $0.exerciseId == exId && $0.isCompleted && !$0.isWarmup }
                .max { $0.weight < $1.weight }

            let deltaKg = lastSet.map { weekTarget.weightKg - $0.weight } ?? 0

            return ExerciseTarget(
                exerciseName: exercise.displayName,
                weightKg: weekTarget.weightKg,
                reps: weekTarget.reps,
                deltaKg: deltaKg,
                lastWeightKg: lastSet?.weight,
                lastReps: lastSet?.reps
            )
        }

        return .trainingDay(
            weekNumber: weekNum,
            templateName: template.name,
            targets: targets,
            lastSessionDate: lastSession?.date,
            cycleName: cycle.name
        )
    }

    private func restDayContext(
        sessions: [WorkoutSession],
        templates: [DayTemplate]
    ) -> HomeContext {
        let nextName = templates.first?.name ?? "Next Session"

        let nextSessionTiming: String = {
            guard let last = sessions.first(where: { $0.isCompleted })?.date else { return "Tomorrow" }
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return daysSince >= 1 ? "Tomorrow" : "Today later"
        }()

        return .restDay(nextSession: nextName, nextSessionTiming: nextSessionTiming)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
