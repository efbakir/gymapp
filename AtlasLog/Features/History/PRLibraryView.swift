//
//  PRLibraryView.swift
//  AtlasLog
//
//  Personal Records library: best e1RM per exercise, sparkline, Epley/Brzycki toggle.
//

import Charts
import SwiftUI
import SwiftData

// MARK: - e1RM formulas

private enum E1RMFormula: String, CaseIterable {
    case epley = "Epley"
    case brzycki = "Brzycki"

    func calculate(weight: Double, reps: Int) -> Double {
        switch self {
        case .epley:
            // Epley: weight × (1 + reps / 30)
            return weight * (1.0 + Double(reps) / 30.0)
        case .brzycki:
            // Brzycki: weight × 36 / (37 − reps)
            guard reps < 37 else { return weight }
            return weight * 36.0 / Double(37 - reps)
        }
    }
}

// MARK: - PR Entry

struct PREntry: Identifiable {
    let id: UUID        // exerciseId
    let exerciseName: String
    let bestE1RM: Double
    let bestSetText: String
    let dateAchieved: Date
    let recentE1RMs: [Double]   // for sparkline (latest 8)
}

// MARK: - PRLibraryView

struct PRLibraryView: View {
    let sessions: [WorkoutSession]
    let exercises: [Exercise]

    @State private var formula: E1RMFormula = {
        let saved = UserDefaults.standard.string(forKey: "atlas_e1rm_formula")
        return E1RMFormula(rawValue: saved ?? "") ?? .epley
    }()

    @Environment(\.dismiss) private var dismiss

    private var prEntries: [PREntry] {
        let allSets = sessions.flatMap { $0.setEntries }.filter { $0.isCompleted && $0.reps > 0 && $0.weight > 0 }

        let byExercise = Dictionary(grouping: allSets, by: \.exerciseId)

        return byExercise.compactMap { exerciseId, sets -> PREntry? in
            guard let exercise = exercises.first(where: { $0.id == exerciseId }) else { return nil }

            let withE1RM = sets.map { entry -> (e1rm: Double, entry: SetEntry) in
                (formula.calculate(weight: entry.weight, reps: entry.reps), entry)
            }

            guard let best = withE1RM.max(by: { $0.e1rm < $1.e1rm }) else { return nil }

            // Recent e1RMs for sparkline: last 8 chronologically
            let recentE1RMs = withE1RM
                .sorted { $0.entry.session?.date ?? .distantPast < $1.entry.session?.date ?? .distantPast }
                .suffix(8)
                .map { $0.e1rm }

            let setText = "\(best.entry.weight.weightString)kg × \(best.entry.reps)"
            let date = best.entry.session?.date ?? Date()

            return PREntry(
                id: exerciseId,
                exerciseName: exercise.displayName,
                bestE1RM: best.e1rm,
                bestSetText: setText,
                dateAchieved: date,
                recentE1RMs: recentE1RMs
            )
        }
        .sorted { $0.bestE1RM > $1.bestE1RM }
    }

    var body: some View {
        NavigationStack {
            List {
                // Formula picker
                Section {
                    Picker("Formula", selection: $formula) {
                        ForEach(E1RMFormula.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: formula) { _, new in
                        UserDefaults.standard.set(new.rawValue, forKey: "atlas_e1rm_formula")
                    }
                } footer: {
                    Text(formula == .epley
                         ? "Epley: weight × (1 + reps ÷ 30)"
                         : "Brzycki: weight × 36 ÷ (37 − reps)")
                        .font(AtlasTheme.Typography.caption)
                }

                // PR rows
                if prEntries.isEmpty {
                    Text("No completed sets yet.")
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                } else {
                    Section("Personal Records") {
                        ForEach(prEntries) { entry in
                            PRRow(entry: entry)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("PR Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

}

// MARK: - PR Row

private struct PRRow: View {
    let entry: PREntry

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: entry.dateAchieved)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AtlasTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                Text(entry.exerciseName)
                    .font(AtlasTheme.Typography.sectionTitle)
                    .lineLimit(1)
                Text(entry.bestSetText)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                Text(dateText)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: AtlasTheme.Spacing.xxs) {
                Text("\(Int(entry.bestE1RM)) kg")
                    .font(AtlasTheme.Typography.metric)
                    .foregroundStyle(AtlasTheme.Colors.accent)
                    .monospacedDigit()
                Text("e1RM")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)

                // Sparkline (60×30 pt)
                if entry.recentE1RMs.count > 1 {
                    SparklineView(values: entry.recentE1RMs)
                        .frame(width: 60, height: 30)
                }
            }
        }
        .frame(minHeight: 64)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.exerciseName). Best e1RM: \(Int(entry.bestE1RM))kg from \(entry.bestSetText) on \(dateText).")
    }
}

// MARK: - Sparkline

private struct SparklineView: View {
    let values: [Double]

    var body: some View {
        let indexed = values.enumerated().map { SparkPoint(index: $0.offset, value: $0.element) }
        Chart(indexed) { point in
            LineMark(
                x: .value("Set", point.index),
                y: .value("e1RM", point.value)
            )
            .foregroundStyle(AtlasTheme.Colors.accent)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityHidden(true)
    }
}

private struct SparkPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

#Preview {
    let container = PreviewSampleData.makePreviewContainer()
    let sessions = (try? container.mainContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []
    let exercises = (try? container.mainContext.fetch(FetchDescriptor<Exercise>())) ?? []
    return PRLibraryView(sessions: sessions, exercises: exercises)
        .modelContainer(container)
}
