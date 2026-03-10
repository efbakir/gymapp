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
            VStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Day name")
                        .font(Theme.Typography.title)
                    TextField("e.g. Push", text: $name)
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
                    Text("Create Day")
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
                .preferredColorScheme(.dark)
        }
    }
}
