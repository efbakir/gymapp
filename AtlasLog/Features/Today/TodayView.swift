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
    case trainingDay(weekNumber: Int, templateName: String, targets: [ExerciseTarget])
    case restDay(nextSession: String, nextSessionTiming: String, wins: [SessionWin])
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

struct SessionWin {
    let exerciseName: String
    let deltaKg: Double
}

// MARK: - TodayView

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var cycles: [Cycle]
    @Query private var rules: [ProgressionRule]

    @StateObject private var viewModel = TodayDashboardViewModel()

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    private var activeCycle: Cycle? {
        cycles.first(where: { $0.isActive && !$0.isCompleted })
    }

    private var orderedTemplates: [DayTemplate] {
        var ordered: [DayTemplate] = []
        let templateByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        for split in splits {
            for templateID in split.orderedTemplateIds {
                if let template = templateByID[templateID], !ordered.contains(where: { $0.id == template.id }) {
                    ordered.append(template)
                }
            }
        }
        let remaining = templates
            .filter { template in !ordered.contains(where: { $0.id == template.id }) }
            .sorted { $0.name < $1.name }
        return ordered + remaining
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
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                // Context card
                contextCard

                if !orderedTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        Text("Quick Start")
                            .font(AtlasTheme.Typography.sectionTitle)
                            .padding(.top, AtlasTheme.Spacing.xs)
                        Text("Tap a day to begin instantly.")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }

                    ForEach(orderedTemplates, id: \.id) { template in
                        let session = viewModel.lastCompletedSession(for: template.id, in: sessions)
                        DayCardView(
                            title: template.name,
                            splitName: viewModel.splitName(for: template, in: splits),
                            lastPerformed: viewModel.lastPerformedLabel(date: session?.date),
                            topLift: viewModel.topLiftSummary(from: session, exercises: exercises)
                        ) {
                            startWorkout(template)
                        }
                    }
                } else {
                    Text("No day templates yet. Build your split in Program.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, AtlasTheme.Spacing.xl)
                }
            }
            .padding(AtlasTheme.Spacing.md)
        }
        .background(AtlasTheme.Colors.background)
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
        case .trainingDay(let week, let name, let targets):
            TrainingDayCard(weekNumber: week, templateName: name, targets: targets) {
                if let template = templates.first(where: { $0.name == name }) {
                    startWorkout(template)
                }
            }
        case .restDay(let next, let timing, let wins):
            RestDayCard(nextSession: next, nextSessionTiming: timing, wins: wins)
        case .noCycle:
            NoCycleCard()
        }
    }

    // MARK: - Actions

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
    let targets: [ExerciseTarget]
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                    Text("Compared to last \(templateName)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    Text(templateName)
                        .font(AtlasTheme.Typography.hero)
                }
                Spacer(minLength: 0)
                Button(action: onStart) {
                    Label("Start Session", systemImage: "play.circle.fill")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .frame(height: 44)
                        .background(AtlasTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if !targets.isEmpty {
                Divider()
                ForEach(targets.prefix(3), id: \.exerciseName) { target in
                    ExerciseTargetRow(target: target)
                }
            }
        }
        .atlasCardStyle()
    }
}

private struct ExerciseTargetRow: View {
    let target: ExerciseTarget

    var body: some View {
        HStack(alignment: .top, spacing: AtlasTheme.Spacing.xs) {
            Text(target.exerciseName)
                .font(AtlasTheme.Typography.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                if let lastKg = target.lastWeightKg, let lastReps = target.lastReps {
                    Text("Last: \(lastKg.weightString)kg × \(lastReps)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .monospacedDigit()
                }
                HStack(spacing: AtlasTheme.Spacing.xxs) {
                    Text("Today: \(target.weightKg.weightString)kg × \(target.reps)")
                        .font(AtlasTheme.Typography.body)
                        .monospacedDigit()
                    if target.deltaKg > 0 {
                        Text("+\(target.deltaKg.weightString)kg")
                            .font(AtlasTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(AtlasTheme.Colors.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AtlasTheme.Colors.accentSoft)
                            .clipShape(Capsule())
                    } else if target.lastWeightKg != nil && target.deltaKg == 0 {
                        Text("=")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue({
            if let lastKg = target.lastWeightKg {
                return "Last: \(lastKg.weightString)kg. Today: \(target.weightKg.weightString)kg × \(target.reps) reps"
            }
            return "Today: \(target.weightKg.weightString)kg × \(target.reps) reps, first session"
        }())
    }
}

// MARK: - Rest Day Card

private struct RestDayCard: View {
    let nextSession: String
    let nextSessionTiming: String
    let wins: [SessionWin]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                    Text("Rest Day")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    Text(nextSession)
                        .font(AtlasTheme.Typography.hero)
                    Text(nextSessionTiming)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            if !wins.isEmpty {
                Divider()
                Text("Last session wins")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                ForEach(wins.prefix(3), id: \.exerciseName) { win in
                    HStack {
                        Text("+\(win.deltaKg.weightString)kg")
                            .font(AtlasTheme.Typography.body.weight(.semibold))
                            .foregroundStyle(AtlasTheme.Colors.accent)
                            .monospacedDigit()
                        Text("·  \(win.exerciseName)")
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue("+\(win.deltaKg.weightString)kg on \(win.exerciseName)")
                }
            }
        }
        .atlasCardStyle()
    }
}

// MARK: - No Cycle Card

private struct NoCycleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
            Text("No Active Cycle")
                .font(AtlasTheme.Typography.sectionTitle)
            Text("Go to Program → tap the calendar icon to start an 8-week cycle and unlock auto-progression targets.")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
        }
        .atlasCardStyle()
    }
}

// MARK: - Day Card

private struct DayCardView: View {
    let title: String
    let splitName: String
    let lastPerformed: String
    let topLift: String
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        Text(title)
                            .font(AtlasTheme.Typography.sectionTitle)
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                        Text(splitName)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AtlasTheme.Colors.accent)
                }
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        Text("Last performed")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Text(lastPerformed)
                            .font(AtlasTheme.Typography.body)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: AtlasTheme.Spacing.xxs) {
                        Text("Top lift")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Text(topLift)
                            .font(AtlasTheme.Typography.body)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
            .atlasCardStyle()
        }
        .buttonStyle(AtlasScaleButtonStyle())
        .accessibilityHint("Starts workout with one tap")
    }
}

