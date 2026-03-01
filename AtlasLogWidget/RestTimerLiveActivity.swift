//
//  RestTimerLiveActivity.swift
//  AtlasLogWidget
//
//  Live Activity view for rest timer (Lock Screen / Dynamic Island).
//  ActivityKit is iOS-only; this file is compiled only for iOS.
//

#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimerLiveActivityView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        VStack(spacing: 4) {
            Text("Rest")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(timerInterval: context.state.endDate, countsDown: true)
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
        }
        .padding()
    }
}
#endif
