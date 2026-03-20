//
//  AppAtoms.swift
//  Unit
//
//  Five-Tier UI — Layer 1: Atoms
//  The single source of truth for colors, typography, spacing, radius, shadows, icons, divider.
//  No raw hex, raw font, raw spacing, or raw SF Symbol outside this file.
//

import SwiftUI
import UIKit

// MARK: - AppColor

enum AppColor {
    // Surfaces
    static let background      = Color(uiColor: uicolorAdaptive(light: 0xF2F2F7, dark: 0x000000))
    static let surface         = Color(uiColor: uicolorAdaptive(light: 0xFFFFFF, dark: 0x1C1C1E))
    static let cardBackground  = Color(uiColor: uicolorAdaptive(light: 0xFFFFFF, dark: 0x1C1C1E))

    // Text
    static let textPrimary     = Color(uiColor: uicolorAdaptive(light: 0x000000, dark: 0xFFFFFF))
    static let textSecondary   = Color(uiColor: uicolorAdaptive(light: 0x8E8E93, dark: 0x8E8E93))
    static let mutedText       = Color(uiColor: uicolorAdaptive(light: 0x8E8E93, dark: 0x636366))

    // Interactive
    static let accent          = Color(uiColor: uicolorAdaptive(light: 0x000000, dark: 0xFFFFFF))
    static let accentSoft      = Color(uiColor: uicolorAccentSoft())
    static let onboardingAccent = Color(uiColor: uicolorAdaptive(light: 0xFF8A1F, dark: 0xFF8A1F))
    static let disabled        = Color(uiColor: uicolorAdaptive(light: 0x8E8E93, dark: 0x636366))
    static let border          = Color(uiColor: uicolorAdaptive(light: 0xF2F2F7, dark: 0x38383A))

    // Status
    static let success         = Color(uiColor: uicolorAdaptive(light: 0x34C759, dark: 0x30D158))
    static let error           = Color(uiColor: uicolorAdaptive(light: 0xFF3B30, dark: 0xFF453A))
    static let warning         = Color(uiColor: uicolorAdaptive(light: 0xFF9500, dark: 0xFF9F0A))

    /// UIKit may resolve dynamic `UIColor` providers off the main thread (e.g. SwiftUI async renderer).
    /// These factories are `nonisolated` so the trait closure is not MainActor-isolated.
    private nonisolated static func uicolorAdaptive(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red:   CGFloat((hex & 0xFF0000) >> 16) / 255,
                green: CGFloat((hex & 0x00FF00) >> 8)  / 255,
                blue:  CGFloat( hex & 0x0000FF)        / 255,
                alpha: 1
            )
        }
    }

    private nonisolated static func uicolorAccentSoft() -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(white: 0, alpha: 0.06)
        }
    }
}

// MARK: - AppFont

enum AppFont {
    case heroDisplay      // 52pt black — splash
    case largeTitle       // title2 bold
    case title            // title3 semibold
    case sectionHeader    // headline
    case body             // body
    case label            // body semibold
    case caption          // caption
    case captionBold      // caption semibold — badges, tags
    case muted            // caption, secondary color

    var font: Font {
        switch self {
        case .heroDisplay:    return .system(size: 52, weight: .black)
        case .largeTitle:     return .system(.title2).weight(.bold)
        case .title:          return .system(.title3).weight(.semibold)
        case .sectionHeader:  return .system(.headline)
        case .body:           return .system(.body)
        case .label:          return .system(.body).weight(.semibold)
        case .caption:        return .system(.caption)
        case .captionBold:    return .system(.caption).weight(.semibold)
        case .muted:          return .system(.caption)
        }
    }

    var color: Color {
        switch self {
        case .muted: return AppColor.textSecondary
        default:     return AppColor.textPrimary
        }
    }

    // Specialised fonts for numeric/metric contexts
    static let numericDisplay: Font = .system(size: 36, weight: .bold).monospacedDigit()
    static let numericLarge: Font = .system(size: 28, weight: .bold).monospacedDigit()
    static let numericTimer: Font = .system(size: 13, weight: .semibold).monospacedDigit()
    static let overline: Font = .system(size: 10, weight: .semibold)
    static let badgeText: Font = .system(size: 10, weight: .bold)
    static let smallLabel: Font = .system(size: 11, weight: .medium)
    static let tinyBold: Font = .system(size: 11, weight: .bold)
}

// MARK: - AppSpacing

enum AppSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
}

// MARK: - AppRadius

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - AppShadow

enum AppShadow {
    static func card(_ scheme: ColorScheme) -> some View {
        EmptyView()
            .shadow(
                color: scheme == .dark ? .white.opacity(0.04) : .black.opacity(0.06),
                radius: 8, x: 0, y: 2
            )
    }

    static let cardRadius: CGFloat = 8
    static let cardOpacityLight: Double = 0.06
    static let cardOpacityDark: Double = 0.04
}

// MARK: - AppIcon

enum AppIcon: String {
    // Navigation
    case back               = "arrow.left"
    case forward            = "arrow.right"
    case close              = "xmark"

    // Actions
    case add                = "plus"
    case remove             = "minus"
    case edit               = "pencil"
    case editLine           = "pencil.line"
    case swap               = "arrow.triangle.2.circlepath"
    case clearField         = "xmark.circle"
    case search             = "magnifyingglass"

    // Tab bar
    case home               = "house.fill"
    case program            = "square.grid.2x2.fill"
    case settings           = "gearshape.fill"
    case settingsOutline    = "gearshape"

    // Status
    case checkmarkFilled    = "checkmark.circle.fill"
    case checkmark          = "checkmark"
    case xmarkFilled        = "xmark.circle.fill"
    case failCircle         = "xmark.square.fill"

    // Features
    case timer              = "timer"
    case list               = "list.bullet"
    case calendarClock      = "calendar.badge.clock"
    case calendarPlain      = "calendar"
    case cloud              = "icloud.fill"
    case bolt               = "bolt.fill"
    case progression        = "arrow.up.right.circle.fill"
    case target             = "target"
    case chart              = "chart.line.uptrend.xyaxis"
    case deload             = "arrow.down.circle.fill"
    case addCircle          = "plus.circle.fill"

    // Content
    case sliders            = "slider.horizontal.3"
    case photo              = "photo"
    case dumbbell           = "dumbbell"
    case trophy             = "trophy"
    case reorder            = "line.3.horizontal"
    case applelogo          = "applelogo"
    case camera             = "camera"
    case clipboard          = "doc.on.clipboard"
    case keyboard           = "keyboard"

    var systemName: String { rawValue }

    /// Render as an Image view at the given size and weight.
    func image(size: CGFloat = 17, weight: Font.Weight = .semibold) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: weight))
    }
}

// MARK: - AppDivider

struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColor.border)
            .frame(height: 0.5)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Double Formatting

extension Double {
    /// Format as weight string: whole numbers as integers, fractional as 1 decimal place.
    /// e.g. 100.0 → "100", 92.5 → "92.5"
    var weightString: String {
        self == floor(self) ? "\(Int(self))" : String(format: "%.1f", self)
    }
}
