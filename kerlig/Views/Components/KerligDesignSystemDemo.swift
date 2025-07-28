import SwiftUI

/// Demo view showcasing the Kerlig Design System
/// This serves as both documentation and a testing ground for the design system
struct KerligDesignSystemDemo: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Kerlig Design System")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.kerligPrimaryText)
                    
                    Text("Consistent, macOS-native UI components")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.kerligSecondaryText)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // Tab Picker
                Picker("Category", selection: $selectedTab) {
                    Text("Colors").tag(0)
                    Text("Buttons").tag(1)
                    Text("Cards").tag(2)
                    Text("Typography").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        switch selectedTab {
                        case 0:
                            ColorsDemo()
                        case 1:
                            ButtonsDemo()
                        case 2:
                            CardsDemo()
                        case 3:
                            TypographyDemo()
                        default:
                            ColorsDemo()
                        }
                    }
                    .padding(20)
                }
                .background(Color.kerligBackground)
            }
        }
        .background(Color.kerligBackground)
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Colors Demo
struct ColorsDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Color Palette", subtitle: "Dynamic colors that adapt to light/dark mode")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ColorSwatch(color: .kerligPrimaryText, name: "Primary Text", description: "Main text color")
                ColorSwatch(color: .kerligSecondaryText, name: "Secondary Text", description: "Subtle text")
                ColorSwatch(color: .kerligTertiaryText, name: "Tertiary Text", description: "Disabled text")
                ColorSwatch(color: .kerligAccent, name: "Accent", description: "Brand color")
                ColorSwatch(color: .kerligBackground, name: "Background", description: "Main background")
                ColorSwatch(color: .kerligSurface, name: "Surface", description: "Card background")
            }
        }
    }
}

// MARK: - Buttons Demo
struct ButtonsDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Button Styles", subtitle: "Consistent button components")
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button("Primary Large") { }
                        .kerligButton(variant: .primary, size: .large)
                    
                    Button("Secondary Large") { }
                        .kerligButton(variant: .secondary, size: .large)
                    
                    Button("Tertiary Large") { }
                        .kerligButton(variant: .tertiary, size: .large)
                }
                
                HStack(spacing: 16) {
                    Button("Primary Medium") { }
                        .kerligButton(variant: .primary, size: .medium)
                    
                    Button("Secondary Medium") { }
                        .kerligButton(variant: .secondary, size: .medium)
                    
                    Button("Tertiary Medium") { }
                        .kerligButton(variant: .tertiary, size: .medium)
                }
                
                HStack(spacing: 16) {
                    Button("Primary Small") { }
                        .kerligButton(variant: .primary, size: .small)
                    
                    Button("Secondary Small") { }
                        .kerligButton(variant: .secondary, size: .small)
                    
                    Button("Tertiary Small") { }
                        .kerligButton(variant: .tertiary, size: .small)
                }
            }
        }
    }
}

// MARK: - Cards Demo
struct CardsDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Card Elevations", subtitle: "Different card styles for hierarchy")
            
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    CardExample(elevation: .none, title: "No Elevation")
                    CardExample(elevation: .low, title: "Low Elevation")
                }
                
                HStack(spacing: 16) {
                    CardExample(elevation: .medium, title: "Medium Elevation")
                    CardExample(elevation: .high, title: "High Elevation")
                }
            }
        }
    }
}

// MARK: - Typography Demo
struct TypographyDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Typography Scale", subtitle: "Consistent text hierarchy")
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Heading 1")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.kerligPrimaryText)
                
                Text("Heading 2")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.kerligPrimaryText)
                
                Text("Heading 3")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.kerligPrimaryText)
                
                Text("Body Text - This is the standard body text used throughout the application. It should be easy to read and well-spaced.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.kerligPrimaryText)
                
                Text("Secondary Text - Used for less important information and descriptions.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kerligSecondaryText)
                
                Text("Caption Text - Small text for labels and metadata.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.kerligTertiaryText)
            }
        }
    }
}

// MARK: - Helper Components
struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.kerligPrimaryText)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.kerligSecondaryText)
        }
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.kerligBorder, lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.kerligPrimaryText)
                
                Text(description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.kerligSecondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .kerligCard(elevation: .low)
        .padding(12)
    }
}

struct CardExample: View {
    let elevation: KerligCardStyle.CardElevation
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.kerligPrimaryText)
            
            Text("This is an example card with \(title.lowercased()) to demonstrate the shadow and styling.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.kerligSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .kerligCard(elevation: elevation)
        .frame(height: 120)
    }
}

#if DEBUG
#Preview {
    KerligDesignSystemDemo()
        .frame(width: 900, height: 700)
}
#endif 