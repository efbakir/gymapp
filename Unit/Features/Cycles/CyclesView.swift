//
//  CyclesView.swift
//  Unit
//
//  Cycles tab root: 8-week list view, empty state, and cycle creation.
//

import SwiftUI
import SwiftData

struct CyclesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]
    @Query private var progressionRules: [ProgressionRule]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var showingCreateCycle = false
    @State private var selectedCycle: Cycle?
    @State private var showingSettings = false

    private var activeCycle: Cycle? { cycles.first(where: { $0.isActive && !$0.isCompleted }) }

    var body: some View {
        NavigationStack {
            Group {
                if cycles.isEmpty {
                    emptyCycleState
                } else {
                    cycleContent
                }
            }
            .navigationTitle("Cycles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let active = activeCycle {
                        Button {
                            selectedCycle = active
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Cycle settings")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if activeCycle == nil {
                        Button {
                            showingCreateCycle = true
                        } label: {
                            Label("New Cycle", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateCycle) {
                CreateCycleView()
            }
            .sheet(isPresented: $showingSettings) {
                if let cycle = selectedCycle ?? activeCycle {
                    CycleSettingsView(cycle: cycle)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyCycleState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.Colors.textSecondary)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.xs) {
                Text("No Active Cycle")
                    .font(Theme.Typography.hero)
                Text("Start an 8-week cycle to unlock auto-progression.\nThe app computes your targets every week.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showingCreateCycle = true
            } label: {
                Text("Start 8-Week Cycle")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .frame(height: 52)
                    .background(Theme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    // MARK: - Cycle Content

    private var cycleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if let active = activeCycle {
                    activeCycleSection(active)
                }

                let completed = cycles.filter { !$0.isActive || $0.isCompleted }
                if !completed.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Past Cycles")
                            .font(Theme.Typography.title)
                            .padding(.top, Theme.Spacing.sm)
                        ForEach(completed, id: \.id) { cycle in
                            pastCycleRow(cycle)
                        }
                    }
                }

                // "Start new cycle" button when active cycle exists (for future)
                if activeCycle == nil {
                    Button {
                        showingCreateCycle = true
                    } label: {
                        Label("Start New Cycle", systemImage: "plus.circle.fill")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Active Cycle Section

    private func activeCycleSection(_ cycle: Cycle) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(cycle.name)
                        .font(Theme.Typography.hero)
                    Text("Week \(cycle.currentWeekNumber) of \(cycle.weekCount)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
                ProgressRing(
                    progress: Double(cycle.currentWeekNumber) / Double(cycle.weekCount)
                )
                .frame(width: 44, height: 44)
            }
            .cardStyle()

            ForEach(1...cycle.weekCount, id: \.self) { week in
                WeekRowView(
                    cycle: cycle,
                    weekNumber: week,
                    sessions: sessions,
                    rules: progressionRules,
                    exercises: exercises
                )
            }
        }
    }

    // MARK: - Past Cycle Row

    private func pastCycleRow(_ cycle: Cycle) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(cycle.name)
                .font(Theme.Typography.title)
            Text("Completed · \(cycle.weekCount) weeks")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .cardStyle()
    }
}

// MARK: - Week Row View

private struct WeekRowView: View {
    let cycle: Cycle
    let weekNumber: Int
    let sessions: [WorkoutSession]
    let rules: [ProgressionRule]
    let exercises: [Exercise]

    @State private var showingProjected = false

    private var cycleSession: WorkoutSession? {
        sessions.first { $0.cycleId == cycle.id && $0.weekNumber == weekNumber && $0.isCompleted }
    }

    private var status: WeekStatus {
        let current = cycle.currentWeekNumber
        if weekNumber < current {
            let allSets = sessions.filter { $0.cycleId == cycle.id && $0.weekNumber == weekNumber }
            let anyFailed = allSets.flatMap { $0.setEntries }.contains { !$0.metTarget && $0.targetWeight > 0 }
            return anyFailed ? .failed : .completed
        } else if weekNumber == current { return .current }
        return .upcoming
    }

    private var dateRangeText: String {
        let range = cycle.dateRange(for: weekNumber)
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: range.lowerBound))–\(fmt.string(from: range.upperBound))"
    }

    var body: some View {
        let s = status  // compute once per render
        Group {
            if s == .current || s == .completed || s == .failed {
                NavigationLink(destination: WeekDetailView(cycle: cycle, weekNumber: weekNumber, rules: rules, exercises: exercises, sessions: sessions)) {
                    rowContent(status: s)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showingProjected = true
                } label: {
                    rowContent(status: s)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingProjected) {
                    ProjectedWeekSheet(cycle: cycle, weekNumber: weekNumber, rules: rules, exercises: exercises)
                        .presentationDetents([.medium])
                }
            }
        }
    }

    private func rowContent(status: WeekStatus) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("Week \(weekNumber)")
                .font(Theme.Typography.body.weight(.medium))
                .frame(width: 60, alignment: .leading)

            Text(dateRangeText)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            statusBadge(status: status)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(minHeight: 52)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(borderColor(for: status), lineWidth: status == .current ? 2 : 1.5)
        )
    }

    @ViewBuilder
    private func statusBadge(status: WeekStatus) -> some View {
        switch status {
        case .completed:
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(Theme.Typography.caption)
                .foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "xmark.circle.fill")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.failure)
        case .current:
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Current")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.accent)
            }
        case .upcoming:
            Text("—")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func borderColor(for status: WeekStatus) -> Color {
        switch status {
        case .current: return Theme.Colors.accent
        case .failed: return Theme.Colors.failure.opacity(0.4)
        default: return Color.clear
        }
    }
}

private enum WeekStatus { case completed, failed, current, upcoming }

// MARK: - Progress Ring

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.border, lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Projected Week Sheet

private struct ProjectedWeekSheet: View {
    let cycle: Cycle
    let weekNumber: Int
    let rules: [ProgressionRule]
    let exercises: [Exercise]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Projected targets — no outcomes yet.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    ForEach(rules.filter { $0.cycleId == cycle.id }, id: \.id) { rule in
                        if let target = ProgressionEngine.target(for: weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: []) {
                            let name = exercises.first(where: { $0.id == rule.exerciseId })?.displayName ?? "Exercise"
                            HStack {
                                Text(name)
                                    .font(Theme.Typography.body)
                                Spacer(minLength: 0)
                                Text("\(target.weightKg.weightString)kg × \(target.reps)")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.ghostText)
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                            Divider()
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Week \(weekNumber) Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

}

#Preview {
    CyclesView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
