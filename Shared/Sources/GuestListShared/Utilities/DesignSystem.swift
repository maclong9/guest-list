#if canImport(SwiftUI)
import SwiftUI
#endif

/// Unified design system for GuestList
/// Works seamlessly with both SwiftUI and WebUI
///
/// For SwiftUI: Use Color, CGFloat values, and view modifiers
/// For WebUI: Use rawValue strings that map to WebUI's Color/TextSize enums
public enum DesignSystem {
    // MARK: - Colors

    /// Design system colors that work with both SwiftUI and WebUI
    public enum Colors {
        // MARK: Brand Colors

        case primary
        case secondary
        case accent

        // MARK: Semantic Colors

        case success
        case warning
        case error
        case info

        // MARK: Neutral Scale

        case gray50
        case gray100
        case gray200
        case gray300
        case gray400
        case gray500
        case gray600
        case gray700
        case gray800
        case gray900
        case gray950

        // MARK: Background Colors

        case background
        case backgroundSecondary
        case backgroundTertiary

        // MARK: Text Colors

        case textPrimary
        case textSecondary
        case textTertiary
        case textInverse

        // MARK: - SwiftUI Color

        #if canImport(SwiftUI)
        /// Get SwiftUI Color for use in SwiftUI apps
        public var swiftUIColor: Color {
            switch self {
            // Brand
            case .primary: return Color(red: 0.29, green: 0.48, blue: 1.0)  // #4A7AFF (blue-500)
            case .secondary: return Color(red: 0.51, green: 0.33, blue: 0.89)  // #8354E3 (violet-600)
            case .accent: return Color(red: 1.0, green: 0.4, blue: 0.0)  // #FF6600 (orange-600)

            // Semantic
            case .success: return Color(red: 0.13, green: 0.8, blue: 0.43)  // #22C55E (green-500)
            case .warning: return Color(red: 0.98, green: 0.73, blue: 0.02)  // #FBBF04 (yellow-500)
            case .error: return Color(red: 0.94, green: 0.27, blue: 0.29)  // #EF4444 (red-500)
            case .info: return Color(red: 0.22, green: 0.71, blue: 0.96)  // #38BDF8 (sky-400)

            // Grays (using slate scale)
            case .gray50: return Color(red: 0.98, green: 0.98, blue: 0.99)  // #F8FAFC
            case .gray100: return Color(red: 0.95, green: 0.96, blue: 0.97)  // #F1F5F9
            case .gray200: return Color(red: 0.89, green: 0.91, blue: 0.94)  // #E2E8F0
            case .gray300: return Color(red: 0.8, green: 0.84, blue: 0.88)  // #CBD5E1
            case .gray400: return Color(red: 0.58, green: 0.64, blue: 0.72)  // #94A3B8
            case .gray500: return Color(red: 0.39, green: 0.46, blue: 0.55)  // #64748B
            case .gray600: return Color(red: 0.28, green: 0.34, blue: 0.42)  // #475569
            case .gray700: return Color(red: 0.2, green: 0.25, blue: 0.33)  // #334155
            case .gray800: return Color(red: 0.12, green: 0.15, blue: 0.22)  // #1E293B
            case .gray900: return Color(red: 0.06, green: 0.09, blue: 0.15)  // #0F172A
            case .gray950: return Color(red: 0.01, green: 0.03, blue: 0.08)  // #020617

            // Backgrounds
            case .background: return Color.white
            case .backgroundSecondary: return Self.gray50.swiftUIColor
            case .backgroundTertiary: return Self.gray100.swiftUIColor

            // Text
            case .textPrimary: return Self.gray900.swiftUIColor
            case .textSecondary: return Self.gray600.swiftUIColor
            case .textTertiary: return Self.gray400.swiftUIColor
            case .textInverse: return Color.white
            }
        }
        #endif

        // MARK: - WebUI Color String

