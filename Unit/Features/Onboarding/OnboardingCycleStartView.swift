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
    var progressStep: Int
    var progressTotal: Int
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
            ctaLabel: "Continue",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onCreateCycle
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {

                // Start options
                StartOptionRow(
                    label: "Today",
                    detail: dateFormatter.string(from: todayDate()),
                    isSelected: vm.startOption == .today
                ) {
                    selectStartOption(.today)
                }

                StartOptionRow(
                    label: "Next Monday",
                    detail: dateFormatter.string(from: nextMondayDate()),
                    isSelected: vm.startOption == .nextMonday
                ) {
                    selectStartOption(.nextMonday)
                }

                // Custom date option
                VStack(spacing: 0) {
                    StartOptionRow(
                        label: "Pick a date",
                        detail: vm.startOption == .custom ? dateFormatter.string(from: vm.customDate) : "",
                        isSelected: vm.startOption == .custom
                    ) {
                        selectStartOption(.custom)
                    }

                    if vm.startOption == .custom {
                        DatePicker(
                            "",
                            selection: $vm.customDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(AppColor.accent)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)
                    }
                }
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                // Cycle summary
                HStack {
                    AppIcon.calendarPlain.image(size: 14, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                    Text("Your 8-week cycle ends on \(dateFormatter.string(from: endDate)).")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.top, AppSpacing.sm)
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

    private func selectStartOption(_ option: OnboardingViewModel.StartOption) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            vm.startOption = option
        }
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
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppColor.accent : AppColor.border,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(AppColor.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                Spacer()
                if label == "Pick a date" {
                    AppIcon.calendarPlain.image(size: 15, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        OnboardingCycleStartView(progressStep: 6, progressTotal: 6) { }
            .environment(OnboardingViewModel())
    }
    .tint(AppColor.accent)
}
