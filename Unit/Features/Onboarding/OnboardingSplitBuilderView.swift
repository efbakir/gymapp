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
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void

    private let suggestions = ["Push", "Pull", "Legs", "Upper", "Lower", "Full Body", "Back & Bi", "Chest & Tri"]
    @FocusState private var focusedDay: Int?

    private func dayNameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard vm.dayNames.indices.contains(index) else { return "" }
                return vm.dayNames[index]
            },
            set: { newValue in
                guard vm.dayNames.indices.contains(index) else { return }
                vm.dayNames[index] = newValue
            }
        )
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Your training split",
            ctaLabel: "Continue",
            ctaEnabled: vm.splitIsValid,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                // Day count stepper
                HStack {
                    Text("Days per week")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            vm.updateDayCount(vm.dayCount - 1)
                        } label: {
                            AppIcon.remove.image(size: 14, weight: .semibold)
                                .frame(width: 36, height: 36)
                                .background(AppColor.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                                .foregroundStyle(vm.dayCount <= 2 ? AppColor.disabled : AppColor.textPrimary)
                        }
                        .disabled(vm.dayCount <= 2)

                        Text("\(vm.dayCount)")
                            .font(AppFont.title.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(minWidth: 24, alignment: .center)

                        Button {
                            vm.updateDayCount(vm.dayCount + 1)
                        } label: {
                            AppIcon.add.image(size: 14, weight: .semibold)
                                .frame(width: 36, height: 36)
                                .background(AppColor.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                                .foregroundStyle(vm.dayCount >= 6 ? AppColor.disabled : AppColor.textPrimary)
                        }
                        .disabled(vm.dayCount >= 6)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                // Day name fields
                VStack(spacing: AppSpacing.sm) {
                    ForEach(0..<vm.dayCount, id: \.self) { i in
                        HStack(spacing: AppSpacing.sm) {
                            Text("Day \(i + 1)")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(width: 44, alignment: .leading)

                            TextField("Name", text: dayNameBinding(for: i))
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textPrimary)
                                .focused($focusedDay, equals: i)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(i < vm.dayCount - 1 ? .next : .done)
                                .onSubmit {
                                    if i < vm.dayCount - 1 { focusedDay = i + 1 }
                                    else { focusedDay = nil }
                                }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 48)
                        .background(AppColor.cardBackground)
                        .contentShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(focusedDay == i ? AppColor.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .onTapGesture {
                            focusedDay = i
                        }
                    }
                }

                // Suggestion chips
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("SUGGESTIONS")
                        .font(AppFont.overline)
                        .foregroundStyle(AppColor.textSecondary)
                        .tracking(1.0)

                    FlowLayout(spacing: AppSpacing.sm) {
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
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColor.cardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AppColor.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: vm.dayCount) { _, newValue in
            guard let focusedDay else { return }
            if focusedDay >= newValue {
                self.focusedDay = max(0, newValue - 1)
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
        OnboardingSplitBuilderView(progressStep: 2, progressTotal: 6) { }
            .environment(OnboardingViewModel())
    }
    .tint(AppColor.accent)
}
