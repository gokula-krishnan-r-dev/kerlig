import SwiftUI
import Combine

struct PortMonitorView: View {
    @StateObject private var scannerService = PortScannerService(autoRefreshInterval: 10)
    @State private var searchText = ""
    @State private var isShowingDialog = false
    @State private var dialogMessage = ""
    @State private var selectedPortProtocol: PortInfo.PortProtocol? = nil
    @State private var showOnlyProjects = false
    
    private var filteredPorts: [PortInfo] {
        var filtered = scannerService.ports
        
        // Filter by protocol if selected
        if let protocolFilter = selectedPortProtocol {
            filtered = filtered.filter { $0.protocol == protocolFilter }
        }
        
        // Filter to show only ports with project info if enabled
        if showOnlyProjects {
            filtered = filtered.filter { $0.projectInfo != nil }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { port in
                let portString = String(port.port)
                let pidString = String(port.pid)
                
                return portString.contains(lowercasedSearch) ||
                       port.processName.lowercased().contains(lowercasedSearch) ||
                       port.command.lowercased().contains(lowercasedSearch) ||
                       pidString.contains(lowercasedSearch) ||
                       (port.projectInfo?.name.lowercased().contains(lowercasedSearch) ?? false)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search and filters
            filterBar
            
            // Main content
            if scannerService.isLoading && scannerService.ports.isEmpty {
                loadingView
            } else if let error = scannerService.error {
                errorView(error)
            } else if filteredPorts.isEmpty {
                emptyStateView
            } else {
                portListView
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            scannerService.scanPorts()
        }
        .alert(isPresented: $isShowingDialog) {
            Alert(
                title: Text("Port Monitor"),
                message: Text(dialogMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Header view
    private var headerView: some View {
        HStack {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                
                Text("Active Ports Monitor")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Spacer()
            
            // Refresh button
            Button(action: {
                scannerService.scanPorts()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(scannerService.isLoading)
            .opacity(scannerService.isLoading ? 0.5 : 1.0)
            .help("Refresh Ports")
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
    
    // Filter and search bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search by port, process, or project", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(6)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Protocol filter
            Menu {
                Button("All Protocols", action: { selectedPortProtocol = nil })
                Button("TCP Only", action: { selectedPortProtocol = .tcp })
                Button("UDP Only", action: { selectedPortProtocol = .udp })
            } label: {
                HStack {
                    Text(selectedPortProtocol == nil ? "All Protocols" : 
                         selectedPortProtocol == .tcp ? "TCP Only" : "UDP Only")
                        .font(.system(size: 13))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            // Project filter toggle
            Toggle(isOn: $showOnlyProjects) {
                Text("Show Projects Only")
                    .font(.system(size: 13))
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            
            // Total count
            Text("\(filteredPorts.count) ports")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .background(Color(.windowBackgroundColor))
    }
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Scanning ports...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    // Error view
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Error scanning ports")
                .font(.system(size: 18, weight: .semibold))
            
            Text(error.localizedDescription)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Try Again") {
                scannerService.scanPorts()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "network.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty || selectedPortProtocol != nil || showOnlyProjects {
                Text("No matching ports found")
                    .font(.system(size: 18, weight: .semibold))
                
                Button("Clear Filters") {
                    searchText = ""
                    selectedPortProtocol = nil
                    showOnlyProjects = false
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.top, 10)
            } else {
                Text("No active ports found")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("There are no network connections currently active on your system.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    // Port list view
    private var portListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredPorts) { port in
                    PortListItemView(
                        port: port,
                        onStop: {
                            stopProcess(port)
                        },
                        onRestart: {
                            restartService(port)
                        },
                        onOpenInVSCode: {
                            openInVSCode(port)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.windowBackgroundColor))
        // Pull to refresh functionality
        .overlay(alignment: .top) {
            if scannerService.isLoading {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
            }
        }
    }
    
    // MARK: - Actions
    
    // Stop a process
    private func stopProcess(_ port: PortInfo) {
        scannerService.terminateProcess(pid: port.pid)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    dialogMessage = "Failed to stop process: \(error.localizedDescription)"
                    isShowingDialog = true
                }
            }, receiveValue: { _ in
                dialogMessage = "Process terminated successfully."
                isShowingDialog = true
            })
//            .store(in: &scannerService.cancellables)
    }
    
    // Restart a service
    private func restartService(_ port: PortInfo) {
        scannerService.restartService(for: port)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    dialogMessage = "Failed to restart service: \(error.localizedDescription)"
                    isShowingDialog = true
                }
            }, receiveValue: { _ in
                dialogMessage = "Service restarted successfully."
                isShowingDialog = true
            })
//            .store(in: &scannerService.cancellables)
    }
    
    // Open project in VS Code
    private func openInVSCode(_ port: PortInfo) {
        guard let projectInfo = port.projectInfo, let path = projectInfo.path else {
            dialogMessage = "No project path available."
            isShowingDialog = true
            return
        }
        
        scannerService.openInVSCode(path: path)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    dialogMessage = "Failed to open in VS Code: \(error.localizedDescription)"
                    isShowingDialog = true
                }
            }, receiveValue: { _ in
                // Success - no need to show dialog
            })
//            .store(in: &scannerService.cancellables)
    }
} 
                        