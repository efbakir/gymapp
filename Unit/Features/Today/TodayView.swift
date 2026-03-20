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
    case trainingDay(TrainingDayContext)
    case restDay(RestDayContext)
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

struct TrainingDayContext {
    let headerTitle: String
    let headerSubtitle: String
    let weekNumber: Int
    let weekCount: Int
    let templateName: String
    let targets: [ExerciseTarget]
    let lastSessionDate: Date?
    let cycleName: String
}

struct RestDayContext {
    let headerTitle: String
    let headerSubtitle: String
    let nextTemplateName: String
    let nextTimingLabel: String
    let lastSessionSummary: String?
    let weekNumber: Int
    let weekCount: Int
    let cycleName: String
    let nextTargets: [ExerciseTarget]
}

// MARK: - TodayView

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTabSelection) private var appTabSelection
    @AppStorage("pendingFeelingSessionId") private var pendingFeelingSessionId = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var cycles: [Cycle]
    @Query private var rules: [ProgressionRule]

    @State private var viewModel = TodayDashboardViewModel()
    @State private var trainingTargetsSheet: TrainingTargetsSheetPayload?
    @State private var feelingPromptPayload: FeelingPromptPayload?
    @State private var showingHistory = false

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    private var activeCycle: Cycle? {
        cycles.first(where: { $0.isActive && !$0.isCompleted })
            ?? cycles.first(where: { !$0.isCompleted })
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
            .sheet(item: $trainingTargetsSheet) { payload in
                TrainingTargetsSheet(templateName: payload.templateName, cycleName: payload.cycleName, targets: payload.targets)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.cardBackground)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(showsCloseButton: true)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.cardBackground)
            }
            .sheet(item: $feelingPromptPayload) { payload in
                PostWorkoutFeelingPrompt(session: payload.session) {
                    pendingFeelingSessionId = ""
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.cardBackground)
            }
            .toolbar(activeSession == nil ? .visible : .hidden, for: .tabBar)
            .tint(AppColor.accent)
            .onAppear {
                presentPendingFeelingPromptIfNeeded()
            }
            .onChange(of: sessions.count) { _, _ in
                presentPendingFeelingPromptIfNeeded()
            }
        }
    }

    private var dashboardContent: some View {
        let ctx = viewModel.currentCycleContext(
            activeCycle: activeCycle,
            rules: rules,
            sessions: sessions,
            templates: templates,
            splits: splits,
            exercises: exercises
        )
        return AppScreen(
            title: "Home",
            trailingText: NavTextAction(label: "History", action: { showingHistory = true })
        ) {
            if hasCompletedOnboarding {
                welcomeBlock(for: ctx)
            }
            contextHeader(for: ctx)
            contextCard(ctx: ctx)
        }
    }

    @ViewBuilder
    private func welcomeBlock(for ctx: HomeContext) -> some View {
        let cycleName: String? = switch ctx {
        case .trainingDay(let payload): payload.cycleName
        case .restDay(let payload): payload.cycleName
        case .noCycle: nil
        }

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Welcome back")
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)

            if let cycleName, !cycleName.isEmpty {
                Text(cycleName)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                Text("Your next training decisions live here.")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func contextHeader(for ctx: HomeContext) -> some View {
        switch ctx {
        case .trainingDay(let payload):
            HeaderBlock(title: payload.headerTitle, subtitle: payload.headerSubtitle)
        case .restDay(let payload):
            HeaderBlock(title: payload.headerTitle, subtitle: payload.headerSubtitle)
        case .noCycle:
            EmptyView()
        }
    }

    // MARK: - Context Card
    @ViewBuilder
    private func contextCard(ctx: HomeContext) -> some View {
        switch ctx {
        case .trainingDay(let payload):
            TrainingDayCard(
                weekNumber: payload.weekNumber,
                weekCount: payload.weekCount,
                templateName: payload.templateName,
                cycleName: payload.cycleName,
                targets: payload.targets,
                lastSessionDate: payload.lastSessionDate,
                onStart: { startWorkout(named: payload.templateName) },
                onOpenDetails: {
                    trainingTargetsSheet = TrainingTargetsSheetPayload(
                        templateName: payload.templateName,
                        cycleName: payload.cycleName,
                        targets: payload.targets
                    )
                }
            )
        case .restDay(let payload):
            RestDayCard(
                nextSession: payload.nextTemplateName,
                nextSessionTiming: payload.nextTimingLabel,
                lastSessionSummary: payload.lastSessionSummary,
                onOpenDetails: {
                    trainingTargetsSheet = TrainingTargetsSheetPayload(
                        templateName: payload.nextTemplateName,
                        cycleName: payload.cycleName,
                        targets: payload.nextTargets
                    )
                }
            )
        case .noCycle:
            NoCycleCard {
                appTabSelection(.program)
            }
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

    private func presentPendingFeelingPromptIfNeeded() {
        guard activeSession == nil else { return }
        guard !pendingFeelingSessionId.isEmpty else { return }
        guard let sessionID = UUID(uuidString: pendingFeelingSessionId) else {
            pendingFeelingSessionId = ""
            return
        }
        guard let session = sessions.first(where: { $0.id == sessionID && $0.isCompleted }) else { return }
        feelingPromptPayload = FeelingPromptPayload(session: session)
    }
}

// MARK: - Training Day Card

private struct HeaderBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.largeTitle.font)
                .foregroundStyle(AppColor.textPrimary)
            Text(subtitle)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TrainingDayCard: View {
    let weekNumber: Int
    let weekCount: Int
    let templateName: String
    let cycleName: String
    let targets: [ExerciseTarget]
    let lastSessionDate: Date?
    let onStart: () -> Void
    let onOpenDetails: () -> Void

    private var subtitleLabel: String {
        guard let date = lastSessionDate else { return "First session" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "Last: \(fmt.string(from: date))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Button(action: onOpenDetails) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("Week \(weekNumber) of \(weekCount)")
                            .font(AppFont.caption.font.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        if !cycleName.isEmpty {
                            Text("·")
                                .foregroundStyle(AppColor.textSecondary)
                            Text(cycleName)
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(templateName)
                            .font(AppFont.largeTitle.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(subtitleLabel)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    if !targets.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            ForEach(Array(targets.prefix(2).enumerated()), id: \.offset) { _, target in
                                ExerciseTargetRow(target: target)
                            }
                            if targets.count > 2 {
                                Text("+\(targets.count - 2) more exercises")
                                    .font(AppFont.caption.font.weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                    .padding(.top, AppSpacing.xs)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            AppPrimaryButton("Start Session", action: onStart)
        }
        .appCardStyle()
    }
}

private struct ExerciseTargetRow: View {
    let target: ExerciseTarget

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            // Exercise name
            Text(target.exerciseName)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: last row + today row
            VStack(alignment: .trailing, spacing: 2) {
                // Last + delta on one line
                if let lastKg = target.lastWeightKg, let lastReps = target.lastReps {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Last \(lastKg.weightString) × \(lastReps)")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .monospacedDigit()
                        if target.deltaKg > 0 {
                            Text("+\(target.deltaKg.weightString)kg")
                                .font(AppFont.overline)
                                .foregroundStyle(AppColor.success)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppColor.success.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                // Today target
                Text("\(target.weightKg.weightString)kg × \(target.reps)")
                    .font(AppFont.body.font.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TrainingTargetsSheetPayload: Identifiable {
    let id = UUID()
    let templateName: String
    let cycleName: String
    let targets: [ExerciseTarget]
}

private struct FeelingPromptPayload: Identifiable {
    let id = UUID()
    let session: WorkoutSession
}

private struct TrainingTargetsSheet: View {
    let templateName: String
    let cycleName: String
    let targets: [ExerciseTarget]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AppScreen(
                title: "All Exercises",
                leadingAction: NavAction(icon: .back, action: { dismiss() })
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(templateName)
                        .font(AppFont.largeTitle.font)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(cycleName)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle()

                if targets.isEmpty {
                    Text("No exercises set for this day yet.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCardStyle()
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(targets, id: \.exerciseName) { target in
                            ExerciseTargetRow(target: target)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCardStyle()
                }
            }
        }
    }
}

private struct PostWorkoutFeelingPrompt: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text("How did the workout feel?")
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)

                HStack(spacing: AppSpacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            try? modelContext.save()
                            onDismiss()
                            dismiss()
                        }
                        .font(AppFont.sectionHeader.font)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? AppColor.accent : AppColor.cardBackground)
                        .foregroundStyle(session.overallFeeling == value ? .white : AppColor.textPrimary)
                        .clipShape(Circle())
                    }
                }

                Button("Skip") {
                    onDismiss()
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Optional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                onDismiss()
            }
        }
    }
}

// MARK: - Rest Day Card

private struct RestDayCard: View {
    let nextSession: String
    let nextSessionTiming: String
    let lastSessionSummary: String?
    let onOpenDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Today is a rest day")
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)

            Text("Next: \(nextSession) \(nextSessionTiming)")
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)

            if let lastSessionSummary {
                Text(lastSessionSummary)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }

            AppPrimaryButton("View Next Session") {
                onOpenDetails()
            }
        }
        .appCardStyle()
    }
}

