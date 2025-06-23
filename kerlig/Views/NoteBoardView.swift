import SwiftUI

struct NoteBoardView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var isAddingColumn = false
    @State private var newColumnTitle = ""
    @State private var selectedColumnColor: Color = .blue
    @Environment(\.colorScheme) private var colorScheme
    private let floatingSidebarController = FloatingSidebarController()
    
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
                    withAnimation {
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
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            // Board content
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(noteStore.columns.sorted(by: { $0.order < $1.order })) { column in
                        NoteColumnView(
                            column: column,
                            notes: noteStore.getNotesForColumn(column),
                            noteStore: noteStore
                        )
                    }
                    
                    // Add column button
                    Button(action: {
                        isAddingColumn = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2)
                            Text("Add Column")
                                .font(.headline)
                        }
                        .foregroundColor(.gray)
                        .frame(width: 200, height: 100)
                        .background(Color(hex: "#1C1C1E"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
                
                VStack(spacing: 16) {
                    TextField("Column Title", text: $newColumnTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                        .onSubmit {
                            createNewColumn()
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColumnColor == color ? 3 : 0)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
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
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    .disabled(newColumnTitle.isEmpty)
                }
                .padding()
            }
            .background(Color(hex: "#1C1C1E"))
            .frame(width: 400)
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
