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
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.lg) {
                if let pr = allTimePR, let e1rm = epley1RM {
                    prCard(pr: pr, e1rm: e1rm)
                }

                if sessionPoints.count > 1 {
                    chartCard
                }

                if !sessionPoints.isEmpty {
                    sessionListCard
                } else {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Text("No data yet for \(exerciseName).")
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasTheme.Spacing.xl)
                }
            }
            .padding(AtlasTheme.Spacing.md)
        }
        .background(AtlasTheme.Colors.background)
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - PR Card

    private func prCard(pr: SessionPoint, e1rm: Double) -> some View {
        HStack(spacing: AtlasTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                Text("Best Set")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                Text("\(pr.weight.weightString)kg × \(pr.reps)")
                    .font(AtlasTheme.Typography.metric)
                    .monospacedDigit()
            }
            Divider().frame(height: 36)
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                Text("Est. 1RM")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                Text("\(e1rm.weightString)kg")
                    .font(AtlasTheme.Typography.metric)
                    .foregroundStyle(AtlasTheme.Colors.accent)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .atlasCardStyle()
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("Weight Over Time")
                .font(AtlasTheme.Typography.sectionTitle)

            Chart(sessionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(AtlasTheme.Colors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .foregroundStyle(AtlasTheme.Colors.accent)
                .symbolSize(30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    AxisGridLine()
                        .foregroundStyle(AtlasTheme.Colors.border.opacity(0.4))
                }
            }
            .frame(height: 160)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: exerciseName)
        }
        .atlasCardStyle()
    }

    // MARK: - Session list

    private var sessionListCard: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("Sessions")
                .font(AtlasTheme.Typography.sectionTitle)

            let reversed = sessionPoints.reversed() as [SessionPoint]
            VStack(spacing: AtlasTheme.Spacing.xs) {
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
        .atlasCardStyle()
    }

    private func sessionRow(point: SessionPoint, prev: SessionPoint?) -> some View {
        let templateName = templates.first(where: { $0.id == point.templateId })?.name ?? "Session"
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let delta = prev.map { point.weight - $0.weight }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(templateName)
                    .font(AtlasTheme.Typography.body)
                    .lineLimit(1)
                Text(fmt.string(from: point.date))
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(point.weight.weightString)kg × \(point.reps)")
                    .font(AtlasTheme.Typography.body)
                    .monospacedDigit()
                if let d = delta {
                    if d > 0 {
                        Text("+\(d.weightString)kg vs. last \(templateName)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.accent)
                            .monospacedDigit()
                    } else if d < 0 {
                        Text("\(d.weightString)kg vs. last \(templateName)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.failureAccent)
                            .monospacedDigit()
                    } else {
                        Text("= last \(templateName)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
