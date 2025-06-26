import SwiftUI

struct NoteBoardView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var isAddingColumn = false
    @State private var newColumnTitle = ""
    @State private var selectedColumnColor: Color = .blue
    @Environment(\.colorScheme) private var colorScheme
    private let floatingSidebarController = FloatingSidebarController()
    
    // Animation states
    @State private var isHeaderVisible = false
    @State private var areColumnsVisible = false
    
    // Define a consistent color palette
    private let primaryBgColor = Color(hex: "#1A1A1C")
    private let secondaryBgColor = Color(hex: "#242426") 
    private let accentColor = Color(hex: "#4CAF50")
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Pin Now button
            HStack {
                Text("Notes Board")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        //close this window
                        //get the current window
                        let window = NSApplication.shared.windows.first
                        window?.close()
                        floatingSidebarController.toggleSidebar()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.fill")
                            .rotationEffect(.degrees(45))
                        Text("Pin Now")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentGradient)
                    .cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            .opacity(isHeaderVisible ? 1 : 0)
            .offset(y: isHeaderVisible ? 0 : -20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    isHeaderVisible = true
                }
            }
            
            // Board content
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Array(zip(noteStore.columns.sorted(by: { $0.order < $1.order }).indices, noteStore.columns.sorted(by: { $0.order < $1.order }))), id: \.1.id) { index, column in
                        NoteColumnView(
                            column: column,
                            notes: noteStore.getNotesForColumn(column),
                            noteStore: noteStore
                        )
                        .onAppear {
                            noteStore.loadNotes()
                        }
                        .onChange(of: noteStore.notes) { _, _ in
                            noteStore.loadNotes()
                        }
                        .opacity(areColumnsVisible ? 1 : 0)
                        .offset(y: areColumnsVisible ? 0 : 50)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(index) * 0.1), value: areColumnsVisible)
                    }
                    
                    // Add column button
                    Button(action: {
                        isAddingColumn = true
                    }) {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: "#2C2C2E"))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                )
                            Text("Add Column")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 200, height: 140)
                        .background(Color(hex: "#1C1C1E"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .opacity(areColumnsVisible ? 1 : 0)
                    .offset(y: areColumnsVisible ? 0 : 50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(noteStore.columns.count) * 0.1), value: areColumnsVisible)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryBgColor)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    areColumnsVisible = true
                }
            }
        }
        .sheet(isPresented: $isAddingColumn) {
            VStack(spacing: 0) {
                HStack {
                    Text("New Column")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        isAddingColumn = false
                    }
                    .foregroundColor(.gray)
                }
                .padding()
                .background(Color(hex: "#1C1C1E"))
                
                VStack(spacing: 24) {
                    TextField("Column Title", text: $newColumnTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onSubmit {
                            createNewColumn()
                        }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColumnColor == color ? 3 : 0)
                                            
                                            if selectedColumnColor == color {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedColumnColor = color
                                        }
                                    }
                            }
                        }
                    }
                    
                    Button(action: {
                        createNewColumn()
                    }) {
                        Text("Create Column")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGradient)
                            .cornerRadius(8)
                            .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .disabled(newColumnTitle.isEmpty)
                    .opacity(newColumnTitle.isEmpty ? 0.6 : 1)
                }
                .padding()
            }
            .background(Color(hex: "#1C1C1E"))
            .frame(width: 400)
            .cornerRadius(12)
        }
    }
    
    private func createNewColumn() {
        if !newColumnTitle.isEmpty {
            noteStore.addColumn(
                title: newColumnTitle,
                color: selectedColumnColor
            )
            isAddingColumn = false
            newColumnTitle = ""
            selectedColumnColor = .blue
        }
    }
}

#Preview {
    NoteBoardView()
} 
