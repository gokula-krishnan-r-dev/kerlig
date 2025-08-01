import SwiftUI

struct AIModelCard: View {
    let model: ModelOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Model Icon
            ZStack {
                Circle()
                    .fill(model.iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: model.iconName)
                    .foregroundColor(model.iconColor)
                    .font(.system(size: 18, weight: .medium))
            }
            
            // Model Information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if model.isRecommended {
                        RecommendedBadge()
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
                
                Text(model.provider)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                
                if let description = model.description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Metrics Row
                HStack(spacing: 12) {
                    MetricPill(
                        icon: "dollarsign.circle",
                        text: model.formattedCost,
                        color: .green
                    )
                    
                    MetricPill(
                        icon: "speedometer",
                        text: model.speed,
                        color: model.speedLevel.color
                    )
                    
                    MetricPill(
                        icon: "star.fill",
                        text: model.capabilities,
                        color: model.capabilityLevel.color
                    )
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
        }
        .help(model.description ?? "Select \(model.name)")
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.blue
        } else if isHovered {
            return Color.primary.opacity(0.2)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2.0 : 1.0
    }
}

struct MetricPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct RecommendedBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("Recommended")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange)
        )
    }
}

// MARK: - Compact Model Card

struct CompactAIModelCard: View {
    let model: ModelOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Model Icon
            ZStack {
                Circle()
                    .fill(model.iconColor.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: model.iconName)
                    .foregroundColor(model.iconColor)
                    .font(.system(size: 12, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                    }
                }
                
                HStack(spacing: 8) {
                    Text(model.provider)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    
                    Text(model.formattedCost)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.blue
        } else if isHovered {
            return Color.primary.opacity(0.2)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 0.5
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        AIModelCard(
            model: ModelOption(
                id: "gpt-4o",
                name: "GPT-4o",
                iconName: "sparkle.magnifyingglass",
                iconColor: .green,
                cost: 0.01,
                provider: "OpenAI",
                capabilities: "Excellent",
                speed: "Fast",
                description: "Most capable GPT-4 model with vision capabilities",
                isRecommended: true
            ),
            isSelected: true,
            onSelect: {}
        )
        
        AIModelCard(
            model: ModelOption(
                id: "claude-3-opus",
                name: "Claude 3 Opus",
                iconName: "wand.and.stars",
                iconColor: .purple,
                cost: 0.015,
                provider: "Anthropic",
                capabilities: "Excellent",
                speed: "Medium",
                description: "Most powerful Claude model for complex reasoning"
            ),
            isSelected: false,
            onSelect: {}
        )
        
        CompactAIModelCard(
            model: ModelOption(
                id: "gpt-4o-mini",
                name: "GPT-4o Mini",
                iconName: "sparkle",
                iconColor: .green,
                cost: 0.001,
                provider: "OpenAI",
                capabilities: "Good",
                speed: "Very Fast"
            ),
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .frame(width: 400)
}