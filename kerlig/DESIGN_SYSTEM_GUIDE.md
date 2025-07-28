# Kerlig Design System Guide

## Overview

The Kerlig Design System provides a comprehensive, macOS-native color palette and component library that automatically adapts to light and dark modes. This system ensures consistency across the entire application while maintaining excellent accessibility and user experience.

## 🎨 Color System

### Usage

```swift
// Background colors (automatically adapt to light/dark mode)
Color.kerligBackground          // Main window background
Color.kerligSecondaryBackground // Secondary areas
Color.kerligSurface            // Card backgrounds

// Text colors (dynamic)
Color.kerligPrimaryText        // Main text
Color.kerligSecondaryText      // Subtitle text
Color.kerligTertiaryText       // Disabled/placeholder text

// Accent colors
Color.kerligAccent             // Brand color (follows system accent)
Color.kerligButtonBackground   // Button backgrounds
```

### Best Practices

- Always use semantic color names (e.g., `.kerligPrimaryText`) instead of hardcoded hex values
- Colors automatically adapt to system appearance and accent color preferences
- Use the gradient backgrounds for hero sections: `Color.kerligGradientBackground`

## 🔘 Button System

### Usage

```swift
// Primary button (for main actions)
Button("Get Started") { action() }
    .kerligButton(variant: .primary, size: .large)

// Secondary button (for alternative actions)
Button("Cancel") { action() }
    .kerligButton(variant: .secondary, size: .medium)

// Tertiary button (for subtle actions)
Button("Learn More") { action() }
    .kerligButton(variant: .tertiary, size: .small)
```

### Button Variants

- **Primary**: High emphasis, solid background with accent color
- **Secondary**: Medium emphasis, outlined style
- **Tertiary**: Low emphasis, text-only style

### Button Sizes

- **Large**: 16px font, suitable for hero CTAs
- **Medium**: 14px font, standard UI buttons
- **Small**: 12px font, compact interfaces

## 📦 Card System

### Usage

```swift
VStack {
    // Your content here
}
.kerligCard(elevation: .medium)
```

### Elevation Levels

- **None**: No shadow, flat appearance
- **Low**: Subtle shadow, minimal elevation
- **Medium**: Standard card elevation (recommended)
- **High**: Prominent shadow, maximum elevation

## 📝 Typography

### Font Scale

```swift
// Headings
.font(.system(size: 32, weight: .bold, design: .rounded))    // H1
.font(.system(size: 24, weight: .bold, design: .rounded))    // H2
.font(.system(size: 20, weight: .semibold))                  // H3

// Body text
.font(.system(size: 16, weight: .regular))                   // Body
.font(.system(size: 14, weight: .medium))                    // Secondary
.font(.system(size: 12, weight: .medium))                    // Caption
```

### Text Colors

Always pair typography with appropriate semantic colors:

```swift
Text("Main Heading")
    .font(.system(size: 32, weight: .bold, design: .rounded))
    .foregroundColor(.kerligPrimaryText)

Text("Subtitle")
    .font(.system(size: 16, weight: .medium))
    .foregroundColor(.kerligSecondaryText)
```

## 🚀 Implementation Examples

### Modern Card Component

```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Card Title")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.kerligPrimaryText)

    Text("Card description with secondary text color")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.kerligSecondaryText)

    Button("Action") { }
        .kerligButton(variant: .primary, size: .medium)
}
.padding(20)
.kerligCard(elevation: .medium)
```

### Settings Row

```swift
HStack {
    VStack(alignment: .leading, spacing: 4) {
        Text("Setting Name")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.kerligPrimaryText)

        Text("Setting description")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.kerligSecondaryText)
    }

    Spacer()

    Toggle("", isOn: $isEnabled)
}
.padding(.vertical, 12)
.padding(.horizontal, 16)
```

### Hero Section

```swift
VStack(spacing: 24) {
    Text("Welcome to Kerlig")
        .font(.system(size: 36, weight: .bold, design: .rounded))
        .foregroundColor(.kerligPrimaryText)

    Text("Enhance your writing with AI")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.kerligSecondaryText)

    Button("Get Started") { }
        .kerligButton(variant: .primary, size: .large)
}
.padding(40)
.background(Color.kerligGradientBackground)
```

## 🔧 Migration from Old Colors

### Before (Hardcoded)

```swift
// ❌ Don't use hardcoded colors
Color(hex: "222831")
Color(hex: "76ABAE")
.foregroundColor(.white)
```

### After (Semantic)

```swift
// ✅ Use semantic colors
Color.kerligBackground
Color.kerligAccent
.foregroundColor(.kerligPrimaryText)
```

## 📱 Responsive Design

The design system works seamlessly across different window sizes:

```swift
GeometryReader { geometry in
    VStack {
        // Content adapts to geometry
        Image("demo")
            .frame(maxWidth: min(800, geometry.size.width - 80))
            .kerligCard(elevation: .medium)
    }
}
```

## 🎯 Accessibility

All colors in the system:

- Meet WCAG contrast requirements
- Automatically adapt to system preferences
- Support high contrast mode
- Work with VoiceOver and other assistive technologies

## 🔄 Dynamic Adaptation

The system automatically adapts to:

- **Light/Dark Mode**: All colors have appropriate variants
- **System Accent Color**: Buttons and accents follow user preferences
- **Accessibility Settings**: High contrast, reduced motion, etc.
- **Window Focus State**: Colors adjust when window loses focus

## 📦 Adding New Components

When creating new components, follow these patterns:

1. **Use semantic colors**: Always use `.kerligPrimaryText` instead of `.black`
2. **Follow spacing scale**: Use multiples of 4pt (4, 8, 12, 16, 20, 24, etc.)
3. **Apply consistent elevation**: Use `.kerligCard()` for surfaces
4. **Respect typography scale**: Use the defined font sizes and weights
5. **Add hover states**: Use `.onHover` for interactive elements

### Example New Component

```swift
struct CustomCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.kerligPrimaryText)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.kerligSecondaryText)

            Button("Action") { action() }
                .kerligButton(variant: .secondary, size: .small)
        }
        .padding(16)
        .kerligCard(elevation: .low)
    }
}
```

## 🧪 Testing Your Implementation

Use the `KerligDesignSystemDemo` view to:

- Test your components in different color schemes
- Verify proper contrast and readability
- Ensure consistent spacing and typography
- Preview different elevation levels

```swift
// Add to your ContentView for testing
#if DEBUG
NavigationLink("Design System Demo") {
    KerligDesignSystemDemo()
}
#endif
```

## 📈 Future Enhancements

The design system is built to be extensible:

- Add new color variants by extending the `Color` extension
- Create new button styles by extending `KerligButtonStyle`
- Add animation presets for consistent motion design
- Include custom SF Symbols for brand consistency

---

_This design system ensures your app feels native to macOS while maintaining your unique brand identity. Always test in both light and dark modes, and consider accessibility from the start._
