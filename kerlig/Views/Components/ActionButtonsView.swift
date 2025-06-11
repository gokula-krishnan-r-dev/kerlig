import SwiftUI

/// A view component that displays a grid of action buttons for AI operations.
/// The view automatically animates buttons appearance and supports keyboard navigation.
struct ActionButtonsView: View {
  // MARK: - Properties

  /// The currently selected action, if any
  @Binding var selectedAction: AIAction?

  /// Whether an operation is currently being processed
  @Binding var isProcessing: Bool

  /// The currently focused button for keyboard navigation
  @FocusState var focusedField: KerligStylePanelView.FocusableField?

  /// Animation state for staggered entrance
  @Binding var animateEntrance: Bool

  /// Layout configuration
  var columns: Int = 2
  var spacing: CGFloat = 10
  var horizontalPadding: CGFloat = 16

  /// Actions to display - if nil, default actions will be used
  var actions: [AIAction]?

  /// Callback when an action is selected
  var onActionSelected: (AIAction) -> Void

  // MARK: - Computed Properties

  /// Default actions if none are provided
  private var defaultActions: [AIAction] {
    return [
      .fixSpellingGrammar,
      .improveWriting,
      .translate,
      .makeShorter,
      .analyzeImage,
    ]
  }

  /// Actions to display, using defaults if none provided
  private var displayedActions: [AIAction] {
    return actions ?? defaultActions
  }

  /// Grid layout for buttons
  private var gridLayout: [GridItem] {
    return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 10) {
      // Section title
      HStack {
        Text("Quick Actions")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding(.horizontal, horizontalPadding)
      .padding(.bottom, 4)
      .opacity(animateEntrance ? 1 : 0)
      .animation(.easeIn.delay(0.1), value: animateEntrance)

      // Action buttons in grid layout
      LazyVGrid(columns: gridLayout, spacing: spacing) {
        ForEach(Array(displayedActions.enumerated()), id: \.element) { index, action in
          actionButton(for: action, at: index)
            .focused($focusedField, equals: .actionButton(index))
        }
      }
      .padding(.horizontal, horizontalPadding)
    }
    .padding(.top, 12)
    .padding(.bottom, 8)
  }

  // MARK: - Helper Views
  /// Creates a button for a specific action
  private func actionButton(for action: AIAction, at index: Int) -> some View {
    // Break down the complex expression into smaller parts
    ButtonContent(
      action: action,
      isSelected: selectedAction == action,
      isProcessing: isProcessing && selectedAction == action,
      isFocused: focusedField == .actionButton(index),
      index: index,
      animateEntrance: animateEntrance,
      onSelect: {
        onActionSelected(action)
      }
    )
    .focused($focusedField, equals: .actionButton(index))
    .disabled(isProcessing)
  }

  /// Processing overlay with loading animation
  private var processingOverlay: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.black.opacity(0.05))

      ProgressView()
        .scaleEffect(0.8)
        .padding(5)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.9))
        )
    }
  }

  /// Determines the background color for a button based on its state
  private func buttonBackground(for action: AIAction) -> some ShapeStyle {
    if selectedAction == action {
      return LinearGradient(
        gradient: Gradient(colors: [
          Color.blue.opacity(0.1),
          Color.blue.opacity(0.08),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    } else {
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(NSColor.controlBackgroundColor).opacity(0.97),
          Color(NSColor.controlBackgroundColor).opacity(0.9),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }
}

// MARK: - Helper Structures

/// A helper view for button content to reduce complexity
private struct ButtonContent: View {
  let action: AIAction
  let isSelected: Bool
  let isProcessing: Bool
  let isFocused: Bool
  let index: Int
  let animateEntrance: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      buttonLabel
    }
    .buttonStyle(PlainButtonStyle())
    .contentShape(Rectangle())
    .opacity(animateEntrance ? 1 : 0)
    .offset(y: animateEntrance ? 0 : 20)
    .animation(
      .spring(response: 0.4, dampingFraction: 0.7)
        .delay(Double(index) * 0.05 + 0.2),
      value: animateEntrance
    )
  }

  // Button label content
  private var buttonLabel: some View {
    VStack(spacing: 8) {
      // Icon
      iconView

      // Title
      titleView
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .padding(.horizontal, 8)
    .background(backgroundView)
    .overlay(borderView)
    .shadow(
      color: isSelected ? Color.blue.opacity(0.2) : Color.clear,
      radius: 3, x: 0, y: 1
    )
    .overlay(processingView)
    .overlay(focusIndicator)
  }

  // Icon at the top of the button
  private var iconView: some View {
    Image(systemName: action.icon)
      .font(.system(size: 22))
      .foregroundColor(isSelected ? .blue : .secondary)
      .frame(height: 24)
      .contentShape(Rectangle())
  }

  // Title text
  private var titleView: some View {
    Text(action.title)
      .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
      .foregroundColor(isSelected ? .primary : .secondary)
      .lineLimit(2)
      .multilineTextAlignment(.center)
  }

  // Background gradient
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(buttonBackgroundGradient)
  }

  // Border overlay
  private var borderView: some View {
    RoundedRectangle(cornerRadius: 10)
      .stroke(
        isSelected ? Color.blue.opacity(0.4) : Color.secondary.opacity(0.15),
        lineWidth: isSelected ? 1.5 : 1
      )
  }

  // Processing indicator overlay
  @ViewBuilder
  private var processingView: some View {
    if isProcessing {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.black.opacity(0.05))

        ProgressView()
          .scaleEffect(0.8)
          .padding(5)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.white.opacity(0.9))
          )
      }
    }
  }

  // Focus indicator
  @ViewBuilder
  private var focusIndicator: some View {
    if isFocused {
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.blue, lineWidth: 2)
        .padding(-1)
    }
  }

  // Background gradient based on selection state
  private var buttonBackgroundGradient: LinearGradient {
    if isSelected {
      return LinearGradient(
        gradient: Gradient(colors: [
          Color.blue.opacity(0.1),
          Color.blue.opacity(0.08),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    } else {
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(NSColor.controlBackgroundColor).opacity(0.97),
          Color(NSColor.controlBackgroundColor).opacity(0.9),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }
}
