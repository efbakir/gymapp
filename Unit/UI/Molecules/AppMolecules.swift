//
//  AppMolecules.swift
//  Unit
//
//  Five-Tier UI — Layer 2: Molecules
//  Small, reusable components built from atoms.
//  AppNavBar, AppListRow, AppStepper, AppTag, AppPrimaryButton, AppSecondaryButton.
//

import SwiftUI

// MARK: - NavAction

/// Tuple describing a nav-bar button (icon + callback).
struct NavAction {
    let icon: AppIcon
    let action: () -> Void
}

// MARK: - AppNavBar

/// Fixed-height, fixed-alignment nav bar. Same layout on every screen.
/// Screens never create their own navigation chrome — they pass title & actions to AppScreen.
struct AppNavBar: View {
    let title: String?
    let leadingAction: NavAction?
    let trailingAction: NavAction?

    var body: some View {
        ZStack {
            // Title — centred
            if let title {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppFont.sectionHeader.color)
                    .lineLimit(1)
            }

            // Leading / trailing
            HStack {
                if let leading = leadingAction {
                    Button(action: leading.action) {
                        leading.icon.image(size: 17, weight: .semibold)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 44)
                }

                Spacer()

                if let trailing = trailingAction {
                    Button(action: trailing.action) {
                        trailing.icon.image(size: 17, weight: .semibold)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 44)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, AppSpacing.sm)
    }
}

/// Text-based trailing action variant (e.g. "History", "Done").
struct NavTextAction {
    let label: String
    let action: () -> Void
}

/// AppNavBar variant that supports a text trailing button.
struct AppNavBarWithTextTrailing: View {
    let title: String?
    let leadingAction: NavAction?
    let trailingText: NavTextAction?

    var body: some View {
        ZStack {
            if let title {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppFont.sectionHeader.color)
                    .lineLimit(1)
            }

            HStack {
                if let leading = leadingAction {
                    Button(action: leading.action) {
                        leading.icon.image(size: 17, weight: .semibold)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 44)
                }

                Spacer()

                if let trailing = trailingText {
                    Button(action: trailing.action) {
                        Text(trailing.label)
                            .font(AppFont.label.font)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                } else {
                    Spacer().frame(width: 44)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, AppSpacing.sm)
    }
}

// MARK: - AppListRow

/// Standard row: optional leading icon, title, optional subtitle, optional trailing content.
/// Fixed padding — no per-screen overrides. No chevrons.
struct AppListRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leadingIcon: AppIcon?
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon = leadingIcon {
                icon.image(size: 15, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppFont.body.color)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppFont.muted.color)
                }
            }

            Spacer(minLength: 0)

            trailing()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

extension AppListRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, leadingIcon: AppIcon? = nil) {
        self.init(title: title, subtitle: subtitle, leadingIcon: leadingIcon) {
            EmptyView()
        }
    }
}

// MARK: - AppStepper

/// The only minus/value/plus control. Internal gap is always AppSpacing.sm.
struct AppStepper: View {
    let value: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            stepButton(icon: .remove, action: onDecrement)

            Text(value)
                .font(AppFont.label.font)
                .foregroundStyle(AppFont.label.color)
                .lineLimit(1)

            stepButton(icon: .add, action: onIncrement)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private func stepButton(icon: AppIcon, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon.image(size: 14, weight: .semibold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}

// MARK: - AppTag

/// Shared pill primitive for units, day names, status chips, and small labels.
struct AppTag: View {
    let text: String
    var style: Style = .default

    enum Style {
        case `default`   // accent-soft bg, primary text
        case accent      // black bg, white text
        case success     // green
        case warning     // orange
        case error       // red
        case muted       // border bg, secondary text
        case custom(fg: Color, bg: Color)
    }

    var body: some View {
        Text(text)
            .font(AppFont.caption.font)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch style {
        case .default:            return AppColor.textPrimary
        case .accent:             return .white
        case .success:            return AppColor.success
        case .warning:            return AppColor.warning
        case .error:              return AppColor.error
        case .muted:              return AppColor.textSecondary
        case .custom(let fg, _):  return fg
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .default:            return AppColor.accentSoft
        case .accent:             return AppColor.accent
        case .success:            return AppColor.success.opacity(0.12)
        case .warning:            return AppColor.warning.opacity(0.12)
        case .error:              return AppColor.error.opacity(0.12)
        case .muted:              return AppColor.border
        case .custom(_, let bg):  return bg
        }
    }
}

// MARK: - AppPrimaryButton

/// The only full-width CTA. Black fill, white text, 50pt height.
struct AppPrimaryButton: View {
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ label: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.label.font)
                .foregroundStyle(isEnabled ? .white : AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? AppColor.accent : AppColor.disabled)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Secondary full-width button. Quiet surface, primary text, same height as primary CTA.
struct AppSecondaryButton: View {
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ label: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.label.font)
                .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? AppColor.cardBackground : AppColor.disabled.opacity(0.2))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
