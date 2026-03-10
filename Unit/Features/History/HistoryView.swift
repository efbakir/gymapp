//
//  HistoryView.swift
//  Unit
//
//  History tab: calendar heatmap + completed session list.
//

import Charts
import SwiftUI
import SwiftData

// MARK: - Day Cell State

private enum DayCellState {
    case none, completed, progressed, failed
}

// MARK: - Selected Day (for bottom sheet)

private struct SelectedDay: Identifiable {
    let id = UUID()
    let session: WorkoutSession
    let templateName: String
    let exercises: [Exercise]
}

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var showingAllPRs = false
    @State private var selectedDay: SelectedDay?

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    // Exercises that appear in at least one completed session
    private var activeExercises: [Exercise] {
        let usedIds = Set(completedSessions.flatMap { $0.setEntries.map(\.exerciseId) })
        return exercises.filter { usedIds.contains($0.id) }
    }

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return activeExercises }
        return activeExercises.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    // Top 5 PRs by weight
    private var topPRs: [(exercise: Exercise, weight: Double, reps: Int)] {
        let allSets = completedSessions.flatMap { $0.setEntries }
        var result: [(exercise: Exercise, weight: Double, reps: Int)] = []
        for exercise in activeExercises.prefix(10) {
            let best = allSets
                .filter { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup }
                .max { $0.weight == $1.weight ? $0.reps < $1.reps : $0.weight < $1.weight }
            if let best {
                result.append((exercise, best.weight, best.reps))
            }
        }
        return result.sorted { $0.weight > $1.weight }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let exercise = selectedExercise {
                    ExerciseProgressView(
                        exerciseId: exercise.id,
                        exerciseName: exercise.displayName,
                        sessions: completedSessions,
                        templates: templates
                    )
                } else {
                    mainList
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search exercises")
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty { selectedExercise = nil }
            }
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session, templateName: templateName(for: session.templateId))
            }
            .sheet(isPresented: $showingAllPRs) {
                PRLibraryView(sessions: completedSessions, exercises: exercises)
            }
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(day: day)
            }
        }
    }

    private var mainList: some View {
        List {
            if !searchText.isEmpty {
                // Exercise filter results
                Section("Exercises") {
                    if filteredExercises.isEmpty {
                        VStack(spacing: AtlasTheme.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            Text("No exercises found.")
                                .font(AtlasTheme.Typography.body)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AtlasTheme.Spacing.xl)
                    } else {
                        ForEach(filteredExercises, id: \.id) { exercise in
                            Button {
                                selectedExercise = exercise
                                searchText = ""
                            } label: {
                                HStack {
                                    Text(exercise.displayName)
                                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundStyle(AtlasTheme.Colors.accent)
                                }
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }
                .listRowBackground(AtlasTheme.Colors.elevatedBackground)
            } else {
                // Calendar heatmap
                Section {
                    CalendarHeatmap(sessions: completedSessions) { session in
                        let name = templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                        selectedDay = SelectedDay(session: session, templateName: name, exercises: exercises)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Inline top PRs
                if !topPRs.isEmpty {
                    Section {
                        ForEach(topPRs, id: \.exercise.id) { pr in
                            Button {
                                selectedExercise = pr.exercise
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pr.exercise.displayName)
                                            .font(AtlasTheme.Typography.body)
                                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                        Text("Best set")
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Text("\(pr.weight.weightString)kg × \(pr.reps)")
                                        .font(AtlasTheme.Typography.body)
                                        .foregroundStyle(AtlasTheme.Colors.accent)
                                        .monospacedDigit()
                                }
                                .frame(minHeight: 44)
                            }
                        }
                        Button {
                            showingAllPRs = true
                        } label: {
                            Text("See all personal records")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 44)
                        }
                    } header: {
                        Text("Personal Records")
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                }

                // Session list
                if completedSessions.isEmpty {
                    Section {
                        VStack(spacing: AtlasTheme.Spacing.sm) {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            Text("No completed sessions yet.")
                                .font(AtlasTheme.Typography.body)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AtlasTheme.Spacing.xl)
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                } else {
                    Section("Sessions") {
                        ForEach(completedSessions, id: \.id) { session in
                            NavigationLink(value: session) {
                                SessionRow(session: session, templateName: templateName(for: session.templateId))
                            }
                        }
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
    }

    private func templateName(for templateID: UUID) -> String {
        templates.first { $0.id == templateID }?.name ?? "Unknown"
    }
}

// MARK: - Calendar Heatmap

private struct CalendarHeatmap: View {
    let sessions: [WorkoutSession]
    let onDayTap: (WorkoutSession) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    private var calendarDays: [CalendarDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .month, value: -2, to: today) ?? today
        let startOfWeek: Date = {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start)
            return cal.date(from: comps) ?? start
        }()

        // Map each day to its session (first completed session that day)
        var sessionByDay: [Date: WorkoutSession] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.date)
            if sessionByDay[day] == nil {
                sessionByDay[day] = session
            }
        }

        var days: [CalendarDay] = []
        var current = startOfWeek
        while current <= today {
            let session = sessionByDay[current]
            let state = dayCellState(for: session)
            days.append(CalendarDay(date: current, state: state, session: session))
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return days
    }

    private func dayCellState(for session: WorkoutSession?) -> DayCellState {
        guard let session else { return .none }
        let sets = session.setEntries.filter { $0.isCompleted && !$0.isWarmup }
        let hasTargetData = sets.contains { $0.targetWeight > 0 }
        guard hasTargetData else { return .completed }
        let hasFailure = sets.contains { $0.targetWeight > 0 && !$0.metTarget }
        if hasFailure { return .failed }
        let hasProgress = sets.contains { $0.metTarget }
        return hasProgress ? .progressed : .completed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
            HStack(spacing: 4) {
                ForEach(dayHeaders, id: \.self) { h in
                    Text(h)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays) { day in
                    Button {
                        if let session = day.session {
                            onDayTap(session)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(day.fillColor)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .disabled(day.session == nil)
                    .accessibilityLabel(day.accessibilityLabel)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)

            // Legend
            HStack(spacing: AtlasTheme.Spacing.md) {
                legendItem(color: AtlasTheme.Colors.accent, label: "Progressed")
                legendItem(color: AtlasTheme.Colors.accent.opacity(0.3), label: "Completed")
                legendItem(color: AtlasTheme.Colors.failureAccent.opacity(0.5), label: "Failed")
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.bottom, AtlasTheme.Spacing.xs)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
        }
    }
}

private struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let state: DayCellState
    let session: WorkoutSession?

    var fillColor: Color {
        switch state {
        case .none:      return Color(uiColor: .tertiarySystemFill)
        case .completed: return AtlasTheme.Colors.accent.opacity(0.3)
        case .progressed: return AtlasTheme.Colors.accent
        case .failed:    return AtlasTheme.Colors.failureAccent.opacity(0.5)
        }
    }

    var accessibilityLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let dateStr = fmt.string(from: date)
        switch state {
        case .none:       return "\(dateStr): no session"
        case .completed:  return "\(dateStr): completed"
        case .progressed: return "\(dateStr): progressed"
        case .failed:     return "\(dateStr): failed or missed target"
        }
    }
}

// MARK: - Day Detail Sheet

private struct DayDetailSheet: View {
    let day: SelectedDay
    @Environment(\.dismiss) private var dismiss

    private var sessionDateText: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: day.session.date)
    }

    private var progressedSets: [SetEntry] {
        day.session.setEntries
            .filter { $0.isCompleted && !$0.isWarmup && $0.metTarget }
    }

    private var failedSets: [SetEntry] {
        day.session.setEntries
            .filter { $0.isCompleted && !$0.isWarmup && $0.targetWeight > 0 && !$0.metTarget }
    }

    private func exerciseName(for id: UUID) -> String {
        day.exercises.first(where: { $0.id == id })?.displayName ?? "Exercise"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(day.templateName)
                            .font(AtlasTheme.Typography.sectionTitle)
                        Spacer()
                        Text(sessionDateText)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                    .frame(minHeight: 44)
                }
                .listRowBackground(AtlasTheme.Colors.elevatedBackground)

                if !progressedSets.isEmpty {
                    Section("Hit Target") {
                        ForEach(progressedSets, id: \.id) { entry in
                            HStack {
                                Text(exerciseName(for: entry.exerciseId))
                                    .font(AtlasTheme.Typography.body)
                                Spacer()
                                Text("\(entry.weight.weightString)kg × \(entry.reps)")
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundStyle(AtlasTheme.Colors.accent)
                                    .monospacedDigit()
                            }
                            .frame(minHeight: 44)
                        }
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                }

                if !failedSets.isEmpty {
                    Section("Missed Target") {
                        ForEach(failedSets, id: \.id) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exerciseName(for: entry.exerciseId))
                                        .font(AtlasTheme.Typography.body)
                                    Text("Target: \(entry.targetWeight.weightString)kg × \(entry.targetReps)")
                                        .font(AtlasTheme.Typography.caption)
                                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                        .monospacedDigit()
                                }
                                Spacer()
                                Label("\(entry.weight.weightString)kg × \(entry.reps)", systemImage: "xmark.circle.fill")
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundStyle(AtlasTheme.Colors.failureAccent)
                                    .monospacedDigit()
                            }
                            .frame(minHeight: 44)
                        }
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                }

                if progressedSets.isEmpty && failedSets.isEmpty {
                    Section {
                        Text("No progression data for this session.")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(minHeight: 44)
                    }
                    .listRowBackground(AtlasTheme.Colors.elevatedBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Session Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(AtlasTheme.Colors.background)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession
    let templateName: String

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
            Text(templateName)
                .font(AtlasTheme.Typography.sectionTitle)
            Text(dateText)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            HStack(spacing: AtlasTheme.Spacing.xs) {
                if session.overallFeeling > 0 {
                    Text("Feeling: \(session.overallFeeling)/5")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
                if session.weekNumber > 0 {
                    Text("Week \(session.weekNumber)")
                        .font(AtlasTheme.Typography.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AtlasTheme.Colors.accentSoft)
                        .clipShape(Capsule())
                        .foregroundStyle(AtlasTheme.Colors.accent)
                }
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.xs)
        .frame(minHeight: 44, alignment: .leading)
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
