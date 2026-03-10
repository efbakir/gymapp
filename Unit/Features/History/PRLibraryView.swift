//
//  PRLibraryView.swift
//  Unit
//
//  Personal record list by exercise.
//

import SwiftUI

struct PRLibraryView: View {
    let sessions: [WorkoutSession]
    let exercises: [Exercise]

    private var records: [PRRecord] {
        let completedEntries = sessions
            .filter(\.isCompleted)
            .flatMap { $0.setEntries.filter(\.isCompleted) }

        let grouped = Dictionary(grouping: completedEntries, by: \.exerciseId)

        return grouped.compactMap { exerciseID, entries in
            guard let exercise = exercises.first(where: { $0.id == exerciseID }) else { return nil }
            guard let best = entries.max(by: { lhs, rhs in
                lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight
            }) else {
                return nil
            }
            return PRRecord(exerciseName: exercise.displayName, weight: best.weight, reps: best.reps)
        }
        .sorted { $0.exerciseName < $1.exerciseName }
    }

    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Text("No PRs yet. Complete workouts to build your library.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(minHeight: 44)
                } else {
                    ForEach(records) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                Text(record.exerciseName)
                                    .font(Theme.Typography.body)
                                Text("Best set")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Text("\(record.weight.weightString) kg × \(record.reps)")
                                .font(Theme.Typography.body)
                                .monospacedDigit()
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle("PR Library")
        }
    }
}

private struct PRRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weight: Double
    let reps: Int
}

#Preview {
    PRLibraryView(sessions: [], exercises: [])
        .preferredColorScheme(.dark)
}
