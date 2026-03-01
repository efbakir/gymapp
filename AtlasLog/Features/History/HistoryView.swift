//
//  HistoryView.swift
//  AtlasLog
//
//  History tab: completed workout sessions.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    var body: some View {
        NavigationStack {
            List {
                if completedSessions.isEmpty {
                    Text("No completed sessions yet.")
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .frame(minHeight: 44)
                } else {
                    ForEach(completedSessions, id: \.id) { session in
                        NavigationLink(value: session) {
                            SessionRow(session: session, templateName: templateName(for: session.templateId))
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session, templateName: templateName(for: session.templateId))
            }
        }
    }

    private func templateName(for templateID: UUID) -> String {
        templates.first { $0.id == templateID }?.name ?? "Unknown"
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    let templateName: String

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
            Text(templateName)
                .font(AtlasTheme.Typography.sectionTitle)
            Text(dateText)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            if session.overallFeeling > 0 {
                Text("Feeling: \(session.overallFeeling)/5")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.xs)
        .frame(minHeight: 44, alignment: .leading)
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
