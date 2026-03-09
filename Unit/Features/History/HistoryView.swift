//
//  HistoryView.swift
//  Unit
//
//  History tab: calendar heatmap + completed session list.
//

import Charts
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var showingAllPRs = false

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
        }
    }

    private var mainList: some View {
        List {
            if !searchText.isEmpty {
                // Exercise filter results
                Section("Exercises") {
                    if filteredExercises.isEmpty {
                        Text("No exercises found.")
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(minHeight: 44)
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
            } else {
                // Calendar heatmap
                Section {
                    CalendarHeatmap(sessions: completedSessions)
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
                }

                // Session list
                if completedSessions.isEmpty {
                    Text("No completed sessions yet.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(minHeight: 44)
                } else {
                    Section("Sessions") {
                        ForEach(completedSessions, id: \.id) { session in
                            NavigationLink(value: session) {
                                SessionRow(session: session, templateName: templateName(for: session.templateId))
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func templateName(for templateID: UUID) -> String {
        templates.first { $0.id == templateID }?.name ?? "Unknown"
    }
}

// MARK: - Calendar Heatmap

private struct CalendarHeatmap: View {
    let sessions: [WorkoutSession]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    private var calendarDays: [CalendarDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // 3 months back
        let start = cal.date(byAdding: .month, value: -2, to: today) ?? today
        let startOfWeek: Date = {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start)
            return cal.date(from: comps) ?? start
        }()

        // Total tonnage per day for quick lookup
        var tonnageByDay: [Date: Double] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.date)
            let t = session.setEntries.filter(\.isCompleted).reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            tonnageByDay[day, default: 0] += t
        }

        let maxTonnage = tonnageByDay.values.max() ?? 1

        var days: [CalendarDay] = []
        var current = startOfWeek
        while current <= today {
            let tonnage = tonnageByDay[current] ?? 0
            days.append(CalendarDay(date: current, tonnage: tonnage, maxTonnage: maxTonnage))
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return days
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
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(day.fillColor)
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(day.accessibilityLabel)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
        }
    }
}

private struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let tonnage: Double
    let maxTonnage: Double

    var intensity: Double {
        guard maxTonnage > 0, tonnage > 0 else { return 0 }
        return min(tonnage / maxTonnage, 1)
    }

    var fillColor: Color {
        if intensity == 0 { return Color(uiColor: .tertiarySystemFill) }
        return AtlasTheme.Colors.accent.opacity(0.2 + intensity * 0.8)
    }

    var accessibilityLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        if tonnage > 0 {
            return "\(fmt.string(from: date)): \(Int(tonnage))kg total volume"
        }
        return "\(fmt.string(from: date)): rest day"
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
