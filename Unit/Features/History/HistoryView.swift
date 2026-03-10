//
//  HistoryView.swift
//  Unit
//
//  History tab: month calendar (default scan view) + recent sessions list.
//  Calendar day circles show state via color fill (green/red/grey).
//  Tapping a day with a session opens a lightweight bottom sheet.
//

import SwiftUI
import SwiftData

// MARK: - Day State

enum DaySessionState {
    case none        // no session logged
    case completed   // session logged, no target data
    case progressed  // ≥1 set met target
    case failed      // ≥1 set missed target (and no progressed sets)

    var fillColor: Color? {
        switch self {
        case .none:       return nil
        case .completed:  return AtlasTheme.Colors.textSecondary.opacity(0.35)
        case .progressed: return AtlasTheme.Colors.successAccent
        case .failed:     return AtlasTheme.Colors.failureAccent
        }
    }

    var label: String {
        switch self {
        case .none:       return ""
        case .completed:  return "COMPLETED"
        case .progressed: return "PROGRESSED"
        case .failed:     return "MISSED"
        }
    }

    var labelColor: Color {
        switch self {
        case .none:       return .clear
        case .completed:  return AtlasTheme.Colors.textSecondary
        case .progressed: return AtlasTheme.Colors.successAccent
        case .failed:     return AtlasTheme.Colors.failureAccent
        }
    }
}

// MARK: - Calendar Day Model

private struct CalDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isFuture: Bool
    let state: DaySessionState
    let session: WorkoutSession?
}

// MARK: - Selected Day (bottom sheet payload)

private struct SelectedDayPayload: Identifiable {
    let id = UUID()
    let date: Date
    let session: WorkoutSession
    let templateName: String
    let exercises: [Exercise]
}

// MARK: - HistoryView

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var displayMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedPayload: SelectedDayPayload?
    @State private var titleGradientProgress: CGFloat = 0

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtlasTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: HistoryScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("historyScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Calendar card
                        MonthCalendar(
                            displayMonth: $displayMonth,
                            sessions: completedSessions,
                            onDayTap: { calDay in
                                guard let session = calDay.session else { return }
                                let name = templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                                selectedPayload = SelectedDayPayload(
                                    date: calDay.date,
                                    session: session,
                                    templateName: name,
                                    exercises: exercises
                                )
                            }
                        )
                        .padding(.horizontal, AtlasTheme.Spacing.md)

                        // Sessions list
                        sessionsSection
                    }
                    .padding(.top, AtlasTheme.Spacing.md)
                    .padding(.bottom, AtlasTheme.Spacing.md)
                }
                .coordinateSpace(name: "historyScroll")
                .scrollIndicators(.hidden)

                titleGradientOverlay
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AtlasTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(
                    session: session,
                    templateName: templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                )
            }
            .onPreferenceChange(HistoryScrollOffsetPreferenceKey.self) { minY in
                let progress = min(max((-minY) / 72, 0), 1)
                titleGradientProgress = progress
            }
        }
        .sheet(item: $selectedPayload) { payload in
            DayDetailSheet(payload: payload)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AtlasTheme.Colors.sheet)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        if completedSessions.isEmpty {
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                Text("No completed sessions yet.")
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AtlasTheme.Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                Text("RECENT SESSIONS")
                    .font(AtlasTheme.Typography.overline)
                    .tracking(1.0)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .padding(.horizontal, AtlasTheme.Spacing.md)

                ForEach(completedSessions.prefix(20)) { session in
                    NavigationLink(value: session) {
                        SessionListRow(
                            session: session,
                            templateName: templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                }
            }
        }
    }

    private var titleGradientOverlay: some View {
        LinearGradient(
            colors: [
                AtlasTheme.Colors.background.opacity(0.98),
                AtlasTheme.Colors.background.opacity(0.92),
                AtlasTheme.Colors.background.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 132)
        .ignoresSafeArea(edges: .top)
        .opacity(0.2 + (titleGradientProgress * 0.8))
        .allowsHitTesting(false)
    }
}

