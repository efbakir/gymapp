//
//  TemplateDetailView.swift
//  Unit
//
//  View/edit a day template: rename, reorder exercises, and type-to-create.
//

import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Bindable var template: DayTemplate

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @State private var showingAddExercise = false

    private var orderedExercises: [Exercise] {
        template.orderedExerciseIds.compactMap { id in
            exercises.first(where: { $0.id == id })
        }
    }

    var body: some View {
        List {
            Section("Day") {
                TextField("Template name", text: $template.name)
                    .font(AtlasTheme.Typography.body)
                    .frame(minHeight: 44)
            }

            Section {
                ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        Text("\(index + 1).")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(width: 24, alignment: .leading)
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                            Text(exercise.displayName)
                                .font(AtlasTheme.Typography.body)
                            if !exercise.aliases.isEmpty {
                                Text(exercise.aliases.joined(separator: ", "))
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            }
                        }
                    }
                    .frame(minHeight: 44)
                }
                .onDelete(perform: removeExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .frame(minHeight: 44)
                }
                .foregroundStyle(AtlasTheme.Colors.accent)
            } header: {
                Text("Exercises")
            } footer: {
                Text("Drag and drop to reorder. Search matches display name and aliases.")
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToTemplateView(template: template)
        }
        .onChange(of: template.name) { _, _ in
            try? modelContext.save()
        }
    }

    private func removeExercises(at offsets: IndexSet) {
        var ids = template.orderedExerciseIds
        ids.remove(atOffsets: offsets)
        template.orderedExerciseIds = ids
        try? modelContext.save()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var ids = template.orderedExerciseIds
        ids.move(fromOffsets: source, toOffset: destination)
        template.orderedExerciseIds = ids
        try? modelContext.save()
    }
}

struct AddExerciseToTemplateView: View {
    let template: DayTemplate

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @State private var query = ""
    @State private var aliasesText = ""

    private var availableExercises: [Exercise] {
        let inTemplate = Set(template.orderedExerciseIds)
        return exercises.filter { !inTemplate.contains($0.id) }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredExercises: [Exercise] {
        guard !trimmedQuery.isEmpty else { return availableExercises }
        let needle = trimmedQuery.lowercased()
        return availableExercises.filter { exercise in
            if exercise.displayName.lowercased().contains(needle) {
                return true
            }
            return exercise.aliases.contains { $0.lowercased().contains(needle) }
        }
    }

    private var hasExactNameMatch: Bool {
        exercises.contains { $0.displayName.compare(trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        Button {
                            addExercise(exercise)
                        } label: {
                            HStack(spacing: AtlasTheme.Spacing.sm) {
                                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                                    Text(exercise.displayName)
                                        .font(AtlasTheme.Typography.body)
                                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                    if !exercise.aliases.isEmpty {
                                        Text(exercise.aliases.joined(separator: " • "))
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus")
                                    .foregroundStyle(AtlasTheme.Colors.accent)
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredExercises.isEmpty {
                        Text("No matching exercises")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Results")
                }

                if !trimmedQuery.isEmpty && !hasExactNameMatch {
                    Section("Create") {
                        TextField("Aliases (optional, comma separated)", text: $aliasesText)
                            .frame(minHeight: 44)
                        Button {
                            createAndAdd()
                        } label: {
                            Label("Create \"\(trimmedQuery)\"", systemImage: "plus.circle.fill")
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .frame(minHeight: 44)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search by name or alias")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        var ids = template.orderedExerciseIds
        ids.append(exercise.id)
        template.orderedExerciseIds = ids
        try? modelContext.save()
        dismiss()
    }

    private func createAndAdd() {
        let aliases = aliasesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let exercise = Exercise(displayName: trimmedQuery, aliases: aliases)
        modelContext.insert(exercise)

        var ids = template.orderedExerciseIds
        ids.append(exercise.id)
        template.orderedExerciseIds = ids

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let template = (try? container.mainContext.fetch(FetchDescriptor<DayTemplate>()))?.first

        return Group {
            if let template {
                TemplateDetailView(template: template)
                    .modelContainer(container)
            }
        }
    }
}
