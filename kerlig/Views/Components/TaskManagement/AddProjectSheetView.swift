import  SwiftUI

// MARK: - UI Enhancements
// This edit introduces:
// 1. Environment-aware colours for automatic light / dark adaptation.
// 2. A compact "close" button that replaces the text-based Cancel link.
// 3. Dynamic colour helpers to avoid hard-coded .white values.
// 4. Minor layout tweaks to ensure the sheet looks good on a single screen size.
struct AddProjectSheetView: View {
    // Make the view respect system light / dark mode
    @Environment(\.colorScheme) private var colorScheme
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

    // MARK: - Additional UI States inspired by reference design
    @State private var selectedInputOption: String = "Clearly conveys the focus on problem-solving"
    private let inputOptions: [String] = [
        "Clearly conveys the focus on problem-solving",
        "Highlights product benefits",
        "Engaging opening statement"
    ]

    @State private var templateQuery: String = ""
    @State private var selectedTemplates: [String] = ["Blog Ideas"]
    private let allTemplateSuggestions: [String] = ["Case Study", "Blog Case", "White Paper", "Product Guide"]

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.1)
    }
 
    // Computed dynamic colours
    private var headerBackground: Color {
        colorScheme == .dark ? secondaryBgColor : Color(NSColor.windowBackgroundColor)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? cardBgColor : Color(NSColor.controlBackgroundColor)
    }

    private var primaryTextColor: Color { .primary }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider().opacity(0)
            formContent
        }
        .background(headerBackground)
        .frame(minWidth: 480, idealWidth: 560, maxWidth: 640,
               minHeight: 560, idealHeight: 620, maxHeight: 720)
        .cornerRadius(12)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Project")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                Text("Your created project will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                dismiss()
                resetProjectForm()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(primaryTextColor.opacity(0.05))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(headerBackground)
    }

    // MARK: - Form
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                uploadLogoSection
                projectTitleSection
                descriptionSection
                inputContentListSection
                templateSection
                colorSection
                createButton
            }
            .padding()
        }
    }

    private var uploadLogoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upload Project Logo")
                .font(.headline)
                .foregroundColor(primaryTextColor)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .background(RoundedRectangle(cornerRadius: 12).fill(cardBackground))

                if let logoImage = newProjectLogoImage {
                    Image(nsImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 120, maxHeight: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.up.fill")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                        Text("Click to upload or drag and drop")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentColor)
                        Text("Max. File Size: 25MB")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
            }
            .frame(height: 160)
            .onTapGesture { isShowingImagePicker = true }
            .fileImporter(
                isPresented: $isShowingImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                handleImageSelection(result)
            }
        }
    }

    private var projectTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Title")
                .font(.headline)
                .foregroundColor(primaryTextColor)
            TextField("Enter project title", text: $newProjectTitle)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(primaryTextColor)
                .padding()
                .background(cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
                .cornerRadius(8)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(primaryTextColor)
            TextField("Enter project description", text: $newProjectDescription, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(primaryTextColor)
                .padding()
                .background(cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
                .cornerRadius(8)
                .frame(minHeight: 80)
        }
    }

    private var inputContentListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input from Content List")
                .font(.headline)
                .foregroundColor(primaryTextColor)

            Menu {
                ForEach(inputOptions, id: \.self) { option in
                    Button(option) { selectedInputOption = option }
                }
            } label: {
                HStack {
                    Text(selectedInputOption)
                        .foregroundColor(primaryTextColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose Content Template")
                .font(.headline)
                .foregroundColor(primaryTextColor)

            VStack(alignment: .leading, spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTemplates, id: \.self) { template in
                            TagChip(title: template) {
                                selectedTemplates.removeAll { $0 == template }
                            }
                        }
                        TextField("Type template", text: $templateQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(minWidth: 100)
                            .onSubmit { addTemplate() }
                    }
                    .padding(8)
                }

                if !templateQuery.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(allTemplateSuggestions.filter { $0.lowercased().contains(templateQuery.lowercased()) }, id: \.self) { suggestion in
                            Button(action: {
                                templateQuery = ""
                                if !selectedTemplates.contains(suggestion) {
                                    selectedTemplates.append(suggestion)
                                }
                            }) {
                                HStack {
                                    Text(suggestion)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
                }
            }
            .background(cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
            .cornerRadius(8)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
                .foregroundColor(primaryTextColor)
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
    }

    private var createButton: some View {
        Button(action: { createProject() }) {
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

    // MARK: - Helpers
    private func addTemplate() {
        let trimmed = templateQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !selectedTemplates.contains(trimmed) {
            selectedTemplates.append(trimmed)
        }
        templateQuery = ""
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let title: String
    var onRemove: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.1))
        .clipShape(Capsule())
    }
}