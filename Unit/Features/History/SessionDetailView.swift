//
//  SessionDetailView.swift
//  Unit
//
//  Read-only session detail grouped by exercise.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    let templateName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @State private var showingFeelingPicker = false

    private var setsByExercise: [(exercise: Exercise, entries: [SetEntry])] {
        let grouped = Dictionary(grouping: session.setEntries.filter(\.isCompleted), by: \.exerciseId)
        return grouped.compactMap { exerciseID, entries in
            guard let exercise = exercises.first(where: { $0.id == exerciseID }) else { return nil }
            return (exercise, entries.sorted { $0.setIndex < $1.setIndex })
        }
        .sorted { $0.exercise.displayName < $1.exercise.displayName }
    }

    var body: some View {
        AppScreen(
            title: "Session",
            leadingAction: NavAction(icon: .back, action: { dismiss() })
        ) {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(templateName)
                        .font(AppFont.sectionHeader.font)
                    Text(session.date, style: .date)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(session.date, style: .time)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            ForEach(setsByExercise, id: \.exercise.id) { section in
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(section.exercise.displayName)
                            .font(AppFont.sectionHeader.font)

                        ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                            AppListRow(
                                title: "Set \(entry.setIndex + 1)",
                                subtitle: entry.rpe > 0 ? "RPE \(formatWeight(entry.rpe))" : nil
                            ) {
                                Text("\(formatWeight(entry.weight)) kg × \(entry.reps)")
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            if index < section.entries.count - 1 {
                                AppDivider()
                            }
                        }
                    }
                }
            }

            AppCard {
                Button {
                    showingFeelingPicker = true
                } label: {
                    AppListRow(title: "Overall feeling") {
                        if session.overallFeeling > 0 {
                            Text("\(session.overallFeeling)/5")
                                .font(AppFont.label.font)
                                .foregroundStyle(AppColor.accent)
                        } else {
                            Text("Tap to set")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingFeelingPicker) {
            FeelingPickerView(session: session)
        }
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

private struct FeelingPickerView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text("How did this workout feel?")
                    .font(AppFont.sectionHeader.font)

                HStack(spacing: AppSpacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            try? modelContext.save()
                            dismiss()
                        }
                        .font(AppFont.sectionHeader.font)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? AppColor.accent : AppColor.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : AppColor.textPrimary)
                        .clipShape(Circle())
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let session = (try? container.mainContext.fetch(FetchDescriptor<WorkoutSession>()))?.first

        return Group {
            if let session {
                SessionDetailView(session: session, templateName: "Push")
                    .modelContainer(container)
            }
        }
    }
}
