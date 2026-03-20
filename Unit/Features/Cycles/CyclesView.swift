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
    @State private var cycleToRename: Cycle?
    @State private var cycleNameDraft = ""

    private var activeCycle: Cycle? {
        ongoingCycles.first(where: { $0.isActive }) ?? ongoingCycles.first
    }

    private var ongoingCycles: [Cycle] {
        cycles.filter { !$0.isCompleted }
    }

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
                            AppIcon.settingsOutline.image()
                        }
                        .accessibilityLabel("Cycle settings")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if ongoingCycles.isEmpty {
                        Button {
                            showingCreateCycle = true
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                AppIcon.add.image()
                                Text("New Cycle")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateCycle) {
                CreateCycleView()
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.cardBackground)
            }
            .sheet(isPresented: $showingSettings) {
                if let cycle = selectedCycle ?? activeCycle {
                    CycleSettingsView(cycle: cycle)
                        .presentationDragIndicator(.visible)
                        .presentationBackground(AppColor.cardBackground)
                }
            }
            .alert("Rename Cycle", isPresented: Binding(
                get: { cycleToRename != nil },
                set: { if !$0 { cycleToRename = nil } }
            )) {
                TextField("Cycle name", text: $cycleNameDraft)
                Button("Save") {
                    renameSelectedCycle()
                }
                Button("Cancel", role: .cancel) {
                    cycleToRename = nil
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyCycleState: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            AppIcon.calendarClock.image(size: 32, weight: .light)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)
            VStack(spacing: AppSpacing.sm) {
                Text("Start an 8-week cycle to unlock auto-progression.\nThe app computes your targets every week.")
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, AppSpacing.lg)
            Button {
                showingCreateCycle = true
            } label: {
                Text("Start 8-Week Cycle")
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .frame(height: 52)
                    .background(AppColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(AppSpacing.xl)
        .background(AppColor.background.ignoresSafeArea())
    }

    // MARK: - Cycle Content

    private var cycleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let active = activeCycle {
                    activeCycleSection(active)
                }

                let otherPrograms = ongoingCycles.filter { $0.id != activeCycle?.id }
                if !otherPrograms.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Other Programs")
                            .font(AppFont.sectionHeader.font)
                            .padding(.top, AppSpacing.sm)
                        ForEach(otherPrograms, id: \.id) { cycle in
                            switchableCycleRow(cycle)
                        }
                    }
                }

                let completed = cycles.filter { $0.isCompleted }
                if !completed.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Past Cycles")
                            .font(AppFont.sectionHeader.font)
                            .padding(.top, AppSpacing.sm)
                        ForEach(completed, id: \.id) { cycle in
                            pastCycleRow(cycle)
                        }
                    }
                }

                // "Start new cycle" button when active cycle exists (for future)
                if ongoingCycles.isEmpty {
                    Button {
                        showingCreateCycle = true
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            AppIcon.addCircle.image()
                            Text("Start New Cycle")
                        }
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .appCardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
    }

    // MARK: - Active Cycle Section

    private func activeCycleSection(_ cycle: Cycle) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(cycle.name)
                        .font(AppFont.largeTitle.font)
                    Text("Week \(cycle.currentWeekNumber) of \(cycle.weekCount)")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer(minLength: 0)
                Button {
                    cycleNameDraft = cycle.name
                    cycleToRename = cycle
                } label: {
                    AppIcon.edit.image(size: 14)
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 36, height: 36)
                        .background(AppColor.accentSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                ProgressRing(
                    progress: Double(cycle.currentWeekNumber) / Double(cycle.weekCount)
                )
                .frame(width: 56, height: 56)
            }
            .appCardStyle()

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

    private func switchableCycleRow(_ cycle: Cycle) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(cycle.name)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Week \(cycle.currentWeekNumber) of \(cycle.weekCount)")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Button {
                cycleNameDraft = cycle.name
                cycleToRename = cycle
            } label: {
                AppIcon.edit.image(size: 14)
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 36, height: 36)
                    .background(AppColor.accentSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Button {
                setActiveCycle(cycle)
            } label: {
                Text("Make Current")
                    .font(AppFont.captionBold.font)
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.accentSoft)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .appCardStyle()
    }

    // MARK: - Past Cycle Row

    private func pastCycleRow(_ cycle: Cycle) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(cycle.name)
                .font(AppFont.sectionHeader.font)
            Text("Completed · \(cycle.weekCount) weeks")
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .appCardStyle()
    }

    private func setActiveCycle(_ selectedCycle: Cycle) {
        for cycle in cycles where !cycle.isCompleted {
            cycle.isActive = cycle.id == selectedCycle.id
        }
        try? modelContext.save()
    }

    private func renameSelectedCycle() {
        guard let cycle = cycleToRename else { return }
        let trimmed = cycleNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cycle.name = trimmed
        try? modelContext.save()
        cycleToRename = nil
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
                        .presentationDragIndicator(.visible)
                        .presentationBackground(AppColor.cardBackground)
                }
            }
        }
    }

    private func rowContent(status: WeekStatus) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text("Week \(weekNumber)")
                .font(AppFont.body.font.weight(.medium))
                .frame(width: 60, alignment: .leading)

            Text(dateRangeText)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            statusBadge(status: status)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(minHeight: 52)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(borderColor(for: status), lineWidth: status == .current ? 2 : 1.5)
        )
    }

    @ViewBuilder
    private func statusBadge(status: WeekStatus) -> some View {
        switch status {
        case .completed:
            HStack(spacing: AppSpacing.xs) {
                AppIcon.checkmarkFilled.image()
                Text("Done")
            }
            .font(AppFont.caption.font)
            .foregroundStyle(AppColor.success)
        case .failed:
            HStack(spacing: AppSpacing.xs) {
                AppIcon.xmarkFilled.image()
                Text("Failed")
            }
            .font(AppFont.caption.font)
            .foregroundStyle(AppColor.error)
        case .current:
            HStack(spacing: 4) {
                Circle()
                    .fill(AppColor.accent)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Current")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.accent)
            }
        case .upcoming:
            Text("—")
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func borderColor(for status: WeekStatus) -> Color {
        switch status {
        case .current: return AppColor.accent
        case .failed: return AppColor.error.opacity(0.4)
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
                .stroke(AppColor.border, lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(AppColor.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(AppFont.tinyBold)
                .foregroundStyle(AppColor.textPrimary)
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
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Projected targets — no outcomes yet.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)

                    ForEach(rules.filter { $0.cycleId == cycle.id }, id: \.id) { rule in
                        if let target = ProgressionEngine.target(for: weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: []) {
                            let name = exercises.first(where: { $0.id == rule.exerciseId })?.displayName ?? "Exercise"
                            HStack {
                                Text(name)
                                    .font(AppFont.body.font)
                                Spacer(minLength: 0)
                                Text("\(target.weightKg.weightString)kg × \(target.reps)")
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .padding(.vertical, AppSpacing.sm)
                            AppDivider()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.background)
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
}
