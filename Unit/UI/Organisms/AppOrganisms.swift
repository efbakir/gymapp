//
//  AppOrganisms.swift
//  Unit
//
//  Five-Tier UI — Layer 3: Organisms
//  Higher-level reusable components: AppCard, SettingsSection.
//

import SwiftUI

// MARK: - AppCard

/// The only rounded surface in the app.
/// cardBackground, AppRadius.md corner radius, AppSpacing.md internal padding.
struct AppCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

// MARK: - AppCard modifier (for internal / organism use)

extension View {
    /// Convenience modifier matching AppCard visual. Prefer `AppCard { }` in page files.
    func appCardStyle() -> some View {
        self
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

// MARK: - SettingsSection

/// A labelled AppCard containing shared rows/controls.
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppFont.sectionHeader.color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
