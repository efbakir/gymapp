//
//  OnboardingSplitBuilderView.swift
//  Unit
//
//  Screen 4 — Define training split: number of days and a name for each.
//  Creates the conceptual Split + DayTemplate structure (committed later).
//

import SwiftUI

struct OnboardingSplitBuilderView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onContinue: () -> Void

    private let suggestions = ["Push", "Pull", "Legs", "Upper", "Lower", "Full Body", "Back & Bi", "Chest & Tri"]
    @FocusState private var focusedDay: Int?

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Your training split",
            ctaLabel: "Continue",
            ctaEnabled: vm.splitIsValid,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.lg) {

                // Day count stepper
                HStack {
                    Text("Days per week")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                    Spacer()
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        Button {
                            vm.updateDayCount(vm.dayCount - 1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(AtlasTheme.Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.sm, style: .continuous))
                                .foregroundStyle(vm.dayCount <= 2 ? AtlasTheme.Colors.disabled : AtlasTheme.Colors.textPrimary)
                        }
                        .disabled(vm.dayCount <= 2)

                        Text("\(vm.dayCount)")
                            .font(AtlasTheme.Typography.metric)
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                            .frame(minWidth: 24, alignment: .center)

                        Button {
                            vm.updateDayCount(vm.dayCount + 1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(AtlasTheme.Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.sm, style: .continuous))
                                .foregroundStyle(vm.dayCount >= 6 ? AtlasTheme.Colors.disabled : AtlasTheme.Colors.textPrimary)
                        }
                        .disabled(vm.dayCount >= 6)
                    }
                }
                .padding(AtlasTheme.Spacing.md)
                .background(AtlasTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))

                // Day name fields
                VStack(spacing: AtlasTheme.Spacing.xs) {
                    ForEach(0..<vm.dayCount, id: \.self) { i in
                        HStack(spacing: AtlasTheme.Spacing.sm) {
                            Text("Day \(i + 1)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                .frame(width: 44, alignment: .leading)

                            TextField("Name", text: $vm.dayNames[i])
                                .font(AtlasTheme.Typography.body)
                                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                .focused($focusedDay, equals: i)
                                .submitLabel(i < vm.dayCount - 1 ? .next : .done)
                                .onSubmit {
                                    if i < vm.dayCount - 1 { focusedDay = i + 1 }
                                    else { focusedDay = nil }
                                }
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .frame(height: 48)
                        .background(AtlasTheme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                                .stroke(focusedDay == i ? AtlasTheme.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }

                // Suggestion chips
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text("SUGGESTIONS")
                        .font(AtlasTheme.Typography.overline)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .tracking(1.0)

                    FlowLayout(spacing: AtlasTheme.Spacing.xs) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                if let day = focusedDay, day < vm.dayNames.count {
                                    vm.dayNames[day] = suggestion
                                } else if let emptyIdx = vm.dayNames.indices.first(where: { vm.dayNames[$0].trimmingCharacters(in: .whitespaces).isEmpty }) {
                                    vm.dayNames[emptyIdx] = suggestion
                                    focusedDay = emptyIdx
                                }
                            } label: {
                                Text(suggestion)
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                    .padding(.horizontal, AtlasTheme.Spacing.sm)
                                    .padding(.vertical, AtlasTheme.Spacing.xxs)
                                    .background(AtlasTheme.Colors.card)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AtlasTheme.Colors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingSplitBuilderView { }
            .environment(OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
