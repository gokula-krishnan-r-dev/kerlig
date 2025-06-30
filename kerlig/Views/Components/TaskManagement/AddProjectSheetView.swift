import  SwiftUI

struct AddProjectSheetView: View {
    @Environment(\.dismiss) private var dismiss

    // Bindings for parent view state
    @Binding var isAddingProject: Bool
    @Binding var newProjectTitle: String
    @Binding var newProjectDescription: String
    @Binding var newProjectLogoImage: NSImage?
    @Binding var isShowingImagePicker: Bool
    @Binding var newProjectColor: Color
    
    // Properties passed from parent
    let availableColors: [Color]
    let resetProjectForm: () -> Void
    let createProject: () -> Void
    let secondaryBgColor: Color
    let handleImageSelection: (Result<[URL], Error>) -> Void
    let cardBgColor: Color
    let accentColor: Color
    let accentGradient: LinearGradient

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Project")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    isAddingProject = false
                    resetProjectForm()
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(secondaryBgColor)
            
            // Form
            ScrollView {
                VStack(spacing: 24) {
                    // Logo upload section
                    VStack(alignment: .center, spacing: 12) {
                        if let logoImage = newProjectLogoImage {
                            Image(nsImage: logoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(newProjectColor)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                                .shadow(color: newProjectColor.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(newProjectLogoImage == nil ? "Upload Logo" : "Change Logo")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(8)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .fileImporter(
                            isPresented: $isShowingImagePicker,
                            allowedContentTypes: [.image],
                            allowsMultipleSelection: false
                        ) { result in
                            handleImageSelection(result)
                        }
                        
                        if newProjectLogoImage != nil {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    newProjectLogoImage = nil
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                    Text("Remove Logo")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter project title", text: $newProjectTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                            .onSubmit {
                                if !newProjectTitle.isEmpty && !newProjectDescription.isEmpty {
                                    createProject()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter project description", text: $newProjectDescription, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                            .frame(minHeight: 80)
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
                                                .stroke(Color.white, lineWidth: newProjectColor == color ? 3 : 0)
                                            
                                            if newProjectColor == color {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            newProjectColor = color
                                        }
                                    }
                            }
                        }
                    }
                    
                    Button(action: {
                        createProject()
                    }) {
                        Text("Create Project")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGradient)
                            .cornerRadius(8)
                            .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .disabled(newProjectTitle.isEmpty || newProjectDescription.isEmpty)
                    .opacity((newProjectTitle.isEmpty || newProjectDescription.isEmpty) ? 0.6 : 1)
                }
                .padding()
            }
        }
        .background(secondaryBgColor)
        .frame(width: 500, height: 650)
        .cornerRadius(12)
    }
}