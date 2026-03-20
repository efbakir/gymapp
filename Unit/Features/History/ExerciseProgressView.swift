//
//  ExerciseProgressView.swift
//  Unit
//
//  Exercise-focused progress: PR stat, weight timeline chart, per-session delta list.
//

import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exerciseId: UUID
    let exerciseName: String
    let sessions: [WorkoutSession]
    let templates: [DayTemplate]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct SessionPoint: Identifiable {
        let id: UUID
        let date: Date
        let weight: Double
        let reps: Int
        let templateId: UUID
    }

    // Best set per completed session (highest weight, then reps)
    private var sessionPoints: [SessionPoint] {
        sessions
            .filter(\.isCompleted)
            .compactMap { session -> SessionPoint? in
                let best = session.setEntries
                    .filter { $0.exerciseId == exerciseId && $0.isCompleted && !$0.isWarmup }
                    .max { lhs, rhs in lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight }
                guard let best else { return nil }
                return SessionPoint(id: session.id, date: session.date, weight: best.weight, reps: best.reps, templateId: session.templateId)
            }
            .sorted { $0.date < $1.date }
    }

    private var allTimePR: SessionPoint? {
        sessionPoints.max { lhs, rhs in lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight }
    }

    private var epley1RM: Double? {
        guard let pr = allTimePR else { return nil }
        guard pr.reps > 1 else { return pr.weight }
        return pr.weight * (1.0 + Double(pr.reps) / 30.0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let pr = allTimePR, let e1rm = epley1RM {
                    prCard(pr: pr, e1rm: e1rm)
                }

                if sessionPoints.count > 1 {
                    chartCard
                }

                if !sessionPoints.isEmpty {
                    sessionListCard
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        AppIcon.chart.image(size: 32, weight: .light)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("No data yet for \(exerciseName).")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - PR Card

    private func prCard(pr: SessionPoint, e1rm: Double) -> some View {
        HStack(spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Best Set")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                Text("\(pr.weight.weightString)kg × \(pr.reps)")
                    .font(AppFont.title.font)
                    .monospacedDigit()
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Est. 1RM")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                Text("\(e1rm.weightString)kg")
                    .font(AppFont.title.font)
                    .foregroundStyle(AppColor.accent)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .appCardStyle()
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Weight Over Time")
                .font(AppFont.sectionHeader.font)

            Chart(sessionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(AppColor.textPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .foregroundStyle(AppColor.textPrimary)
                .symbolSize(30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                    AxisGridLine()
                        .foregroundStyle(AppColor.border.opacity(0.4))
                }
            }
            .frame(height: 160)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: exerciseName)
        }
        .appCardStyle()
    }

    // MARK: - Session list

    private var sessionListCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Sessions")
                .font(AppFont.sectionHeader.font)

            let reversed = sessionPoints.reversed() as [SessionPoint]
            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(reversed.enumerated()), id: \.element.id) { idx, point in
                    // Find the previous session for the same template
                    let prevPoint: SessionPoint? = reversed.dropFirst(idx + 1).first { $0.templateId == point.templateId }
                    sessionRow(point: point, prev: prevPoint)
                    if idx < reversed.count - 1 {
                        AppDivider()
                    }
                }
            }
        }
        .appCardStyle()
    }

    private func sessionRow(point: SessionPoint, prev: SessionPoint?) -> some View {
        let templateName = templates.first(where: { $0.id == point.templateId })?.name ?? "Session"
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let delta = prev.map { point.weight - $0.weight }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(templateName)
                    .font(AppFont.body.font)
                    .lineLimit(1)
                Text(fmt.string(from: point.date))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(point.weight.weightString)kg × \(point.reps)")
                    .font(AppFont.body.font)
                    .monospacedDigit()
                if let d = delta {
                    if d > 0 {
                        Text("+\(d.weightString)kg vs. last \(templateName)")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.success)
                            .monospacedDigit()
                    } else if d < 0 {
                        Text("\(d.weightString)kg vs. last \(templateName)")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.error)
                            .monospacedDigit()
                    } else {
                        Text("= last \(templateName)")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
