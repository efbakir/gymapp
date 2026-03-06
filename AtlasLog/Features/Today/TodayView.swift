//
//  TodayView.swift
//  AtlasLog
//
//  Home: Adaptive context card (training day / rest day / no cycle) + day cards for quick start.
//

import Charts
import SwiftUI
import SwiftData

// MARK: - HomeContext

enum HomeContext {
    case trainingDay(weekNumber: Int, templateName: String, targets: [ExerciseTarget])
    case restDay(nextSession: String, streakCount: Int, weeklyTonnage: [DayTonnage])
    case noCycle
}

struct ExerciseTarget {
    let exerciseName: String
    let weightKg: Double
    let reps: Int
    let deltaKg: Double  // +/- vs. prior week
}

struct DayTonnage: Identifiable {
    let id = UUID()
    let dayLabel: String   // "M", "T", "W" …
    let tonnage: Double    // kg × reps
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
        case .restDay(let next, let streak, let tonnage):
            RestDayCard(nextSession: next, streakCount: streak, weeklyTonnage: tonnage)
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
                    Text("Week \(weekNumber) of 8  ·  Training Day")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    Text(templateName)
                        .font(AtlasTheme.Typography.hero)
                }
                Spacer(minLength: 0)
                Button(action: onStart) {
                    Label("Start", systemImage: "play.circle.fill")
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
                    HStack {
                        Text(target.exerciseName)
                            .font(AtlasTheme.Typography.body)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if target.deltaKg != 0 {
                            Text(target.deltaKg > 0 ? "+\(target.deltaKg.weightString)kg" : "\(target.deltaKg.weightString)kg")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(target.deltaKg > 0 ? AtlasTheme.Colors.accent : AtlasTheme.Colors.ghostText)
                        }
                        Text("\(target.weightKg.weightString)kg × \(target.reps)")
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(AtlasTheme.Colors.ghostText)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue("Target: \(target.weightKg.weightString)kg × \(target.reps) reps")
                }
            }
        }
        .atlasCardStyle()
    }
}

// MARK: - Rest Day Card

private struct RestDayCard: View {
    let nextSession: String
    let streakCount: Int
    let weeklyTonnage: [DayTonnage]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                    Text("Recovery Mode")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    Text("Next: \(nextSession)")
                        .font(AtlasTheme.Typography.hero)
                }
                Spacer(minLength: 0)
                if streakCount > 0 {
                    VStack(alignment: .trailing, spacing: AtlasTheme.Spacing.xxs) {
                        Text("\(streakCount)")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(AtlasTheme.Colors.accent)
                        Text("streak")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                }
            }

            if !weeklyTonnage.isEmpty {
                Divider()
                Chart(weeklyTonnage) { day in
                    BarMark(
                        x: .value("Day", day.dayLabel),
                        y: .value("Tonnage (kg)", day.tonnage)
                    )
                    .foregroundStyle(AtlasTheme.Colors.accent.opacity(0.7))
                    .cornerRadius(4)
                }
                .frame(height: 60)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                }
                .chartYAxis(.hidden)
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
            Text("Start an 8-week cycle in the Cycles tab to unlock auto-progression targets.")
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

        // Find the template for today based on the split order
        let templateForToday: DayTemplate? = {
            guard let split = templates.first(where: { $0.splitId == cycle.splitId }) else { return nil }
            // Completed sessions this cycle in order
            let cycleSessionCount = sessions.filter { $0.cycleId == cycle.id }.count
            let templateIds = templates
                .filter { $0.splitId == cycle.splitId }
                .map { $0.id }
            if templateIds.isEmpty { return nil }
            let idx = cycleSessionCount % templateIds.count
            return templates.first { $0.id == templateIds[idx] }
        }()

        // Build exercise targets from engine
        let targets: [ExerciseTarget] = {
            guard let template = templateForToday else { return [] }
            return template.orderedExerciseIds.compactMap { exId -> ExerciseTarget? in
                guard let exercise = exercises.first(where: { $0.id == exId }),
                      let rule = rules.first(where: { $0.exerciseId == exId && $0.cycleId == cycle.id }) else {
                    return nil
                }
                let snapshot = rule.snapshot(weekCount: cycle.weekCount)
                let outcomes = rule.buildOutcomes(from: sessions)
                let allTargets = ProgressionEngine.computeTargets(rule: snapshot, outcomes: outcomes)
                guard let weekTarget = allTargets.first(where: { $0.weekNumber == weekNum }) else { return nil }
                let prevTarget = allTargets.first(where: { $0.weekNumber == weekNum - 1 })
                let delta = prevTarget.map { weekTarget.weightKg - $0.weightKg } ?? 0
                return ExerciseTarget(
                    exerciseName: exercise.displayName,
                    weightKg: weekTarget.weightKg,
                    reps: weekTarget.reps,
                    deltaKg: delta
                )
            }
        }()

        if templateForToday != nil {
            return .trainingDay(
                weekNumber: weekNum,
                templateName: templateForToday?.name ?? "Workout",
                targets: targets
            )
        }

        // Rest day fallback
        let streak = currentStreak(in: sessions)
        let tonnage = weeklyTonnage(sessions: sessions)
        let nextName = templates.first?.name ?? "Next Session"
        return .restDay(nextSession: nextName, streakCount: streak, weeklyTonnage: tonnage)
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

    // MARK: - Private helpers

    private func currentStreak(in sessions: [WorkoutSession]) -> Int {
        let completed = sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
        var streak = 0
        var lastDate: Date?
        for session in completed {
            if let last = lastDate {
                let days = Calendar.current.dateComponents([.day], from: session.date, to: last).day ?? 99
                if days > 3 { break }
            }
            streak += 1
            lastDate = session.date
        }
        return streak
    }

    private func weeklyTonnage(sessions: [WorkoutSession]) -> [DayTonnage] {
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        // Single pass: build day → tonnage dictionary
        var tonnageByDay: [Date: Double] = [:]
        for session in sessions where session.isCompleted {
            let day = cal.startOfDay(for: session.date)
            let t = session.setEntries.filter(\.isCompleted).reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            tonnageByDay[day, default: 0] += t
        }

        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            return DayTonnage(dayLabel: dayLabels[offset], tonnage: tonnageByDay[cal.startOfDay(for: day)] ?? 0)
        }
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
