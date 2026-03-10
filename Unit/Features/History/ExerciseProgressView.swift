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
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if let pr = allTimePR, let e1rm = epley1RM {
                    prCard(pr: pr, e1rm: e1rm)
                }

                if sessionPoints.count > 1 {
                    chartCard
                }

                if !sessionPoints.isEmpty {
                    sessionListCard
                } else {
                    Text("No data yet for \(exerciseName).")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Theme.Spacing.xl)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - PR Card

    private func prCard(pr: SessionPoint, e1rm: Double) -> some View {
        HStack(spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Best Set")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(pr.weight.weightString)kg × \(pr.reps)")
                    .font(Theme.Typography.metric)
                    .monospacedDigit()
            }
            Divider().frame(height: 36)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Est. 1RM")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(e1rm.weightString)kg")
                    .font(Theme.Typography.metric)
                    .foregroundStyle(Theme.Colors.accent)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weight Over Time")
                .font(Theme.Typography.title)

            Chart(sessionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Theme.Colors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .foregroundStyle(Theme.Colors.accent)
                .symbolSize(30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    AxisGridLine()
                        .foregroundStyle(Theme.Colors.border.opacity(0.4))
                }
            }
            .frame(height: 160)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: exerciseName)
        }
        .cardStyle()
    }

    // MARK: - Session list

    private var sessionListCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sessions")
                .font(Theme.Typography.title)

            let reversed = sessionPoints.reversed() as [SessionPoint]
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(reversed.enumerated()), id: \.element.id) { idx, point in
                    // Find the previous session for the same template
                    let prevPoint: SessionPoint? = reversed.dropFirst(idx + 1).first { $0.templateId == point.templateId }
                    sessionRow(point: point, prev: prevPoint)
                    if idx < reversed.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func sessionRow(point: SessionPoint, prev: SessionPoint?) -> some View {
        let templateName = templates.first(where: { $0.id == point.templateId })?.name ?? "Session"
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let delta = prev.map { point.weight - $0.weight }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(templateName)
                    .font(Theme.Typography.body)
                    .lineLimit(1)
                Text(fmt.string(from: point.date))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(point.weight.weightString)kg × \(point.reps)")
                    .font(Theme.Typography.body)
                    .monospacedDigit()
                if let d = delta {
                    if d > 0 {
                        Text("+\(d.weightString)kg vs. last \(templateName)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.accent)
                            .monospacedDigit()
                    } else if d < 0 {
                        Text("\(d.weightString)kg vs. last \(templateName)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.failure)
                            .monospacedDigit()
                    } else {
                        Text("= last \(templateName)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
