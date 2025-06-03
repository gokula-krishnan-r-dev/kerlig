import Foundation
import SwiftUI
import Combine

class PortScannerService: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with optional auto-refresh interval
    init(autoRefreshInterval: TimeInterval? = nil) {
        if let interval = autoRefreshInterval {
            setupAutoRefresh(interval: interval)
        }
    }
    
    // Setup auto-refresh timer
    func setupAutoRefresh(interval: TimeInterval) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.scanPorts()
        }
    }
    
    // Disable auto-refresh
    func disableAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // Main function to scan for open ports
    func scanPorts() {
        isLoading = true
        error = nil
        
        // Execute lsof command to get open ports
        executeLSOFCommand()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] ports in
                self?.ports = ports
            })
            .store(in: &cancellables)
    }
    
    // Execute lsof command to get open ports
    private func executeLSOFCommand() -> AnyPublisher<[PortInfo], Error> {
        return Future<[PortInfo], Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Run lsof to get open ports (requires admin privileges)
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
                    process.arguments = ["-i", "-P", "-n"]
                    
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    
                    try process.run()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let output = String(data: data, encoding: .utf8) else {
                        throw NSError(domain: "PortScannerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode command output"])
                    }
                    
                    process.waitUntilExit()
                    
                    let ports = self.parseLSOFOutput(output)
                    
                    // Detect project info for each port
                    let portsWithProjectInfo = ports.map { port in
                        var portWithInfo = port
                        if let projectInfo = self.detectProjectInfo(for: port) {
                            portWithInfo = PortInfo(
                                port: port.port,
                                pid: port.pid,
                                processName: port.processName,
                                command: port.command,
                                user: port.user,
                                protocol: port.protocol,
                                status: port.status,
                                projectInfo: projectInfo
                            )
                        }
                        return portWithInfo
                    }
                    
                    promise(.success(portsWithProjectInfo))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Parse the lsof command output
    private func parseLSOFOutput(_ output: String) -> [PortInfo] {
        var results: [PortInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        // Skip header line
        for line in lines.dropFirst() where !line.isEmpty {
            let components = line.components(separatedBy: CharacterSet.whitespaces)
                .filter { !$0.isEmpty }
            
            // lsof output format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            if components.count >= 9 {
                let command = components[0]
                guard let pid = Int(components[1]) else { continue }
                let user = components[2]
                
                // Parse the port info from the NAME field (e.g., "127.0.0.1:8080 (LISTEN)")
                let addressInfo = components[8]
                var protocolType: PortInfo.PortProtocol = .tcp
                var status: PortInfo.PortStatus = .other
                
                if line.contains("UDP") {
                    protocolType = .udp
                }
                
                if line.contains("(LISTEN)") {
                    status = .listening
                } else if line.contains("(ESTABLISHED)") {
                    status = .established
                }
                
                // Extract port number from address
                if let portRange = addressInfo.range(of: ":[0-9]+", options: .regularExpression) {
                    let portString = String(addressInfo[portRange])
                        .replacingOccurrences(of: ":", with: "")
                    
                    if let port = Int(portString) {
                        // Find the process name using ps command
                        let processName = getProcessName(for: pid) ?? command
                        
                        // Create PortInfo
                        let portInfo = PortInfo(
                            port: port,
                            pid: pid,
                            processName: processName,
                            command: command,
                            user: user,
                            protocol: protocolType,
                            status: status,
                            projectInfo: nil
                        )
                        
                        results.append(portInfo)
                    }
                }
            }
        }
        
        return results
    }
    
    // Get process name using ps command
    private func getProcessName(for pid: Int) -> String? {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/ps")
            process.arguments = ["-p", "\(pid)", "-o", "comm="]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output
            }
            
            return nil
        } catch {
            print("Error getting process name: \(error)")
            return nil
        }
    }
    
    // Detect project information based on port and process
    private func detectProjectInfo(for port: PortInfo) -> ProjectInfo? {
        // Get working directory of the process
        guard let workingDir = getProcessWorkingDirectory(for: port.pid) else {
            return nil
        }
        
        // Detect project type based on port and process name
        var projectType: ProjectType = .unknown
        var projectName = "Unknown Project"
        
        // Check for common port patterns
        switch port.port {
        case 3000...3999:
            if port.processName.lowercased().contains("node") {
                projectType = .react
                projectName = getProjectNameFromPath(workingDir) ?? "React/Node Project"
            }
        case 8000...8999:
            if port.processName.lowercased().contains("python") {
                projectType = .django
                projectName = getProjectNameFromPath(workingDir) ?? "Django/Flask Project"
            }
        case 4000...4999:
            if port.processName.lowercased().contains("next") {
                projectType = .nextjs
                projectName = getProjectNameFromPath(workingDir) ?? "Next.js Project"
            }
        default:
            break
        }
        
        // Further refine project type based on files in the working directory
        if projectType == .unknown {
            (projectType, projectName) = detectProjectTypeFromFiles(in: workingDir)
        }
        
        return ProjectInfo(name: projectName, type: projectType, path: workingDir)
    }
    
    // Get working directory of a process
    private func getProcessWorkingDirectory(for pid: Int) -> String? {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/lsof")
            process.arguments = ["-p", "\(pid)", "-a", "-d", "cwd", "-Fn"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Extract working directory from output format "ncwd"
                if let dirLine = output.components(separatedBy: "\n").first(where: { $0.hasPrefix("n") }) {
                    return String(dirLine.dropFirst())
                }
            }
            
            return nil
        } catch {
            print("Error getting working directory: \(error)")
            return nil
        }
    }
    
    // Extract project name from path
    private func getProjectNameFromPath(_ path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }
    
    // Detect project type based on files in directory
    private func detectProjectTypeFromFiles(in directory: String) -> (ProjectType, String) {
        do {
            let fileManager = FileManager.default
            let fileURLs = try fileManager.contentsOfDirectory(atPath: directory)
            
            // Check for package.json (Node.js, React, Next.js)
            if fileURLs.contains("package.json") {
                if let packageData = try? Data(contentsOf: URL(fileURLWithPath: "\(directory)/package.json")),
                   let packageJson = try? JSONSerialization.jsonObject(with: packageData) as? [String: Any],
                   let name = packageJson["name"] as? String {
                    
                    // Check for specific dependencies
                    if let dependencies = packageJson["dependencies"] as? [String: Any] {
                        if dependencies["next"] != nil {
                            return (.nextjs, name)
                        }
                        
                        if dependencies["react"] != nil {
                            return (.react, name)
                        }
                        
                        if dependencies["vue"] != nil {
                            return (.vue, name)
                        }
                        
                        if dependencies["@angular/core"] != nil {
                            return (.angular, name)
                        }
                    }
                    
                    return (.node, name)
                }
                
                // Default Node.js if package.json exists but couldn't be parsed
                return (.node, getProjectNameFromPath(directory) ?? "Node.js Project")
            }
            
            // Check for requirements.txt (Python)
            if fileURLs.contains("requirements.txt") {
                if fileURLs.contains("manage.py") {
                    return (.django, getProjectNameFromPath(directory) ?? "Django Project")
                }
                return (.python, getProjectNameFromPath(directory) ?? "Python Project")
            }
            
            // Check for Gemfile (Ruby/Rails)
            if fileURLs.contains("Gemfile") {
                if fileURLs.contains("config/routes.rb") {
                    return (.rails, getProjectNameFromPath(directory) ?? "Rails Project")
                }
                return (.ruby, getProjectNameFromPath(directory) ?? "Ruby Project")
            }
            
            // Check for go.mod (Go)
            if fileURLs.contains("go.mod") {
                return (.go, getProjectNameFromPath(directory) ?? "Go Project")
            }
            
            // Check for Cargo.toml (Rust)
            if fileURLs.contains("Cargo.toml") {
                return (.rust, getProjectNameFromPath(directory) ?? "Rust Project")
            }
            
            // Default to unknown
            return (.unknown, getProjectNameFromPath(directory) ?? "Unknown Project")
            
        } catch {
            print("Error detecting project type: \(error)")
            return (.unknown, getProjectNameFromPath(directory) ?? "Unknown Project")
        }
    }
    
    // Terminate a process
    func terminateProcess(pid: Int) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/bin/kill")
                    process.arguments = ["\(pid)"]
                    
                    try process.run()
                    process.waitUntilExit()
                    
                    // Refresh the port list after termination
                    DispatchQueue.main.async {
                        self.scanPorts()
                    }
                    
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Restart a service based on project type
    func restartService(for port: PortInfo) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            guard let projectInfo = port.projectInfo, let path = projectInfo.path else {
                promise(.failure(NSError(domain: "PortScannerService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No project info available"])))
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // First terminate the current process
                    let killProcess = Process()
                    killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
                    killProcess.arguments = ["\(port.pid)"]
                    
                    try killProcess.run()
                    killProcess.waitUntilExit()
                    
                    // Then start a new process based on project type
                    let startProcess = Process()
                    startProcess.currentDirectoryURL = URL(fileURLWithPath: path)
                    
                    switch projectInfo.type {
                    case .nextjs, .react, .node:
                        if FileManager.default.fileExists(atPath: "\(path)/yarn.lock") {
                            startProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                            startProcess.arguments = ["yarn", "dev"]
                        } else {
                            startProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                            startProcess.arguments = ["npm", "run", "dev"]
                        }
                        
                    case .python, .django:
                        if FileManager.default.fileExists(atPath: "\(path)/manage.py") {
                            startProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                            startProcess.arguments = ["python", "manage.py", "runserver"]
                        } else if FileManager.default.fileExists(atPath: "\(path)/app.py") {
                            startProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                            startProcess.arguments = ["python", "app.py"]
                        }
                        
                    default:
                        promise(.failure(NSError(domain: "PortScannerService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unsupported project type for restart"])))
                        return
                    }
                    
                    // Redirect output to /dev/null
                    let outputPipe = Pipe()
                    startProcess.standardOutput = outputPipe
                    startProcess.standardError = outputPipe
                    
                    // Run in background
                    try startProcess.run()
                    
                    // Refresh the port list after restart
                    DispatchQueue.main.async {
                        // Wait a moment for the service to start
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.scanPorts()
                        }
                    }
                    
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Open project in VS Code
    func openInVSCode(path: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-a", "Visual Studio Code", path]
                    
                    try process.run()
                    process.waitUntilExit()
                    
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
} 