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
                    .font(Theme.Typography.title)
                Text(session.date, style: .date)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(session.date, style: .time)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .listRowBackground(AtlasTheme.Colors.elevatedBackground)

            ForEach(setsByExercise, id: \.exercise.id) { section in
                Section(section.exercise.displayName) {
                    ForEach(section.entries, id: \.id) { entry in
                        HStack {
                            Text("Set \(entry.setIndex + 1)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text("\(formatWeight(entry.weight)) kg × \(entry.reps)")
                                .font(Theme.Typography.body)
                            Spacer(minLength: 0)
                            if entry.rpe > 0 {
                                Text("RPE \(formatWeight(entry.rpe))")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                }
                .listRowBackground(AtlasTheme.Colors.elevatedBackground)
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
                                .foregroundStyle(Theme.Colors.accent)
                        } else {
                            Text("Tap to set")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .frame(minHeight: 44)
                }
            }
            .listRowBackground(AtlasTheme.Colors.elevatedBackground)
        }
        .scrollContentBackground(.hidden)
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
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
            VStack(spacing: Theme.Spacing.lg) {
                Text("How did this workout feel?")
                    .font(Theme.Typography.title)

                HStack(spacing: Theme.Spacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            try? modelContext.save()
                            dismiss()
                        }
                        .font(Theme.Typography.title)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? Theme.Colors.accent : Theme.Colors.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : Theme.Colors.textPrimary)
                        .clipShape(Circle())
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.background.ignoresSafeArea())
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
    .preferredColorScheme(.dark)
}
