//
//  HistoryView.swift
//  Unit
//
//  History tab: calendar-first monthly scan with status-focused day states.
//  Tapping a day with a session opens a lightweight bottom sheet.
//

import SwiftUI
import SwiftData

// MARK: - Day State

enum DaySessionState {
    case none        // no session logged
    case completed   // session logged, no target data
    case progressed  // >=1 set met target
    case failed      // >=1 set missed target (failed wins)

    var indicatorColor: Color? {
        switch self {
        case .none:       return nil
        case .completed:  return AppColor.textSecondary.opacity(0.35)
        case .progressed: return AppColor.success
        case .failed:     return AppColor.error
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
        case .completed:  return AppColor.textSecondary
        case .progressed: return AppColor.success
        case .failed:     return AppColor.error
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
    let showsCloseButton: Bool

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var displayMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedPayload: SelectedDayPayload?
    @State private var showingDayDetail = false
    @Environment(\.dismiss) private var dismiss

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    MonthCalendar(
                        displayMonth: $displayMonth,
                        sessions: completedSessions,
                        onDayTap: { calDay in
                            guard let session = calDay.session else { return }
                            let name = templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                            let payload = SelectedDayPayload(
                                date: calDay.date,
                                session: session,
                                templateName: name,
                                exercises: exercises
                            )
                            selectedPayload = payload
                            if showsCloseButton {
                                showingDayDetail = true
                            }
                        }
                    )
                    .padding(.horizontal, AppSpacing.md)

                    historyLegend
                        .padding(.horizontal, AppSpacing.md)
                }
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(AppColor.accent)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { dismiss() }
                    }
                }
            }
            .navigationDestination(isPresented: $showingDayDetail) {
                if let selectedPayload {
                    DayDetailSheet(payload: selectedPayload)
                        .background(AppColor.background.ignoresSafeArea())
                        .onDisappear {
                            self.selectedPayload = nil
                        }
                }
            }
        }
        .sheet(item: dayDetailSheetBinding) { payload in
            DayDetailSheet(payload: payload)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.cardBackground)
        }
        .onChange(of: showingDayDetail) { _, isPresented in
            if !isPresented {
                selectedPayload = nil
            }
        }
    }

    private var historyLegend: some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                LegendItem(color: AppColor.success, label: "Progressed")
                LegendItem(color: AppColor.error, label: "Failed")
                LegendItem(color: AppColor.textSecondary.opacity(0.35), label: "Completed")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dayDetailSheetBinding: Binding<SelectedDayPayload?> {
        Binding(
            get: { showsCloseButton ? nil : selectedPayload },
            set: { newValue in
                if !showsCloseButton {
                    selectedPayload = newValue
                }
            }
        )
    }
}

extension HistoryView {
    init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

private enum HistoryStatusEvaluator {
    static func state(for session: WorkoutSession?) -> DaySessionState {
        guard let session else { return .none }
        return state(for: session.setEntries)
    }

    static func state(for entries: [SetEntry]) -> DaySessionState {
        let targetSets = entries.filter { $0.isCompleted && !$0.isWarmup && $0.targetWeight > 0 }
        guard !targetSets.isEmpty else { return .completed }
        if targetSets.contains(where: { !$0.metTarget }) {
            return .failed
        }
        return .progressed
    }
}

// MARK: - Month Calendar

private struct MonthCalendar: View {
    @Binding var displayMonth: Date
    let sessions: [WorkoutSession]
    let onDayTap: (CalDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 7)
    private let weekdayHeaders = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

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

