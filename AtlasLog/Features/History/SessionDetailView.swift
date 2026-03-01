//
//  SessionDetailView.swift
//  AtlasLog
//
//  Read-only session detail grouped by exercise.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    let templateName: String

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
        List {
            Section {
                Text(templateName)
                    .font(AtlasTheme.Typography.sectionTitle)
                Text(session.date, style: .date)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                Text(session.date, style: .time)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }

            ForEach(setsByExercise, id: \.exercise.id) { section in
                Section(section.exercise.displayName) {
                    ForEach(section.entries, id: \.id) { entry in
                        HStack {
                            Text("Set \(entry.setIndex + 1)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            Text("\(formatWeight(entry.weight)) kg × \(entry.reps)")
                                .font(AtlasTheme.Typography.body)
                            Spacer(minLength: 0)
                            if entry.rpe > 0 {
                                Text("RPE \(formatWeight(entry.rpe))")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                }
            }

            Section("How did it feel?") {
                Button {
                    showingFeelingPicker = true
                } label: {
                    HStack {
                        Text("Overall feeling")
                        Spacer(minLength: 0)
                        if session.overallFeeling > 0 {
                            Text("\(session.overallFeeling)/5")
                                .foregroundStyle(AtlasTheme.Colors.accent)
                        } else {
                            Text("Tap to set")
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        }
                    }
                    .frame(minHeight: 44)
                }
            }
        }
        .navigationTitle("Session")
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
            VStack(spacing: AtlasTheme.Spacing.lg) {
                Text("How did this workout feel?")
                    .font(AtlasTheme.Typography.sectionTitle)

                HStack(spacing: AtlasTheme.Spacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            try? modelContext.save()
                            dismiss()
                        }
                        .font(AtlasTheme.Typography.sectionTitle)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? AtlasTheme.Colors.accent : AtlasTheme.Colors.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : AtlasTheme.Colors.textPrimary)
                        .clipShape(Circle())
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
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
