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
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]
    @State private var expandedDayIDs: Set<UUID> = []
    @State private var showingProgramSwitcher = false
    @State private var showingProgramRename = false
    @State private var showingCycleRename = false
    @State private var showingOnboarding = false
    @State private var programNameDraft = ""
    @State private var cycleNameDraft = ""

    private var availableCycles: [Cycle] {
        cycles.filter { !$0.isCompleted && $0.splitId != nil }
    }

    private var activeCycle: Cycle? {
        availableCycles.first(where: { $0.isActive }) ?? availableCycles.first
    }

    private var activeSplit: Split? {
        if let splitId = activeCycle?.splitId {
            return splits.first(where: { $0.id == splitId })
        }
        return splits.first
    }

    private func orderedTemplates(for split: Split) -> [DayTemplate] {
        let byId = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let linked = split.orderedTemplateIds.compactMap { byId[$0] }
        if !linked.isEmpty {
            return linked
        }
        return templates.filter { $0.splitId == split.id }
    }

    var body: some View {
        NavigationStack {
            AppScreen(title: "Program") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let split = activeSplit {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            NavigationLink(value: split) {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("ACTIVE PROGRAM")
                                        .font(AppFont.overline)
                                        .tracking(1.0)
                                        .foregroundStyle(AppColor.textSecondary)
                                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                                        Text(split.name)
                                            .font(AppFont.largeTitle.font)
                                            .foregroundStyle(AppColor.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    Text(programSummary(for: split))
                                        .font(AppFont.caption.font)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: AppSpacing.sm) {
                                if availableCycles.count > 1 {
                                    Button {
                                        showingProgramSwitcher = true
                                    } label: {
                                        HStack(spacing: AppSpacing.xs) {
                                            AppIcon.swap.image()
                                            Text("Switch Program")
                                        }
                                        .font(AppFont.captionBold.font)
                                        .foregroundStyle(AppColor.accent)
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(AppColor.accentSoft)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    programNameDraft = split.name
                                    showingProgramRename = true
                                } label: {
                                    HStack(spacing: AppSpacing.xs) {
                                        AppIcon.edit.image()
                                        Text("Rename Program")
                                    }
                                    .font(AppFont.captionBold.font)
                                    .foregroundStyle(AppColor.accent)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColor.accentSoft)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                if activeCycle != nil {
                                    Button {
                                        cycleNameDraft = activeCycle?.name ?? ""
                                        showingCycleRename = true
                                    } label: {
                                        HStack(spacing: AppSpacing.xs) {
                                            AppIcon.editLine.image()
                                            Text("Rename Cycle")
                                        }
                                        .font(AppFont.captionBold.font)
                                        .foregroundStyle(AppColor.accent)
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(AppColor.accentSoft)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .appCardStyle()

                        let days = orderedTemplates(for: split)
                        if days.isEmpty {
                            Text("No days in this program yet.")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appCardStyle()
                        } else {
                            ForEach(days, id: \.id) { template in
                                dayCard(template)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Build your first split")
                                .font(AppFont.sectionHeader.font)
                            Text("Create a split, add day templates, and launch your first auto-adjusting cycle.")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            AppPrimaryButton("Create Split") {
                                showingOnboarding = true
                            }
                        }
                        .appCardStyle()
                    }
                }
            }
            .navigationDestination(for: Split.self) { split in
                SplitDetailView(split: split)
            }
            .navigationDestination(for: DayTemplate.self) { template in
                TemplateDetailView(template: template)
            }
            .navigationDestination(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .tint(AppColor.accent)
            .sheet(isPresented: $showingProgramSwitcher) {
                ProgramSwitcherSheet(
                    cycles: availableCycles,
                    currentCycleID: activeCycle?.id,
                    splitName: splitName(for:),
                    onSelect: setActiveCycle
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.cardBackground)
            }
            .alert("Rename Program", isPresented: $showingProgramRename) {
                TextField("Program name", text: $programNameDraft)
                Button("Save") {
                    renameActiveProgram()
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Rename Cycle", isPresented: $showingCycleRename) {
                TextField("Cycle name", text: $cycleNameDraft)
                Button("Save") {
                    renameActiveCycle()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func programSummary(for split: Split) -> String {
        let days = orderedTemplates(for: split)
        let dayLabel = "\(days.count) day\(days.count == 1 ? "" : "s")"
        guard let activeCycle, activeCycle.splitId == split.id else {
            return dayLabel
        }
        return "Week \(activeCycle.currentWeekNumber) of \(activeCycle.weekCount) · \(dayLabel)"
    }

    @ViewBuilder
    private func dayCard(_ template: DayTemplate) -> some View {
        let isExpanded = expandedDayIDs.contains(template.id)
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { newValue in
                    if newValue {
                        expandedDayIDs.insert(template.id)
                    } else {
                        expandedDayIDs.remove(template.id)
                    }
                }
            )
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(exercisePreview(for: template, limit: 12).enumerated()), id: \.offset) { _, exerciseName in
                    Text(exerciseName)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 28, alignment: .leading)
                }

                NavigationLink(value: template) {
                    Text("Open Day")
                        .font(AppFont.body.font.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.xs)
            }
            .padding(.top, AppSpacing.sm)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(template.name)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let preview = exercisePreview(for: template, limit: 3)
                if preview.isEmpty {
                    Text("No exercises yet")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(preview.enumerated()), id: \.offset) { _, exerciseName in
                            Text(exerciseName)
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .tint(AppColor.textPrimary)
        .appCardStyle()
    }

    private func exercisePreview(for template: DayTemplate, limit: Int) -> [String] {
        let exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.displayName) })
        return Array(template.orderedExerciseIds.compactMap { exerciseMap[$0] }.prefix(limit))
    }

    private func splitName(for cycle: Cycle) -> String {
        guard let splitId = cycle.splitId,
              let split = splits.first(where: { $0.id == splitId }) else {
            return cycle.name
        }
        return split.name
    }

    private func setActiveCycle(_ selectedCycle: Cycle) {
        for cycle in cycles where !cycle.isCompleted {
            cycle.isActive = cycle.id == selectedCycle.id
        }
        try? modelContext.save()
    }

    private func renameActiveProgram() {
        guard let split = activeSplit else { return }
        let trimmed = programNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        split.name = trimmed
        try? modelContext.save()
    }

    private func renameActiveCycle() {
        guard let cycle = activeCycle else { return }
        let trimmed = cycleNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cycle.name = trimmed
        try? modelContext.save()
    }
}

private struct ProgramSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss

    let cycles: [Cycle]
    let currentCycleID: UUID?
    let splitName: (Cycle) -> String
    let onSelect: (Cycle) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(cycles, id: \.id) { cycle in
                        Button {
                            onSelect(cycle)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                                    Text(splitName(cycle))
                                        .font(AppFont.sectionHeader.font)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    if cycle.id == currentCycleID {
                                        Text("CURRENT")
                                            .font(AppFont.badgeText)
                                            .tracking(0.8)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(AppColor.accentSoft)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(cycle.name)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)

                                Text("Week \(cycle.currentWeekNumber) of \(cycle.weekCount)")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .appCardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Choose Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SplitDetailView: View {
    @Bindable var split: Split

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Cycle.startDate, order: .reverse) private var cycles: [Cycle]
    @State private var showingCycleSettings = false

    private var orderedTemplates: [DayTemplate] {
        let byId = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let linked = split.orderedTemplateIds.compactMap { byId[$0] }
        if !linked.isEmpty {
            return linked
        }
        return templates.filter { $0.splitId == split.id }
    }

    private var activeCycle: Cycle? {
        cycles.first(where: { $0.isActive && !$0.isCompleted && $0.splitId == split.id })
            ?? cycles.first(where: { !$0.isCompleted && $0.splitId == split.id })
    }

    var body: some View {
        List {
            Section("Program") {
                TextField("e.g. Push / Pull / Legs", text: $split.name)
                    .frame(minHeight: 44)
            }
            .listRowBackground(AppColor.cardBackground)
            .listRowSeparator(.hidden)

            Section {
                ForEach(orderedTemplates, id: \.id) { template in
                    NavigationLink(value: template) {
                        Text(template.name)
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteDays)
                .onMove(perform: moveDays)
            } header: {
                Text("Days")
            } footer: {
                Text("Open a day to reorder exercises.")
            }
            .listRowBackground(AppColor.cardBackground)
            .listRowSeparator(.hidden)

            Section("Program Actions") {
                Button {
                    editMode?.wrappedValue = .active
                } label: {
                    Text("Edit split structure")
                        .font(AppFont.body.font.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)

                if activeCycle != nil {
                    Button {
                        showingCycleSettings = true
                    } label: {
                        Text("Advanced progression settings")
                            .font(AppFont.body.font.weight(.semibold))
                            .foregroundStyle(AppColor.accent)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
            .listRowBackground(AppColor.cardBackground)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, AppSpacing.md, for: .scrollContent)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(split.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Split" : split.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DayTemplate.self) { template in
            TemplateDetailView(template: template)
        }
        .tint(AppColor.accent)
        .sheet(isPresented: $showingCycleSettings) {
            if let activeCycle {
                CycleSettingsView(cycle: activeCycle)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.cardBackground)
            }
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
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Split name")
                        .font(AppFont.sectionHeader.font)
                    TextField("e.g. Push / Pull / Legs", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 52)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 0.5)
                        )
                }

                Button {
                    save()
                } label: {
                    Text("Create Split")
                        .font(AppFont.label.font)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .opacity(canSave ? 1 : 0.6)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppColor.accent)
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
}
