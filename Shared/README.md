# GuestListShared

Cross-platform Swift package containing models, services, and utilities shared across all GuestList platforms (iOS, macOS, watchOS, visionOS, and Web).

## Structure

```
Sources/GuestListShared/
├── Models/           # Domain models (Event, Ticket, Guest, Venue, User, Message)
├── Services/         # APIClient, WebSocketService
├── ViewModels/       # Shared business logic
├── Views/            # Shared SwiftUI components
└── Utilities/        # Extensions, helpers, and design system
```

## Design System

The package includes a **unified design system** that works seamlessly with both SwiftUI and WebUI, ensuring consistent styling across all platforms.

### Key Features

- ✅ Single source of truth for colors, typography, spacing, and more
- ✅ Type-safe enums prevent typos and invalid values
- ✅ SwiftUI and WebUI use the exact same design tokens
- ✅ Matches Tailwind CSS conventions for web developers
- ✅ Responsive breakpoints built-in

### SwiftUI Usage

```swift
import GuestListShared

struct MyView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing._4.value) {
            Text("Welcome to GuestList")
                .typography(
                    size: .xl5,
                    weight: .bold,
                    color: .primary
                )
            
            Button("Get Started") {
                // Action
            }
            .foregroundColor(.textInverse)
            .padding(._4)
            .backgroundColor(.accent)
            .cornerRadius(.md)
            .shadow(.md)
        }
        .padding(._6)
        .backgroundColor(.background)
    }
}
```

### WebUI Usage

The design system provides WebUI-compatible identifiers that map directly to WebUI's type-safe APIs:

```swift
import GuestListShared
import WebUI

func homePage() -> some HTML {
    Division {
        Heading(.one) { "Welcome to GuestList" }
            .font(
                size: DesignSystem.Typography.xl5.webUISize,  // Maps to .xl5
                weight: DesignSystem.Weight.bold.webUIWeight,  // Maps to .bold
                color: parseWebUIColor(DesignSystem.Colors.primary.webUIColor)  // Maps to .blue(._500)
            )
        
        Button { "Get Started" }
            .font(color: parseWebUIColor(DesignSystem.Colors.textInverse.webUIColor))
            .padding(of: DesignSystem.Spacing._4.webUIValue, at: .all)
            .background(color: parseWebUIColor(DesignSystem.Colors.accent.webUIColor))
            .rounded(DesignSystem.Radius.md.webUIValue)
            .shadow(DesignSystem.Shadow.md.webUIValue)
    }
    .padding(of: DesignSystem.Spacing._6.webUIValue, at: .all)
    .background(color: parseWebUIColor(DesignSystem.Colors.background.webUIColor))
}

// Helper to parse WebUI color strings like "blue._500" into WebUI.Color enum
func parseWebUIColor(_ colorString: String) -> WebUI.Color {
    // Implementation: Parse "blue._500" and return .blue(._500)
    // This bridges DesignSystem to WebUI's type-safe Color enum
}
```

## Design System Reference

### Colors (`DesignSystem.Colors`)

- **Brand**: `primary` (blue-500), `secondary` (violet-600), `accent` (orange-600)
- **Semantic**: `success` (green-500), `warning` (yellow-500), `error` (red-500), `info` (sky-400)
- **Grays**: `gray50` through `gray950` (slate scale)
- **Backgrounds**: `background` (white), `backgroundSecondary` (slate-50), `backgroundTertiary` (slate-100)
- **Text**: `textPrimary` (slate-900), `textSecondary` (slate-600), `textTertiary` (slate-400), `textInverse` (white)

### Typography (`DesignSystem.Typography`)

- `xs` (12px), `sm` (14px), `base` (16px), `lg` (18px), `xl` (20px)
- `xl2` (24px), `xl3` (30px), `xl4` (36px), `xl5` (48px)
- `xl6` (60px), `xl7` (72px), `xl8` (96px), `xl9` (128px)

### Font Weights (`DesignSystem.Weight`)

`thin`, `extralight`, `light`, `normal`, `medium`, `semibold`, `bold`, `extrabold`, `black`

### Spacing (`DesignSystem.Spacing`)

- Small: `px` (1px), `_0` (0), `_0_5` (2px), `_1` (4px), `_1_5` (6px), `_2` (8px), `_2_5` (10px), `_3` (12px), `_3_5` (14px), `_4` (16px)
- Medium: `_5` (20px), `_6` (24px), `_7` (28px), `_8` (32px), `_9` (36px), `_10` (40px), `_11` (44px), `_12` (48px)
- Large: `_14` (56px), `_16` (64px), `_20` (80px), `_24` (96px), `_28` (112px), `_32` (128px)

### Corner Radius (`DesignSystem.Radius`)

`none` (0), `sm` (2px), `base` (4px), `md` (6px), `lg` (8px), `xl` (12px), `xl2` (16px), `xl3` (24px), `full` (9999px)

### Shadows (`DesignSystem.Shadow`)

`sm`, `base`, `md`, `lg`, `xl`, `xl2`, `inner`, `none`

### Breakpoints (`DesignSystem.Breakpoint`)

`xs` (480px), `sm` (640px), `md` (768px), `lg` (1024px), `xl` (1280px), `xl2` (1536px)

## Adding New Shared Code

1. **Models**: Add to `Models/` - must conform to `Codable` and `Sendable`
2. **Services**: Add to `Services/` - use actors for thread-safety
3. **ViewModels**: Add to `ViewModels/` - use `@Observable` or `@MainActor`
4. **Views**: Add to `Views/` - reusable SwiftUI components
5. **Utilities**: Add to `Utilities/` - extensions and helpers

## Testing

```sh
swift test
swift test --filter "ModelTests"
```

## Building

```sh
swift build
```
