// GuestListShared
// Cross-platform shared code for the GuestList application

/// The version of the shared library
public let version = "1.0.0"

/// Cross-platform Swift package for GuestList
/// Contains models, services, and utilities shared across all platforms
///
/// ## Design System
/// Use `DesignSystem` for consistent styling across SwiftUI apps
/// Use `DesignSystemWeb` for WebUI CSS variables and utility classes
///
/// Example:
/// ```swift
/// // SwiftUI
/// Text("Hello")
///     .foregroundColor(DesignSystem.Colors.primary)
///     .designPadding(DesignSystem.Spacing.md)
///
/// // WebUI
/// let css = DesignSystemWeb.cssVariables()
/// ```
public struct GuestListShared {
    public init() {}
}
