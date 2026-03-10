//
//  TemplatesView.swift
//  Unit
//
//  Program builder: splits and day templates.
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @State private var showingAddSplit = false
    @State private var showingCycles = false

    var body: some View {
        NavigationStack {
            List {
                if splits.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Build your first split")
                                .font(Theme.Typography.title)
                            Text("Create a split, add day templates, then reorder exercises with drag-and-drop.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Button {
                                showingAddSplit = true
                            } label: {
                                Label("Create Split", systemImage: "plus.circle.fill")
                                    .font(Theme.Typography.title)
                                    .foregroundStyle(Theme.Colors.accent)
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }

                ForEach(splits, id: \.id) { split in
                    NavigationLink(value: split) {
                        SplitRow(split: split, dayCount: dayCount(for: split))
                    }
                }
                .onDelete(perform: deleteSplits)

                if !orphanTemplates.isEmpty {
                    Section("Unassigned Days") {
                        ForEach(orphanTemplates, id: \.id) { template in
                            NavigationLink(value: template) {
                                Text(template.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Program")
            .navigationDestination(for: Split.self) { split in
                SplitDetailView(split: split)
            }
            .navigationDestination(for: DayTemplate.self) { template in
                TemplateDetailView(template: template)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Exercises") {
                        ExercisesListView()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCycles = true
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                    }
                    .accessibilityLabel("Manage training cycles")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSplit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add split")
                }
            }
            .sheet(isPresented: $showingAddSplit) {
                AddSplitView()
            }
            .sheet(isPresented: $showingCycles) {
                CyclesView()
            }
        }
    }

    private var orphanTemplates: [DayTemplate] {
        templates.filter { $0.splitId == nil }
    }

    private func dayCount(for split: Split) -> Int {
        split.orderedTemplateIds.count
    }

    private func deleteSplits(at offsets: IndexSet) {
        for index in offsets {
            let split = splits[index]
            let linkedTemplates = templates.filter { $0.splitId == split.id }
            linkedTemplates.forEach { modelContext.delete($0) }
            modelContext.delete(split)
        }
        try? modelContext.save()
    }
}

private struct SplitRow: View {
    let split: Split
    let dayCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(split.name)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("\(dayCount) day\(dayCount == 1 ? "" : "s")")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .frame(minHeight: 44)
    }
}

struct SplitDetailView: View {
    @Bindable var split: Split

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @State private var showingAddDay = false

    private var orderedTemplates: [DayTemplate] {
        let byId = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let linked = split.orderedTemplateIds.compactMap { byId[$0] }
        if !linked.isEmpty {
            return linked
        }
        return templates.filter { $0.splitId == split.id }
    }

    var body: some View {
        List {
            Section("Split Name") {
                TextField("Split", text: $split.name)
                    .frame(minHeight: 44)
            }

            Section {
                ForEach(orderedTemplates, id: \.id) { template in
                    NavigationLink(value: template) {
                        Text(template.name)
                            .font(Theme.Typography.body)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                }
                .onDelete(perform: deleteDays)
                .onMove(perform: moveDays)

                Button {
                    showingAddDay = true
                } label: {
                    Label("Add Day", systemImage: "plus.circle.fill")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(minHeight: 44)
                }
            } header: {
                Text("Days")
            } footer: {
                Text("Open a day to reorder exercises.")
            }
        }
        .navigationTitle(split.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DayTemplate.self) { template in
            TemplateDetailView(template: template)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddTemplateView(split: split)
        }
        .onChange(of: split.name) { _, _ in
            try? modelContext.save()
        }
        .onAppear {
            syncTemplateOrderIfNeeded()
        }
    }

    private func syncTemplateOrderIfNeeded() {
        if split.orderedTemplateIds.isEmpty {
            split.orderedTemplateIds = templates
                .filter { $0.splitId == split.id }
                .map(\.id)
            try? modelContext.save()
        }
    }

    private func moveDays(from source: IndexSet, to destination: Int) {
        var ids = split.orderedTemplateIds
        ids.move(fromOffsets: source, toOffset: destination)
        split.orderedTemplateIds = ids
        try? modelContext.save()
    }

    private func deleteDays(at offsets: IndexSet) {
        var ids = split.orderedTemplateIds
        let targets = offsets.map { orderedTemplates[$0] }
        ids.remove(atOffsets: offsets)
        split.orderedTemplateIds = ids
        targets.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

private struct AddSplitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Split name")
                        .font(Theme.Typography.title)
                    TextField("e.g. Push / Pull / Legs", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(height: 52)
                        .background(Theme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .stroke(Theme.Colors.border, lineWidth: 0.5)
                        )
                }

                Button {
                    save()
                } label: {
                    Text("Create Split")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canSave ? Theme.Colors.accent : Color.gray.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let split = Split(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(split)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TemplatesView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.dark)
}
