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
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Day name")
                        .font(AppFont.sectionHeader.font)
                    TextField("e.g. Push", text: $name)
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
                    Text("Create Day")
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
            .navigationTitle("New Day")
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
