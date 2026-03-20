//
//  PRLibraryView.swift
//  Unit
//
//  Personal record list by exercise.
//

import SwiftUI

struct PRLibraryView: View {
    @Environment(\.dismiss) private var dismiss

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
        AppScreen(
            title: "PR Library",
            leadingAction: NavAction(icon: .back, action: { dismiss() })
        ) {
            if records.isEmpty {
                AppCard {
                    VStack(spacing: AppSpacing.sm) {
                        AppIcon.trophy.image(size: 32, weight: .light)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("No PRs yet. Complete workouts to build your library.")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(records) { record in
                        AppCard {
                            AppListRow(
                                title: record.exerciseName,
                                subtitle: "Best set"
                            ) {
                                Text("\(record.weight.weightString) kg × \(record.reps)")
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
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
}