// MARK: - ViewModel

@MainActor
final class TodayDashboardViewModel: ObservableObject {

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

        // Find the template for today based on completed sessions in this cycle
        let templateForToday: DayTemplate? = {
            guard !splitTemplates.isEmpty else { return nil }
            let cycleSessionCount = sessions.filter { $0.cycleId == cycle.id && $0.isCompleted }.count
            let templateIds = splitTemplates.map { $0.id }
            let idx = cycleSessionCount % templateIds.count
            return templates.first { $0.id == templateIds[idx] }
        }()

        guard let template = templateForToday else {
            return restDayContext(sessions: sessions, templates: templates, exercises: exercises)
        }

        // Last completed session for this same template (to show "Last: Xkg × N")
        let lastSession = sessions.first { $0.templateId == template.id && $0.isCompleted }

        // Build per-exercise targets using ProgressionEngine
        let targets: [ExerciseTarget] = template.orderedExerciseIds.compactMap { exId -> ExerciseTarget? in
            guard let exercise = exercises.first(where: { $0.id == exId }),
                  let rule = rules.first(where: { $0.exerciseId == exId && $0.cycleId == cycle.id }) else {
                return nil
            }
            let snapshot = rule.snapshot(weekCount: cycle.weekCount)
            let outcomes = rule.buildOutcomes(from: sessions)
            let allTargets = ProgressionEngine.computeTargets(rule: snapshot, outcomes: outcomes)
            guard let weekTarget = allTargets.first(where: { $0.weekNumber == weekNum }) else { return nil }

            // Best set for this exercise from last same-template session
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

        return .trainingDay(weekNumber: weekNum, templateName: template.name, targets: targets)
    }

    private func restDayContext(
        sessions: [WorkoutSession],
        templates: [DayTemplate],
        exercises: [Exercise]
    ) -> HomeContext {
        let nextName = templates.first?.name ?? "Next Session"

        let nextSessionTiming: String = {
            guard let last = sessions.first(where: { $0.isCompleted })?.date else { return "Tomorrow" }
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return daysSince >= 1 ? "Tomorrow" : "Today later"
        }()

        // Compare last two sessions of the same template for wins
        let wins: [SessionWin] = {
            guard let lastSession = sessions.first(where: { $0.isCompleted }) else { return [] }
            guard let prevSession = sessions.first(where: {
                $0.isCompleted && $0.templateId == lastSession.templateId && $0.id != lastSession.id
            }) else { return [] }

            let prevBestByExercise: [UUID: Double] = Dictionary(
                prevSession.setEntries
                    .filter { $0.isCompleted && !$0.isWarmup }
                    .map { ($0.exerciseId, $0.weight) },
                uniquingKeysWith: max
            )

            return lastSession.setEntries
                .filter { $0.isCompleted && !$0.isWarmup }
                .compactMap { entry -> SessionWin? in
                    guard let prevWeight = prevBestByExercise[entry.exerciseId] else { return nil }
                    let delta = entry.weight - prevWeight
                    guard delta > 0 else { return nil }
                    let name = exercises.first(where: { $0.id == entry.exerciseId })?.displayName ?? "Exercise"
                    return SessionWin(exerciseName: name, deltaKg: delta)
                }
                .sorted { $0.deltaKg > $1.deltaKg }
        }()

        return .restDay(nextSession: nextName, nextSessionTiming: nextSessionTiming, wins: wins)
    }

    func splitName(for template: DayTemplate, in splits: [Split]) -> String {
        guard let splitID = template.splitId,
              let split = splits.first(where: { $0.id == splitID }) else { return "Custom Split" }
        return split.name
    }

    func lastCompletedSession(for templateID: UUID, in sessions: [WorkoutSession]) -> WorkoutSession? {
        sessions.first { $0.templateId == templateID && $0.isCompleted }
    }

    func lastPerformedLabel(date: Date?) -> String {
        guard let date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func topLiftSummary(from session: WorkoutSession?, exercises: [Exercise]) -> String {
        guard let session else { return "No data" }
        let candidate = session.setEntries
            .filter { $0.isCompleted }
            .max { lhs, rhs in
                lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight
            }
        guard let entry = candidate else { return "No data" }
        let name = exercises.first(where: { $0.id == entry.exerciseId })?.displayName ?? "Lift"
        let shortName = name.components(separatedBy: " ").prefix(2).joined(separator: " ")
        return "\(shortName): \(entry.weight.weightString)kg × \(entry.reps)"
    }
}

// MARK: - Button Style

private struct AtlasScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
