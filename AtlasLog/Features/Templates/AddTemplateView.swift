//
//  AddTemplateView.swift
//  Unit
//
//  Create a new day template inside a split.
//

import SwiftUI
import SwiftData

struct AddTemplateView: View {
    let split: Split

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Day name")
                        .font(AtlasTheme.Typography.sectionTitle)
                    TextField("e.g. Push", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .frame(height: 52)
                        .background(AtlasTheme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                                .stroke(AtlasTheme.Colors.border, lineWidth: 1)
                        )
                }

                Button {
                    save()
                } label: {
                    Text("Create Day")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canSave ? AtlasTheme.Colors.accent : Color.gray.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Spacer(minLength: 0)
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("New Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let template = DayTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            splitId: split.id
        )
        modelContext.insert(template)

        var ids = split.orderedTemplateIds
        ids.append(template.id)
        split.orderedTemplateIds = ids

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = PreviewSampleData.makePreviewContainer()
    let split = (try? container.mainContext.fetch(FetchDescriptor<Split>()))?.first

    return Group {
        if let split {
            AddTemplateView(split: split)
                .modelContainer(container)
        }
    }
}