private struct HistoryScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Session List Row

private struct SessionListRow: View {
    let session: WorkoutSession
    let templateName: String

    private var state: DaySessionState {
        let sets = session.setEntries.filter { $0.isCompleted && !$0.isWarmup && $0.targetWeight > 0 }
        guard !sets.isEmpty else { return .completed }
        let anyFailed = sets.contains { !$0.metTarget }
        let anyProgressed = sets.contains { $0.metTarget }
        if anyFailed && !anyProgressed { return .failed }
        return .progressed
    }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: session.date)
    }

    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            // State circle
            ZStack {
                Circle()
                    .fill(state.fillColor ?? AtlasTheme.Colors.textSecondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: state == .failed ? "xmark" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(state == .completed ? AtlasTheme.Colors.textPrimary : .white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(templateName)
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)
                Text(dateLabel)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasTheme.Colors.textSecondary.opacity(0.5))
        }
        .padding(AtlasTheme.Spacing.sm)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .frame(minHeight: 52)
    }
}

// MARK: - Month Calendar

private struct MonthCalendar: View {
    @Binding var displayMonth: Date
    let sessions: [WorkoutSession]
    let onDayTap: (CalDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayMonth)
    }

    private var canGoForward: Bool {
        displayMonth < Calendar.current.startOfMonth(for: Date())
    }

    private func navigateMonth(_ direction: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: direction, to: displayMonth) else { return }
        displayMonth = next
    }

    private var calDays: [CalDay?] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        guard let dayRange = cal.range(of: .day, in: .month, for: displayMonth) else { return [] }

        var sessionByDay: [Date: WorkoutSession] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            if sessionByDay[day] == nil { sessionByDay[day] = s }
        }

        let weekday = cal.component(.weekday, from: displayMonth)
        let leadingCount = (weekday + 5) % 7
        var result: [CalDay?] = Array(repeating: nil, count: leadingCount)

        for offset in 0..<dayRange.count {
            guard let date = cal.date(byAdding: .day, value: offset, to: displayMonth) else { continue }
            let dayNum = offset + 1
            let isFuture = date > today
            let session = sessionByDay[date]
            let state: DaySessionState = isFuture ? .none : sessionState(for: session)
            result.append(CalDay(date: date, dayNumber: dayNum, isToday: date == today,
                                  isFuture: isFuture, state: state, session: session))
        }

        return result
    }

    private func sessionState(for session: WorkoutSession?) -> DaySessionState {
        guard let session else { return .none }
        let sets = session.setEntries.filter { $0.isCompleted && !$0.isWarmup && $0.targetWeight > 0 }
        guard !sets.isEmpty else { return .completed }
        let anyFailed = sets.contains { !$0.metTarget }
        let anyProgressed = sets.contains { $0.metTarget }
        if anyFailed && !anyProgressed { return .failed }
        return .progressed
    }

    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {

            // Month navigation
            HStack {
                Button { navigateMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(AtlasTheme.Typography.sectionTitle)
                    .foregroundStyle(AtlasTheme.Colors.textPrimary)

                Spacer()

                Button { navigateMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canGoForward ? AtlasTheme.Colors.textSecondary : AtlasTheme.Colors.disabled)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoForward)
            }

            // Weekday headers
            HStack(spacing: 4) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, h in
                    Text(h)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AtlasTheme.Colors.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(calDays.enumerated()), id: \.offset) { _, cell in
                    if let cell {
                        DayCell(day: cell) { onDayTap(cell) }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let day: CalDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Filled circle for sessions
                if let fill = day.state.fillColor {
                    Circle().fill(fill)
                }
                // Today ring
                if day.isToday && day.state == .none {
                    Circle()
                        .stroke(AtlasTheme.Colors.accent.opacity(0.7), lineWidth: 1.5)
                }
                // Day number
                Text("\(day.dayNumber)")
                    .font(.system(size: 13, weight: day.isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(
                        day.isFuture ? AtlasTheme.Colors.textSecondary.opacity(0.2) :
                        day.state == .completed ? AtlasTheme.Colors.textPrimary :
                        day.state != .none ? Color.white :
                        day.isToday ? AtlasTheme.Colors.accent :
                                       AtlasTheme.Colors.textPrimary
                    )
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(day.session == nil && !day.isToday)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let d = fmt.string(from: day.date)
        switch day.state {
        case .none:       return "\(d): no session"
        case .completed:  return "\(d): completed"
        case .progressed: return "\(d): progressed"
        case .failed:     return "\(d): missed target"
        }
    }
}

// MARK: - Day Detail Sheet

private struct DayDetailSheet: View {
    let payload: SelectedDayPayload

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private var exerciseRows: [(name: String, bestSet: SetEntry, metTarget: Bool)] {
        let sets = payload.session.setEntries
            .filter { $0.isCompleted && !$0.isWarmup }
        let grouped = Dictionary(grouping: sets, by: \.exerciseId)
        return grouped.compactMap { exerciseId, entries in
            let name = payload.exercises.first(where: { $0.id == exerciseId })?.displayName ?? "Exercise"
            let best = entries.max(by: { $0.weight < $1.weight }) ?? entries[0]
            let met = entries.contains { $0.targetWeight > 0 && $0.metTarget }
            let hasTarget = entries.contains { $0.targetWeight > 0 }
            return (name, best, hasTarget ? met : true)
        }
        .sorted { $0.name < $1.name }
    }

    private var sessionState: DaySessionState {
        let sets = payload.session.setEntries.filter { $0.isCompleted && !$0.isWarmup && $0.targetWeight > 0 }
        guard !sets.isEmpty else { return .completed }
        let anyFailed = sets.contains { !$0.metTarget }
        let anyProgressed = sets.contains { $0.metTarget }
        if anyFailed && !anyProgressed { return .failed }
        return .progressed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                Text(Self.dayFormatter.string(from: payload.date))
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .tracking(0.3)

                HStack(alignment: .firstTextBaseline, spacing: AtlasTheme.Spacing.sm) {
                    Text(payload.templateName)
                        .font(AtlasTheme.Typography.hero)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)

                    let state = sessionState
                    if state != .none {
                        Text(state.label)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(state.labelColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.labelColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if payload.session.weekNumber > 0 {
                    Text("Week \(payload.session.weekNumber) of 8")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
            .padding(.top, AtlasTheme.Spacing.lg)
            .padding(.bottom, AtlasTheme.Spacing.md)

            Divider()
                .background(AtlasTheme.Colors.border)

            if exerciseRows.isEmpty {
                VStack {
                    Text("No set data recorded.")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AtlasTheme.Spacing.xl)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(exerciseRows, id: \.name) { row in
                            ExerciseOutcomeRow(
                                name: row.name,
                                set: row.bestSet,
                                metTarget: row.metTarget
                            )
                            Divider()
                                .padding(.leading, AtlasTheme.Spacing.lg)
                                .background(AtlasTheme.Colors.border)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Exercise Outcome Row

private struct ExerciseOutcomeRow: View {
    let name: String
    let set: SetEntry
    let metTarget: Bool

    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            Image(systemName: metTarget ? "checkmark" : "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(metTarget ? AtlasTheme.Colors.successAccent : AtlasTheme.Colors.failureAccent)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        metTarget ? AtlasTheme.Colors.successAccent.opacity(0.12) : AtlasTheme.Colors.failureAccent.opacity(0.12)
                    )
                )

            Text(name)
                .font(AtlasTheme.Typography.body)
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(set.weight.weightString) kg × \(set.reps)")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .frame(minHeight: 52)
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
