import SwiftUI
struct AddColumnButton: View {
    let onAdd: () -> Void
    @State private var isHovered = false
    @State private var showingAddForm = false
    @State private var newColumnTitle = ""
    @State private var selectedColor: Color = .blue
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        .cyan, .indigo, .mint, .teal
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if showingAddForm {
                // Add column form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Column")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        TextField("Column title", text: $newColumnTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        // Color picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                            .scaleEffect(selectedColor == color ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingAddForm = false
                                newColumnTitle = ""
                                selectedColor = .blue
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        Button("Create Column") {
                            createColumn()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor)
                        )
                        .disabled(newColumnTitle.isEmpty)
                        .opacity(newColumnTitle.isEmpty ? 0.6 : 1)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            } else {
                // Add column button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingAddForm = true
                    }
                }) {
                    VStack(spacing: 20) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.gray.opacity(isHovered ? 0.8 : 0.5))
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                        
                        VStack(spacing: 4) {
                            Text("Add Column")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray.opacity(isHovered ? 0.9 : 0.7))
                            
                            Text("Create a new task column")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(isHovered ? 0.04 : 0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.white.opacity(isHovered ? 0.3 : 0.2),
                                        style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                                    )
                            )
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .frame(height: showingAddForm ? nil : 400)
    }
    
    private func createColumn() {
        guard !newColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingAddForm = false
        }
        
        // Call the onAdd closure with the new column data
        onAdd()
        
        // Reset form
        newColumnTitle = ""
        selectedColor = .blue
    }
}