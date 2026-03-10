//
//  OnboardingCycleStartView.swift
//  Unit
//
//  Screen 8 — Cycle start date.
//  This is the commit point: "Create My Cycle" writes all data to SwiftData.
//

import SwiftUI

struct OnboardingCycleStartView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var onCreateCycle: () -> Void

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var endDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 8, to: vm.startDate) ?? vm.startDate
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "When do you want to start?",
            ctaLabel: "Create My Cycle",
            onContinue: onCreateCycle
        ) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {

                // Start options
                StartOptionRow(
                    label: "Today",
                    detail: dateFormatter.string(from: todayDate()),
                    isSelected: vm.startOption == .today
                ) {
                    vm.startOption = .today
                }

                StartOptionRow(
                    label: "Next Monday",
                    detail: dateFormatter.string(from: nextMondayDate()),
                    isSelected: vm.startOption == .nextMonday
                ) {
                    vm.startOption = .nextMonday
                }

                // Custom date option
                VStack(spacing: 0) {
                    StartOptionRow(
                        label: "Pick a date",
                        detail: vm.startOption == .custom ? dateFormatter.string(from: vm.customDate) : "",
                        isSelected: vm.startOption == .custom
                    ) {
                        vm.startOption = .custom
                    }

                    if vm.startOption == .custom {
                        DatePicker(
                            "",
                            selection: $vm.customDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(AtlasTheme.Colors.accent)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .padding(.bottom, AtlasTheme.Spacing.sm)
                    }
                }
                .background(AtlasTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))

                // Cycle summary
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .font(.system(size: 14))
                    Text("Your 8-week cycle ends on \(dateFormatter.string(from: endDate)).")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
                .padding(.top, AtlasTheme.Spacing.xs)
            }
        }
    }

    private func todayDate() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func nextMondayDate() -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let days = weekday == 2 ? 7 : (9 - weekday) % 7
        return cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: Date())) ?? Date()
    }
}

// MARK: - Start Option Row

private struct StartOptionRow: View {
    let label: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AtlasTheme.Colors.accent : AtlasTheme.Colors.border,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(AtlasTheme.Colors.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textPrimary)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        OnboardingCycleStartView { }
            .environment(OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
    .tint(AtlasTheme.Colors.accent)
}
