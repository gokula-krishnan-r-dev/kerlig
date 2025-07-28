import SwiftUI
import UniformTypeIdentifiers

struct NotionImportView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var isFilePickerPresented = false
    @State private var showImportSummary = false
    @State private var importError: String?
    @State private var showErrorAlert = false
    
    // Optional project/release context
    let selectedProject: Project?
    let selectedRelease: Release?
    
    init(selectedProject: Project? = nil, selectedRelease: Release? = nil) {
        self.selectedProject = selectedProject
        self.selectedRelease = selectedRelease
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if noteStore.isImporting {
                importProgressView
            } else {
                importButton
            }
            
            if noteStore.lastImportSummary != nil && showImportSummary {
                importSummaryView
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Error", isPresented: $showErrorAlert) {
            Button("OK") {
                importError = nil
            }
        } message: {
            Text(importError ?? "An unknown error occurred")
        }
    }
    
    private var importButton: some View {
        Button(action: {
            isFilePickerPresented = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .foregroundColor(Color(hex: "#6366F1"))
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("IMPORT FROM NOTION")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#6366F1"))
                    
                    Text("Select CSV file")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#6366F1").opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#6366F1").opacity(0.5))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#6366F1").opacity(0.08),
                                Color(hex: "#6366F1").opacity(0.04)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#6366F1").opacity(0.3),
                                        Color(hex: "#6366F1").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(noteStore.isImporting ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: noteStore.isImporting)
    }
    
    private var importProgressView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#6366F1").opacity(0.2), lineWidth: 3)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .trim(from: 0, to: noteStore.importProgress)
                        .stroke(Color(hex: "#6366F1"), lineWidth: 3)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: noteStore.importProgress)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("IMPORTING TASKS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#6366F1"))
                    
                    Text(noteStore.importStatus)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#6366F1").opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text("\(Int(noteStore.importProgress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6366F1"))
            }
            
            ProgressView(value: noteStore.importProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#6366F1")))
                .scaleEffect(y: 0.8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#6366F1").opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#6366F1").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var importSummaryView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Import Complete")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showImportSummary = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 10, weight: .medium))
                }
            }
            
            if let summary = noteStore.lastImportSummary {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.importedTasks)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Imported")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.skippedTasks)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Skipped")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(summary.successRate * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Success")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#10B981"),
                            Color(hex: "#059669")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let summary = try await noteStore.importNotionCSV(
                        from: url,
                        selectedProject: selectedProject,
                        selectedRelease: selectedRelease
                    )
                    
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showImportSummary = true
                        }
                        
                        // Auto-hide summary after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showImportSummary = false
                            }
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            }
            
        case .failure(let error):
            importError = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - Preview
struct NotionImportView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            NotionImportView()
                .environmentObject(NoteStore())
            
            NotionImportView()
                .environmentObject({
                    let store = NoteStore()
                    store.isImporting = true
                    store.importProgress = 0.65
                    store.importStatus = "Processing task 15 of 23..."
                    return store
                }())
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        .preferredColorScheme(.dark)
    }
} 