//
//  RestTimerAttributes.swift
//  AtlasLog
//
//  ActivityKit attributes for rest timer Live Activity (Lock Screen / Dynamic Island).
//  ActivityKit is iOS-only; this type is only compiled for iOS (shared by app and widget).
//

import Foundation

#if os(iOS)
import ActivityKit

/// Attributes for the rest timer Live Activity. ContentState holds the countdown end date.
/// Include this file in both AtlasLog and AtlasLogWidgetExtension targets so the same type is used.
public struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the rest period ends; the Live Activity view can use Text(timerInterval:countsDown:).
        public var endDate: Date
    }

    /// Fixed identity for this activity.
    public var kind: String = "rest"
}
#endif
