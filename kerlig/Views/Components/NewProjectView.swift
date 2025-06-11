import SwiftUI

struct NewProjectView: View {
    @Binding var title: String
    @Binding var description: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("New Project")
                .font(.headline)
                .padding(.top)
            
            TextField("Project Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTitleFocused)
            
            TextField("Description (Optional)", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTitleFocused = true
            }
        }
    }
}