// MARK: - No Cycle Card

private struct NoCycleCard: View {
    let onGoToProgram: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("NO ACTIVE CYCLE")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(AppColor.textSecondary)
            Text("Set up your program")
                .font(AppFont.largeTitle.font)
                .foregroundStyle(AppColor.textPrimary)
            Text("Create a split, add exercises, and start an 8-week cycle to unlock auto-progression targets.")
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .lineSpacing(3)
                .padding(.bottom, AppSpacing.sm)
            AppPrimaryButton("Go to Program") {
                onGoToProgram()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
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
        splits: [Split],
        exercises: [Exercise]
    ) -> HomeContext {
        guard let cycle = activeCycle else { return .noCycle }
        let orderedTemplates = orderedTemplates(for: cycle, templates: templates, splits: splits)
        guard !orderedTemplates.isEmpty else { return .noCycle }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cycleStart = calendar.startOfDay(for: cycle.startDate)
        let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: today).day ?? 0
        let effectiveOffset = max(daysSinceStart, 0)
        let trainingDaysPerWeek = min(max(orderedTemplates.count, 1), 6)

        // Failed/missed planned day has priority over today's normal state.
        if daysSinceStart >= 1,
           let yesterdayTemplate = plannedTemplate(
            atDayOffset: daysSinceStart - 1,
            templates: orderedTemplates,
            trainingDaysPerWeek: trainingDaysPerWeek
           ) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            let didCompleteYesterday = sessions.contains {
                $0.isCompleted
                && $0.templateId == yesterdayTemplate.id
                && calendar.isDate($0.date, inSameDayAs: yesterday)
            }
            if !didCompleteYesterday {
                return .trainingDay(
                    TrainingDayContext(
                        headerTitle: "Ready when you are",
                        headerSubtitle: "\(yesterdayTemplate.name) was planned for yesterday",
                        weekNumber: cycle.currentWeekNumber,
                        weekCount: cycle.weekCount,
                        templateName: yesterdayTemplate.name,
                        targets: targets(
                            for: yesterdayTemplate,
                            cycle: cycle,
                            rules: rules,
                            sessions: sessions,
                            exercises: exercises
                        ),
                        lastSessionDate: lastCompletedDate(for: yesterdayTemplate.id, sessions: sessions),
                        cycleName: cycle.name
                    )
                )
            }
        }

        // Training day
        if let todayTemplate = plannedTemplate(
            atDayOffset: effectiveOffset,
            templates: orderedTemplates,
            trainingDaysPerWeek: trainingDaysPerWeek
        ) {
            return .trainingDay(
                TrainingDayContext(
                    headerTitle: "Good morning, Joanna",
                    headerSubtitle: "\(todayTemplate.name) today",
                    weekNumber: cycle.currentWeekNumber,
                    weekCount: cycle.weekCount,
                    templateName: todayTemplate.name,
                    targets: targets(
                        for: todayTemplate,
                        cycle: cycle,
                        rules: rules,
                        sessions: sessions,
                        exercises: exercises
                    ),
                    lastSessionDate: lastCompletedDate(for: todayTemplate.id, sessions: sessions),
                    cycleName: cycle.name
                )
            )
        }

        // Rest / future day states
        guard let nextPlanned = nextPlannedTemplate(
            fromDayOffset: effectiveOffset,
            templates: orderedTemplates,
            trainingDaysPerWeek: trainingDaysPerWeek
        ) else {
            return .noCycle
        }

        let nextDate = calendar.date(byAdding: .day, value: nextPlanned.dayOffset - effectiveOffset, to: today) ?? today
        let nextTiming = relativeDayLabel(from: today, to: nextDate)
        let isTomorrow = calendar.isDate(nextDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today) ?? today)
        let lastSummary = lastSessionSummary(sessions: sessions, templates: templates)

        if isTomorrow {
            return .restDay(
                RestDayContext(
                    headerTitle: "Tomorrow",
                    headerSubtitle: "\(nextPlanned.template.name) is next",
                    nextTemplateName: nextPlanned.template.name,
                    nextTimingLabel: nextTiming,
                    lastSessionSummary: lastSummary,
                    weekNumber: cycle.currentWeekNumber,
                    weekCount: cycle.weekCount,
                    cycleName: cycle.name,
                    nextTargets: targets(
                        for: nextPlanned.template,
                        cycle: cycle,
                        rules: rules,
                        sessions: sessions,
                        exercises: exercises
                    )
                )
            )
        }

        return .restDay(
            RestDayContext(
                headerTitle: "Rest day",
                headerSubtitle: "Next session: \(nextPlanned.template.name) \(nextTiming)",
                nextTemplateName: nextPlanned.template.name,
                nextTimingLabel: nextTiming,
                lastSessionSummary: lastSummary,
                weekNumber: cycle.currentWeekNumber,
                weekCount: cycle.weekCount,
                cycleName: cycle.name,
                nextTargets: targets(
                    for: nextPlanned.template,
                    cycle: cycle,
                    rules: rules,
                    sessions: sessions,
                    exercises: exercises
                )
            )
        )
    }

    private func orderedTemplates(for cycle: Cycle, templates: [DayTemplate], splits: [Split]) -> [DayTemplate] {
        let splitTemplates = templates.filter { $0.splitId == cycle.splitId }
        guard let split = splits.first(where: { $0.id == cycle.splitId }) else {
            return splitTemplates.sorted { $0.name < $1.name }
        }
        let map = Dictionary(uniqueKeysWithValues: splitTemplates.map { ($0.id, $0) })
        let ordered = split.orderedTemplateIds.compactMap { map[$0] }
        return ordered.isEmpty ? splitTemplates.sorted { $0.name < $1.name } : ordered
    }

    private func plannedTemplate(
        atDayOffset dayOffset: Int,
        templates: [DayTemplate],
        trainingDaysPerWeek: Int
    ) -> DayTemplate? {
        guard dayOffset >= 0, !templates.isEmpty else { return nil }
        let week = dayOffset / 7
        let dayInWeek = dayOffset % 7
        guard dayInWeek < trainingDaysPerWeek else { return nil }
        let slotIndex = (week * trainingDaysPerWeek) + dayInWeek
        return templates[slotIndex % templates.count]
    }

    private func nextPlannedTemplate(
        fromDayOffset dayOffset: Int,
        templates: [DayTemplate],
        trainingDaysPerWeek: Int
    ) -> (template: DayTemplate, dayOffset: Int)? {
        guard !templates.isEmpty else { return nil }
        for step in 1...21 {
            let candidateOffset = dayOffset + step
            if let template = plannedTemplate(
                atDayOffset: candidateOffset,
                templates: templates,
                trainingDaysPerWeek: trainingDaysPerWeek
            ) {
                return (template, candidateOffset)
            }
        }
        return nil
    }

    private func targets(
        for template: DayTemplate,
        cycle: Cycle,
        rules: [ProgressionRule],
        sessions: [WorkoutSession],
        exercises: [Exercise]
    ) -> [ExerciseTarget] {
        let weekNum = cycle.currentWeekNumber
        let lastSession = sessions.first { $0.templateId == template.id && $0.isCompleted }

        return template.orderedExerciseIds.compactMap { exId -> ExerciseTarget? in
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
    }

    private func lastCompletedDate(for templateID: UUID, sessions: [WorkoutSession]) -> Date? {
        sessions.first { $0.isCompleted && $0.templateId == templateID }?.date
    }

    private func relativeDayLabel(from today: Date, to nextDate: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: today, to: nextDate).day ?? 0
        switch days {
        case ..<0:
            return "yesterday"
        case 0:
            return "today"
        case 1:
            return "tomorrow"
        default:
            return "in \(days) days"
        }
    }

    private func lastSessionSummary(sessions: [WorkoutSession], templates: [DayTemplate]) -> String? {
        guard let latest = sessions.first(where: { $0.isCompleted }) else { return nil }
        let name = templates.first(where: { $0.id == latest.templateId })?.name ?? "Session"
        return "Last session: \(name) completed"
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
