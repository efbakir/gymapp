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
                TextField("e.g. Upper Body A", text: $template.name)
                    .font(AppFont.body.font)
                    .frame(minHeight: 44)
            }
            .listRowBackground(AppColor.cardBackground)
            .listRowSeparator(.hidden)

            Section {
                if orderedExercises.isEmpty {
                    Text("Add exercises to build this day.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .listRowSeparator(.hidden)
                }

                ForEach(orderedExercises, id: \.id) { exercise in
                    HStack(spacing: AppSpacing.sm) {
                        AppIcon.reorder.image(size: 15)
                            .foregroundStyle(AppColor.textSecondary.opacity(0.85))
                            .frame(width: 20, alignment: .leading)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(exercise.displayName)
                                .font(AppFont.body.font)
                            if !exercise.aliases.isEmpty {
                                Text(exercise.aliases.joined(separator: ", "))
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                    .frame(minHeight: 44)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: removeExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingAddExercise = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        AppIcon.addCircle.image()
                        Text("Add Exercise")
                    }
                    .font(AppFont.sectionHeader.font)
                    .frame(minHeight: 44)
                }
                .foregroundStyle(AppColor.accent)
                .listRowSeparator(.hidden)
            } header: {
                Text("Exercises")
            } footer: {
                Text("Drag and drop to reorder. Search matches display name and aliases.")
            }
            .listRowBackground(AppColor.cardBackground)
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, AppSpacing.md, for: .scrollContent)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Training Day" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.accent)
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
                            HStack(spacing: AppSpacing.sm) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(exercise.displayName)
                                        .font(AppFont.body.font)
                                        .foregroundStyle(AppColor.textPrimary)
                                    if !exercise.aliases.isEmpty {
                                        Text(exercise.aliases.joined(separator: " • "))
                                            .font(AppFont.caption.font)
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                }
                                Spacer()
                                AppIcon.add.image()
                                    .foregroundStyle(AppColor.accent)
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                    }

                    if filteredExercises.isEmpty {
                        Text("No matching exercises")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(minHeight: 44)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Text("Results")
                }
                .listRowBackground(AppColor.cardBackground)

                if !trimmedQuery.isEmpty && !hasExactNameMatch {
                    Section("Create") {
                        TextField("Aliases (optional, comma separated)", text: $aliasesText)
                            .frame(minHeight: 44)
                            .listRowSeparator(.hidden)
                        Button {
                            createAndAdd()
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                AppIcon.addCircle.image()
                                Text("Create \"\(trimmedQuery)\"")
                            }
                            .foregroundStyle(AppColor.accent)
                            .frame(minHeight: 44)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listRowBackground(AppColor.cardBackground)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search by name or alias")
            .tint(AppColor.accent)
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