        /// Get WebUI color identifier for use with WebUI's Color enum
        /// Returns a string like "blue._500" that maps to WebUI.Color.blue(._500)
        public var webUIColor: String {
            switch self {
            // Brand - using Tailwind palette
            case .primary: return "blue._500"
            case .secondary: return "violet._600"
            case .accent: return "orange._600"

            // Semantic
            case .success: return "green._500"
            case .warning: return "yellow._500"
            case .error: return "red._500"
            case .info: return "sky._400"

            // Grays
            case .gray50: return "slate._50"
            case .gray100: return "slate._100"
            case .gray200: return "slate._200"
            case .gray300: return "slate._300"
            case .gray400: return "slate._400"
            case .gray500: return "slate._500"
            case .gray600: return "slate._600"
            case .gray700: return "slate._700"
            case .gray800: return "slate._800"
            case .gray900: return "slate._900"
            case .gray950: return "slate._950"

            // Backgrounds
            case .background: return "white"
            case .backgroundSecondary: return "slate._50"
            case .backgroundTertiary: return "slate._100"

            // Text
            case .textPrimary: return "slate._900"
            case .textSecondary: return "slate._600"
            case .textTertiary: return "slate._400"
            case .textInverse: return "white"
            }
        }

        /// Get hex color code for debugging/export
        public var hex: String {
            switch self {
            case .primary: return "#4A7AFF"
            case .secondary: return "#8354E3"
            case .accent: return "#FF6600"
            case .success: return "#22C55E"
            case .warning: return "#FBBF04"
            case .error: return "#EF4444"
            case .info: return "#38BDF8"
            case .gray50: return "#F8FAFC"
            case .gray100: return "#F1F5F9"
            case .gray200: return "#E2E8F0"
            case .gray300: return "#CBD5E1"
            case .gray400: return "#94A3B8"
            case .gray500: return "#64748B"
            case .gray600: return "#475569"
            case .gray700: return "#334155"
            case .gray800: return "#1E293B"
            case .gray900: return "#0F172A"
            case .gray950: return "#020617"
            case .background: return "#FFFFFF"
            case .backgroundSecondary: return "#F8FAFC"
            case .backgroundTertiary: return "#F1F5F9"
            case .textPrimary: return "#0F172A"
            case .textSecondary: return "#475569"
            case .textTertiary: return "#94A3B8"
            case .textInverse: return "#FFFFFF"
            }
        }
    }

    // MARK: - Typography

    /// Typography scale matching WebUI's TextSize enum
    public enum Typography {
        case xs  // 0.75rem (12px)
        case sm  // 0.875rem (14px)
        case base  // 1rem (16px)
        case lg  // 1.125rem (18px)
        case xl  // 1.25rem (20px)
        case xl2  // 1.5rem (24px)
        case xl3  // 1.875rem (30px)
        case xl4  // 2.25rem (36px)
        case xl5  // 3rem (48px)
        case xl6  // 3.75rem (60px)
        case xl7  // 4.5rem (72px)
        case xl8  // 6rem (96px)
        case xl9  // 8rem (128px)

        #if canImport(SwiftUI)
        /// SwiftUI font size in points
        public var size: CGFloat {
            switch self {
            case .xs: return 12
            case .sm: return 14
            case .base: return 16
            case .lg: return 18
            case .xl: return 20
            case .xl2: return 24
            case .xl3: return 30
            case .xl4: return 36
            case .xl5: return 48
            case .xl6: return 60
            case .xl7: return 72
            case .xl8: return 96
            case .xl9: return 128
            }
        }
        #endif

        /// WebUI TextSize identifier
        public var webUISize: String {
            switch self {
            case .xs: return ".xs"
            case .sm: return ".sm"
            case .base: return ".base"
            case .lg: return ".lg"
            case .xl: return ".xl"
            case .xl2: return ".xl2"
            case .xl3: return ".xl3"
            case .xl4: return ".xl4"
            case .xl5: return ".xl5"
            case .xl6: return ".xl6"
            case .xl7: return ".xl7"
            case .xl8: return ".xl8"
            case .xl9: return ".xl9"
            }
        }
    }