        var sessionsByDay: [Date: [WorkoutSession]] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.date)
            sessionsByDay[day, default: []].append(session)
        }

        let weekday = cal.component(.weekday, from: displayMonth)
        let leadingCount = (weekday + 5) % 7
        var result: [CalDay?] = Array(repeating: nil, count: leadingCount)

        for offset in 0..<dayRange.count {
            guard let date = cal.date(byAdding: .day, value: offset, to: displayMonth) else { continue }
            let dayNum = offset + 1
            let isFuture = date > today
            let daySessions = sessionsByDay[date] ?? []
            let session = daySessions.first(where: { HistoryStatusEvaluator.state(for: $0) == .failed }) ?? daySessions.first
            let state: DaySessionState = isFuture ? .none : sessionState(for: daySessions)
            result.append(CalDay(date: date, dayNumber: dayNum, isToday: date == today,
                                  isFuture: isFuture, state: state, session: session))
        }

        return result
    }

    private func sessionState(for daySessions: [WorkoutSession]) -> DaySessionState {
        guard !daySessions.isEmpty else { return .none }
        let dayEntries = daySessions.flatMap(\.setEntries)
        return HistoryStatusEvaluator.state(for: dayEntries)
    }

    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    Text(monthTitle)
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer(minLength: 0)

                    HStack(spacing: AppSpacing.xs) {
                        Button { navigateMonth(-1) } label: {
                            AppIcon.back.image(size: 15, weight: .semibold)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button { navigateMonth(1) } label: {
                            AppIcon.forward.image(size: 15, weight: .semibold)
                                .foregroundStyle(canGoForward ? AppColor.textPrimary : AppColor.disabled)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canGoForward)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, header in
                        Text(header)
                            .font(AppFont.smallLabel)
                            .foregroundStyle(AppColor.textSecondary.opacity(0.45))
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(Array(calDays.enumerated()), id: \.offset) { _, cell in
                        if let cell {
                            DayCell(day: cell) { onDayTap(cell) }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let day: CalDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    if day.isToday {
                        Circle()
                            .fill(AppColor.accent)
                    } else if day.state == .none {
                        Circle()
                            .stroke(AppColor.border, lineWidth: 1)
                    }

                    Text("\(day.dayNumber)")
                        .font(AppFont.body.font)
                        .foregroundStyle(numberColor)
                }
                .frame(width: 40, height: 40)

                if let indicatorColor = day.state.indicatorColor {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear.frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day.session == nil && !day.isToday)
        .accessibilityLabel(accessibilityLabel)
    }

    private var numberColor: Color {
        if day.isFuture {
            return AppColor.textSecondary.opacity(0.2)
        }
        if day.isToday {
            return .white
        }
        return AppColor.textPrimary
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
            let hasTarget = entries.contains { $0.targetWeight > 0 }
            let missedAnyTarget = entries.contains { $0.targetWeight > 0 && !$0.metTarget }
            return (name, best, hasTarget ? !missedAnyTarget : true)
        }
        .sorted { $0.name < $1.name }
    }

    private var sessionState: DaySessionState {
        HistoryStatusEvaluator.state(for: payload.session)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Self.dayFormatter.string(from: payload.date))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(0.3)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(payload.templateName)
                        .font(AppFont.largeTitle.font)
                        .foregroundStyle(AppColor.textPrimary)

                    let state = sessionState
                    if state != .none {
                        Text(state.label)
                            .font(AppFont.badgeText)
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
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)

            if exerciseRows.isEmpty {
                VStack {
                    Text("No set data recorded.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(exerciseRows, id: \.name) { row in
                            ExerciseOutcomeRow(
                                name: row.name,
                                set: row.bestSet,
                                metTarget: row.metTarget
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
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
        HStack(spacing: AppSpacing.md) {
            (metTarget ? AppIcon.checkmark : AppIcon.close).image(size: 11, weight: .bold)
                .foregroundStyle(metTarget ? AppColor.success : AppColor.error)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        metTarget ? AppColor.success.opacity(0.12) : AppColor.error.opacity(0.12)
                    )
                )

            Text(name)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(set.weight.weightString) kg × \(set.reps)")
                .font(AppFont.label.font)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(minHeight: 52)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
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
}
