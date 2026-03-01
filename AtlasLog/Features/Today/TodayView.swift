//
//  TodayView.swift
//  AtlasLog
//
//  Home: split/day cards with glanceable data and one-tap workout start.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @StateObject private var viewModel = TodayDashboardViewModel()

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    private var orderedTemplates: [DayTemplate] {
        var ordered: [DayTemplate] = []
        let templateByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })

        for split in splits {
            for templateID in split.orderedTemplateIds {
                if let template = templateByID[templateID], !ordered.contains(where: { $0.id == template.id }) {
                    ordered.append(template)
                }
            }
        }

        let remaining = templates
            .filter { template in
                !ordered.contains(where: { $0.id == template.id })
            }
            .sorted { $0.name < $1.name }

        return ordered + remaining
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    ActiveWorkoutView(session: session)
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Home")
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text("Today")
                        .font(AtlasTheme.Typography.hero)
                    Text("Tap a day card to start instantly.")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                }

                if orderedTemplates.isEmpty {
                    Text("No day templates yet. Build your split in Program.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                } else {
                    ForEach(orderedTemplates, id: \.id) { template in
                        let session = viewModel.lastCompletedSession(for: template.id, in: sessions)
                        DayCardView(
                            title: template.name,
                            splitName: viewModel.splitName(for: template, in: splits),
                            lastPerformed: viewModel.lastPerformedLabel(date: session?.date),
                            topLift: viewModel.topLiftSummary(
                                from: session,
                                exercises: exercises
                            )
                        ) {
                            startWorkout(template)
                        }
                    }
                }
            }
            .padding(AtlasTheme.Spacing.md)
        }
        .background(AtlasTheme.Colors.background)
    }

    private func startWorkout(_ template: DayTemplate) {
        let session = WorkoutSession(
            date: Date(),
            templateId: template.id,
            isCompleted: false,
            overallFeeling: 0
        )
        modelContext.insert(session)
        template.lastPerformedDate = session.date
        try? modelContext.save()
    }
}

private struct DayCardView: View {
    let title: String
    let splitName: String
    let lastPerformed: String
    let topLift: String
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        Text(title)
                            .font(AtlasTheme.Typography.sectionTitle)
                            .foregroundStyle(AtlasTheme.Colors.textPrimary)
                        Text(splitName)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AtlasTheme.Colors.accent)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
                        Text("Last performed")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Text(lastPerformed)
                            .font(AtlasTheme.Typography.body)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: AtlasTheme.Spacing.xxs) {
                        Text("Top lift")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Text(topLift)
                            .font(AtlasTheme.Typography.body)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.lg, style: .continuous))
            .atlasCardStyle()
        }
        .buttonStyle(AtlasScaleButtonStyle())
        .accessibilityHint("Starts workout with one tap")
    }
}

@MainActor
final class TodayDashboardViewModel: ObservableObject {
    func splitName(for template: DayTemplate, in splits: [Split]) -> String {
        guard let splitID = template.splitId,
              let split = splits.first(where: { $0.id == splitID }) else {
            return "Custom Split"
        }
        return split.name
    }

    func lastCompletedSession(for templateID: UUID, in sessions: [WorkoutSession]) -> WorkoutSession? {
        sessions.first { $0.templateId == templateID && $0.isCompleted }
    }

    func lastPerformedLabel(date: Date?) -> String {
        guard let date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func topLiftSummary(from session: WorkoutSession?, exercises: [Exercise]) -> String {
        guard let session else { return "No data" }

        let candidate = session.setEntries
            .filter { $0.isCompleted }
            .max { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.reps < rhs.reps
                }
                return lhs.weight < rhs.weight
            }

        guard let entry = candidate else { return "No data" }
        let name = exercises.first(where: { $0.id == entry.exerciseId })?.displayName ?? "Lift"
        let shortName = name.components(separatedBy: " ").prefix(2).joined(separator: " ")
        return "\(shortName): \(formatWeight(entry.weight))kg × \(entry.reps)"
    }

    private func formatWeight(_ weight: Double) -> String {
        weight == floor(weight) ? "\(Int(weight))" : String(format: "%.1f", weight)
    }
}

private struct AtlasScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