    /// Font weights matching WebUI's Weight enum
    public enum Weight {
        case thin  // 100
        case extralight  // 200
        case light  // 300
        case normal  // 400
        case medium  // 500
        case semibold  // 600
        case bold  // 700
        case extrabold  // 800
        case black  // 900

        #if canImport(SwiftUI)
        /// SwiftUI Font.Weight
        public var swiftUIWeight: Font.Weight {
            switch self {
            case .thin: return .thin
            case .extralight: return .ultraLight
            case .light: return .light
            case .normal: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .extrabold: return .heavy
            case .black: return .black
            }
        }
        #endif

        /// WebUI Weight identifier
        public var webUIWeight: String {
            switch self {
            case .thin: return ".thin"
            case .extralight: return ".extralight"
            case .light: return ".light"
            case .normal: return ".normal"
            case .medium: return ".medium"
            case .semibold: return ".semibold"
            case .bold: return ".bold"
            case .extrabold: return ".extrabold"
            case .black: return ".black"
            }
        }
    }

    // MARK: - Spacing

    /// Spacing scale (matches Tailwind's 4px = 1 unit system)
    public enum Spacing {
        case px  // 1px
        case _0  // 0
        case _0_5  // 2px (0.125rem)
        case _1  // 4px (0.25rem)
        case _1_5  // 6px (0.375rem)
        case _2  // 8px (0.5rem)
        case _2_5  // 10px (0.625rem)
        case _3  // 12px (0.75rem)
        case _3_5  // 14px (0.875rem)
        case _4  // 16px (1rem)
        case _5  // 20px (1.25rem)
        case _6  // 24px (1.5rem)
        case _7  // 28px (1.75rem)
        case _8  // 32px (2rem)
        case _9  // 36px (2.25rem)
        case _10  // 40px (2.5rem)
        case _11  // 44px (2.75rem)
        case _12  // 48px (3rem)
        case _14  // 56px (3.5rem)
        case _16  // 64px (4rem)
        case _20  // 80px (5rem)
        case _24  // 96px (6rem)
        case _28  // 112px (7rem)
        case _32  // 128px (8rem)

        #if canImport(SwiftUI)
        /// SwiftUI spacing in points
        public var value: CGFloat {
            switch self {
            case .px: return 1
            case ._0: return 0
            case ._0_5: return 2
            case ._1: return 4
            case ._1_5: return 6
            case ._2: return 8
            case ._2_5: return 10
            case ._3: return 12
            case ._3_5: return 14
            case ._4: return 16
            case ._5: return 20
            case ._6: return 24
            case ._7: return 28
            case ._8: return 32
            case ._9: return 36
            case ._10: return 40
            case ._11: return 44
            case ._12: return 48
            case ._14: return 56
            case ._16: return 64
            case ._20: return 80
            case ._24: return 96
            case ._28: return 112
            case ._32: return 128
            }
        }
        #endif

        /// WebUI spacing identifier (for use with padding/margin operations)
        public var webUIValue: Int {
            #if canImport(SwiftUI)
            return Int(value)
            #else
            // For Linux, calculate directly
            switch self {
            case .px: return 1
            case ._0: return 0
            case ._0_5: return 2
            case ._1: return 4
            case ._1_5: return 6
            case ._2: return 8
            case ._2_5: return 10
            case ._3: return 12
            case ._3_5: return 14
            case ._4: return 16
            case ._5: return 20
            case ._6: return 24
            case ._7: return 28
            case ._8: return 32
            case ._9: return 36
            case ._10: return 40
            case ._11: return 44
            case ._12: return 48
            case ._14: return 56
            case ._16: return 64
            case ._20: return 80
            case ._24: return 96
            case ._28: return 112
            case ._32: return 128
            }
            #endif
        }
    }

    // MARK: - Corner Radius

