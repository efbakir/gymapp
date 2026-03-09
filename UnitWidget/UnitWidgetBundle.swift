//
//  UnitWidgetBundle.swift
//  Unit
//
//  Live Activities (ActivityKit) are iOS-only. On macOS this bundle exposes a no-op widget.
//

import WidgetKit
import SwiftUI

@main
struct UnitWidgetBundle: WidgetBundle {
    var body: some Widget {
        #if os(iOS)
        RestTimerLiveActivityWidget()
        #else
        RestTimerPlaceholderWidget()
        #endif
    }
}

#if os(iOS)
struct RestTimerLiveActivityWidget: Widget {
    let kind: String = "RestTimerLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            RestTimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.state.endDate, countsDown: true)
                        .font(.title2.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.leading) {
                    Text("Rest")
                        .font(.caption)
                }
            } compactLeading: {
                Text("Rest")
                    .font(.caption2)
            } compactTrailing: {
                Text(timerInterval: context.state.endDate, countsDown: true)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
#else
/// Placeholder so the bundle compiles on macOS; Live Activities are iOS-only.
struct RestTimerPlaceholderWidget: Widget {
    let kind: String = "RestTimerPlaceholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RestTimerPlaceholderProvider()) { _ in
            EmptyView()
        }
        .configurationDisplayName("Rest Timer")
        .description("Rest timer runs on iOS only.")
    }
}

struct RestTimerPlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmptyEntry { EmptyEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (EmptyEntry) -> Void) { completion(EmptyEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<EmptyEntry>) -> Void) { completion(Timeline(entries: [EmptyEntry(date: Date())], policy: .never)) }
}

struct EmptyEntry: TimelineEntry {
    let date: Date
}
#endif