    /// Border radius values matching WebUI's rounded() operation
    public enum Radius {
        case none  // 0
        case sm  // 2px (0.125rem)
        case base  // 4px (0.25rem)
        case md  // 6px (0.375rem)
        case lg  // 8px (0.5rem)
        case xl  // 12px (0.75rem)
        case xl2  // 16px (1rem)
        case xl3  // 24px (1.5rem)
        case full  // 9999px

        #if canImport(SwiftUI)
        /// SwiftUI corner radius in points
        public var value: CGFloat {
            switch self {
            case .none: return 0
            case .sm: return 2
            case .base: return 4
            case .md: return 6
            case .lg: return 8
            case .xl: return 12
            case .xl2: return 16
            case .xl3: return 24
            case .full: return 9999
            }
        }
        #endif

        /// WebUI radius identifier
        public var webUIValue: String {
            switch self {
            case .none: return ".none"
            case .sm: return ".sm"
            case .base: return ".base"
            case .md: return ".md"
            case .lg: return ".lg"
            case .xl: return ".xl"
            case .xl2: return ".xl2"
            case .xl3: return ".xl3"
            case .full: return ".full"
            }
        }
    }

    // MARK: - Shadows

    /// Shadow presets
    public enum Shadow {
        case sm
        case base
        case md
        case lg
        case xl
        case xl2
        case inner
        case none

        #if canImport(SwiftUI)
        /// SwiftUI shadow configuration (radius, x, y)
        public var swiftUI: (radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .sm: return (2, 0, 1)
            case .base: return (3, 0, 1)
            case .md: return (6, 0, 4)
            case .lg: return (15, 0, 10)
            case .xl: return (25, 0, 20)
            case .xl2: return (50, 0, 25)
            case .inner: return (0, 0, 0)  // Inner shadow not directly supported
            case .none: return (0, 0, 0)
            }
        }
        #endif

        /// WebUI shadow identifier
        public var webUIValue: String {
            switch self {
            case .sm: return ".sm"
            case .base: return ".base"
            case .md: return ".md"
            case .lg: return ".lg"
            case .xl: return ".xl"
            case .xl2: return ".xl2"
            case .inner: return ".inner"
            case .none: return ".none"
            }
        }
    }

    // MARK: - Breakpoints

    /// Responsive breakpoints matching WebUI's Modifier enum
    public enum Breakpoint {
        case xs  // 480px
        case sm  // 640px
        case md  // 768px
        case lg  // 1024px
        case xl  // 1280px
        case xl2  // 1536px

        #if canImport(SwiftUI)
        /// Breakpoint value in points
        public var value: CGFloat {
            switch self {
            case .xs: return 480
            case .sm: return 640
            case .md: return 768
            case .lg: return 1024
            case .xl: return 1280
            case .xl2: return 1536
            }
        }
        #endif
    }
}

#if canImport(SwiftUI)
// MARK: - SwiftUI Extensions

extension View {
    /// Apply design system color as foreground
    public func foregroundColor(_ color: DesignSystem.Colors) -> some View {
        foregroundColor(color.swiftUIColor)
    }

    /// Apply design system color as background
    public func backgroundColor(_ color: DesignSystem.Colors) -> some View {
        background(color.swiftUIColor)
    }

    /// Apply design system spacing as padding
    public func padding(_ spacing: DesignSystem.Spacing) -> some View {
        padding(spacing.value)
    }

    /// Apply design system corner radius
    public func cornerRadius(_ radius: DesignSystem.Radius) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius.value))
    }

    /// Apply design system shadow
    public func shadow(_ shadow: DesignSystem.Shadow) -> some View {
        let config = shadow.swiftUI
        return self.shadow(
            color: .black.opacity(0.1),
            radius: config.radius,
            x: config.x,
            y: config.y
        )
    }

    /// Apply design system typography
    public func typography(
        size: DesignSystem.Typography,
        weight: DesignSystem.Weight = .normal,
        color: DesignSystem.Colors = .textPrimary
    ) -> some View {
        font(.system(size: size.size, weight: weight.swiftUIWeight))
            .foregroundColor(color.swiftUIColor)
    }
}
#endif
