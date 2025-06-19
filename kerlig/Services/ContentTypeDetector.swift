import Foundation
import UniformTypeIdentifiers

// MARK: - Content Type Detection System
class ContentTypeDetector {
    
    // MARK: - Content Type Models
    struct DetectedContent {
        let type: ContentType
        let confidence: Float
        let filePath: String?
        let fileExtension: String?
        let mimeType: String?
        let description: String
        
        enum ContentType {
            case code(language: ProgrammingLanguage)
            case document(type: DocumentType)
            case media(type: MediaType)
            case data(type: DataType)
            case configuration(type: ConfigType)
            case markup(type: MarkupType)
            case text
            case unknown
            
            var icon: String {
                switch self {
                case .code: return "chevron.left.forwardslash.chevron.right"
                case .document: return "doc.text"
                case .media: return "photo.on.rectangle"
                case .data: return "tablecells"
                case .configuration: return "gear"
                case .markup: return "doc.richtext"
                case .text: return "text.alignleft"
                case .unknown: return "questionmark.circle"

                }
            }
            
            var color: String {
                switch self {
                case .code: return "blue"
                case .document: return "green"
                case .media: return "purple"
                case .data: return "orange"
                case .configuration: return "gray"
                case .markup: return "pink"
                case .text: return "primary"
                case .unknown: return "secondary"
                }
            }
        }
        
        enum ProgrammingLanguage: String, CaseIterable {
            case swift, python, javascript, typescript, java, cpp, c, csharp, php, ruby, go, rust, kotlin, scala, dart, r, matlab, shell, powershell, sql, html, css, scss, less, vue, react, angular, xml, json, yaml, toml, dockerfile, makefile, cmake, gradle, npm, yarn
            
            var displayName: String {
                switch self {
                case .swift: return "Swift"
                case .python: return "Python"
                case .javascript: return "JavaScript"
                case .typescript: return "TypeScript"
                case .java: return "Java"
                case .cpp: return "C++"
                case .c: return "C"
                case .csharp: return "C#"
                case .php: return "PHP"
                case .ruby: return "Ruby"
                case .go: return "Go"
                case .rust: return "Rust"
                case .kotlin: return "Kotlin"
                case .scala: return "Scala"
                case .dart: return "Dart"
                case .r: return "R"
                case .matlab: return "MATLAB"
                case .shell: return "Shell Script"
                case .powershell: return "PowerShell"
                case .sql: return "SQL"
                case .html: return "HTML"
                case .css: return "CSS"
                case .scss: return "SCSS"
                case .less: return "Less"
                case .vue: return "Vue.js"
                case .react: return "React"
                case .angular: return "Angular"
                case .xml: return "XML"
                case .json: return "JSON"
                case .yaml: return "YAML"
                case .toml: return "TOML"
                case .dockerfile: return "Docker"
                case .makefile: return "Makefile"
                case .cmake: return "CMake"
                case .gradle: return "Gradle"
                case .npm: return "NPM"
                case .yarn: return "Yarn"


                }
            }
        }
        
        enum DocumentType: String, CaseIterable {
            case pdf, word, excel, powerpoint, pages, numbers, keynote, rtf, plaintext, markdown
            
            var displayName: String {
                switch self {
                case .pdf: return "PDF Document"
                case .word: return "Word Document"
                case .excel: return "Excel Spreadsheet"
                case .powerpoint: return "PowerPoint Presentation"
                case .pages: return "Pages Document"
                case .numbers: return "Numbers Spreadsheet"
                case .keynote: return "Keynote Presentation"
                case .rtf: return "Rich Text Document"
                case .plaintext: return "Plain Text"
                case .markdown: return "Markdown Document"
                }
            }
        }
        
        enum MediaType: String, CaseIterable {
            case image, video, audio, font, vector
            
            var displayName: String {
                switch self {
                case .image: return "Image File"
                case .video: return "Video File"
                case .audio: return "Audio File"
                case .font: return "Font File"
                case .vector: return "Vector Graphics"
                }
            }
        }
        
        enum DataType: String, CaseIterable {
            case csv, tsv, database, archive, binary
            
            var displayName: String {
                switch self {
                case .csv: return "CSV Data"
                case .tsv: return "TSV Data"
                case .database: return "Database File"
                case .archive: return "Archive File"
                case .binary: return "Binary File"
                }
            }
        }
        
        enum ConfigType: String, CaseIterable {
            case plist, ini, env, gitignore, editorconfig, eslint, prettier, babel, webpack, vite
            
            var displayName: String {
                switch self {
                case .plist: return "Property List"
                case .ini: return "INI Configuration"
                case .env: return "Environment Variables"
                case .gitignore: return "Git Ignore"
                case .editorconfig: return "Editor Config"
                case .eslint: return "ESLint Config"
                case .prettier: return "Prettier Config"
                case .babel: return "Babel Config"
                case .webpack: return "Webpack Config"
                case .vite: return "Vite Config"
                }
            }
        }
        
        enum MarkupType: String, CaseIterable {
            case markdown, rst, asciidoc, latex, wiki
            
            var displayName: String {
                switch self {
                case .markdown: return "Markdown"
                case .rst: return "reStructuredText"
                case .asciidoc: return "AsciiDoc"
                case .latex: return "LaTeX"
                case .wiki: return "Wiki Markup"
                }
            }
        }
    }
    
    // MARK: - File Extension Mappings
    private static let extensionMappings: [String: DetectedContent.ContentType] = [
        // Programming Languages
        "swift": .code(language: .swift),
        "py": .code(language: .python),
        "pyw": .code(language: .python),
        "js": .code(language: .javascript),
        "mjs": .code(language: .javascript),
        "jsx": .code(language: .react),
        "ts": .code(language: .typescript),
        "tsx": .code(language: .react),
        "java": .code(language: .java),
        "cpp": .code(language: .cpp),
        "cxx": .code(language: .cpp),
        "cc": .code(language: .cpp),
        "c": .code(language: .c),
        "h": .code(language: .c),
        "hpp": .code(language: .cpp),
        "cs": .code(language: .csharp),
        "php": .code(language: .php),
        "rb": .code(language: .ruby),
        "go": .code(language: .go),
        "rs": .code(language: .rust),
        "kt": .code(language: .kotlin),
        "kts": .code(language: .kotlin),
        "scala": .code(language: .scala),
        "dart": .code(language: .dart),
        "r": .code(language: .r),
        "m": .code(language: .matlab),
        "sh": .code(language: .shell),
        "bash": .code(language: .shell),
        "zsh": .code(language: .shell),
        "fish": .code(language: .shell),
        "ps1": .code(language: .powershell),
        "sql": .code(language: .sql),
        "html": .code(language: .html),
        "htm": .code(language: .html),
        "css": .code(language: .css),
        "scss": .code(language: .scss),
        "sass": .code(language: .scss),
        "less": .code(language: .less),
        "vue": .code(language: .vue),
        "xml": .code(language: .xml),
        "json": .code(language: .json),
        "yaml": .code(language: .yaml),
        "yml": .code(language: .yaml),
        "toml": .code(language: .toml),
        
        // Documents
        "pdf": .document(type: .pdf),
        "doc": .document(type: .word),
        "docx": .document(type: .word),
        "xls": .document(type: .excel),
        "xlsx": .document(type: .excel),
        "ppt": .document(type: .powerpoint),
        "pptx": .document(type: .powerpoint),
        "pages": .document(type: .pages),
        "numbers": .document(type: .numbers),
        "key": .document(type: .keynote),
        "rtf": .document(type: .rtf),
        "txt": .document(type: .plaintext),
        "md": .document(type: .markdown),
        "markdown": .document(type: .markdown),
        
        // Media
        "jpg": .media(type: .image),
        "jpeg": .media(type: .image),
        "png": .media(type: .image),
        "gif": .media(type: .image),
        "bmp": .media(type: .image),
        "tiff": .media(type: .image),
        "webp": .media(type: .image),
        "svg": .media(type: .vector),
        "mp4": .media(type: .video),
        "avi": .media(type: .video),
        "mov": .media(type: .video),
        "wmv": .media(type: .video),
        "flv": .media(type: .video),
        "webm": .media(type: .video),
        "mp3": .media(type: .audio),
        "wav": .media(type: .audio),
        "flac": .media(type: .audio),
        "aac": .media(type: .audio),
        "ogg": .media(type: .audio),
        "wma": .media(type: .audio),
        "ttf": .media(type: .font),
        "otf": .media(type: .font),
        "woff": .media(type: .font),
        "woff2": .media(type: .font),
        
        // Data
        "csv": .data(type: .csv),
        "tsv": .data(type: .tsv),
        "db": .data(type: .database),
        "sqlite": .data(type: .database),
        "sqlite3": .data(type: .database),
        "zip": .data(type: .archive),
        "rar": .data(type: .archive),
        "7z": .data(type: .archive),
        "tar": .data(type: .archive),
        "gz": .data(type: .archive),
        "bz2": .data(type: .archive),
        
        // Configuration
        "plist": .configuration(type: .plist),
        "ini": .configuration(type: .ini),
        "env": .configuration(type: .env),
        "gitignore": .configuration(type: .gitignore),
        "editorconfig": .configuration(type: .editorconfig),
        "eslintrc": .configuration(type: .eslint),
        "prettierrc": .configuration(type: .prettier),
        "babelrc": .configuration(type: .babel),
        
        // Markup
        "rst": .markup(type: .rst),
        "adoc": .markup(type: .asciidoc),
        "tex": .markup(type: .latex),
        "wiki": .markup(type: .wiki)
    ]
    
    // MARK: - Path Pattern Detection
    private static let pathPatterns: [NSRegularExpression] = {
        let patterns = [
            // Unix/Linux/macOS absolute paths
            "^/[^\\s]*$",
            // Windows absolute paths
            "^[A-Za-z]:\\\\[^\\s]*$",
            // Relative paths with directory separators
            "^[^\\s]*[/\\\\][^\\s]*\\.[a-zA-Z0-9]+$",
            // File names with extensions
            "^[^\\s/\\\\]+\\.[a-zA-Z0-9]+$",
            // Hidden files (starting with dot)
            "^\\.[^\\s]+$",
            // Common project files
            "^(package\\.json|Cargo\\.toml|Gemfile|requirements\\.txt|setup\\.py|build\\.gradle|pom\\.xml|Dockerfile)$"
        ]
        
        return patterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }
    }()
    
    // MARK: - Content Analysis Patterns
    private static let contentPatterns: [(NSRegularExpression, DetectedContent.ContentType, Float)] = {
        let patterns: [(String, DetectedContent.ContentType, Float)] = [
            // Code patterns with confidence scores
            ("import\\s+\\w+|from\\s+\\w+\\s+import", .code(language: .python), 0.8),
            ("def\\s+\\w+\\s*\\(|class\\s+\\w+\\s*:", .code(language: .python), 0.9),
            ("function\\s+\\w+\\s*\\(|const\\s+\\w+\\s*=", .code(language: .javascript), 0.8),
            ("public\\s+class\\s+\\w+|package\\s+\\w+", .code(language: .java), 0.9),
            ("struct\\s+\\w+|func\\s+\\w+\\s*\\(", .code(language: .swift), 0.9),
            ("#include\\s*<|int\\s+main\\s*\\(", .code(language: .c), 0.8),
            ("SELECT\\s+.*FROM|INSERT\\s+INTO", .code(language: .sql), 0.9),
            ("<\\?php|echo\\s+", .code(language: .php), 0.9),
            ("#!/bin/(bash|sh)|if\\s*\\[", .code(language: .shell), 0.8),
            
            // Markup patterns
            ("#{1,6}\\s+.+|\\*\\*.+\\*\\*|\\[.+\\]\\(.+\\)", .markup(type: .markdown), 0.9),
            ("<html|<head|<body|<div", .code(language: .html), 0.9),
            ("\\{[^}]*:[^}]*\\}|@media|@import", .code(language: .css), 0.8),
            
            // Configuration patterns
            ("\\[.+\\]\\s*\\n.*=|.*=.*", .configuration(type: .ini), 0.7),
            ("[A-Z_]+=[^\\n]*", .configuration(type: .env), 0.8),
            
            // Data patterns
            ("[^,\\n]+,[^,\\n]+", .data(type: .csv), 0.7),
            ("\\t[^\\t\\n]+\\t", .data(type: .tsv), 0.7)
        ]
        
        return patterns.compactMap { (pattern, type, confidence) in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
            return (regex, type, confidence)
        }
    }()
    
    // MARK: - Main Detection Function
    func detectContentType(from prompt: String) -> DetectedContent? {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedPrompt.isEmpty else { return nil }
        
        let lines = trimmedPrompt.components(separatedBy: .newlines)
        var detectionResults: [DetectedContent] = []
        
        // 1. Check for file paths in each line
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines or very short lines
            guard !trimmedLine.isEmpty && trimmedLine.count >= 3 else { continue }
            
            // Check if line contains a file path
            if let pathResult = detectFilePath(in: trimmedLine) {
                detectionResults.append(pathResult)
            }
        }
        
        // 2. Analyze content patterns if no clear file paths found
        if detectionResults.isEmpty {
            if let contentResult = analyzeContentPatterns(in: trimmedPrompt) {
                detectionResults.append(contentResult)
            }
        }
        
        // 3. Return the highest confidence result
        return detectionResults.max { $0.confidence < $1.confidence }
    }
    
    // MARK: - File Path Detection
    private func detectFilePath(in line: String) -> DetectedContent? {
        // Check if line matches path patterns
        guard isValidFilePath(line) else { return nil }
        
        // Extract file extension and determine content type
        let fileExtension = extractFileExtension(from: line)
        let contentType = getContentTypeFromExtension(fileExtension)
        let confidence = calculatePathConfidence(for: line, fileExtension: fileExtension)
        
        // Get MIME type if available
        let mimeType = getMimeType(for: fileExtension)
        
        let description = generateDescription(for: contentType, filePath: line, fileExtension: fileExtension)
        
        return DetectedContent(
            type: contentType,
            confidence: confidence,
            filePath: line,
            fileExtension: fileExtension,
            mimeType: mimeType,
            description: description
        )
    }
    
    // MARK: - Content Pattern Analysis
    private func analyzeContentPatterns(in content: String) -> DetectedContent? {
        var bestMatch: (DetectedContent.ContentType, Float) = (.text, 0.0)
        
        for (pattern, contentType, baseConfidence) in Self.contentPatterns {
            let matches = pattern.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            
            if !matches.isEmpty {
                // Calculate confidence based on number of matches and content length
                let matchCount = Float(matches.count)
                let contentLength = Float(content.count)
                let confidence = min(baseConfidence + (matchCount / (contentLength / 100)) * 0.1, 1.0)
                
                if confidence > bestMatch.1 {
                    bestMatch = (contentType, confidence)
                }
            }
        }
        
        guard bestMatch.1 > 0.3 else { return nil } // Minimum confidence threshold
        
        let description = generateDescription(for: bestMatch.0, filePath: nil, fileExtension: nil)
        
        return DetectedContent(
            type: bestMatch.0,
            confidence: bestMatch.1,
            filePath: nil,
            fileExtension: nil,
            mimeType: nil,
            description: description
        )
    }
    
    // MARK: - Helper Functions
    
    private func isValidFilePath(_ path: String) -> Bool {
        return Self.pathPatterns.contains { pattern in
            let range = NSRange(path.startIndex..., in: path)
            return pattern.firstMatch(in: path, options: [], range: range) != nil
        }
    }
    
    private func extractFileExtension(from path: String) -> String? {
        // Handle special cases first
        let fileName = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        
        // Check for files without traditional extensions
        let specialFiles = [
            "dockerfile", "makefile", "rakefile", "gemfile", "vagrantfile",
            "package.json", "composer.json", "cargo.toml", "pyproject.toml",
            ".gitignore", ".eslintrc", ".prettierrc", ".babelrc", ".editorconfig"
        ]
        
        for specialFile in specialFiles {
            if fileName.contains(specialFile) {
                return specialFile.replacingOccurrences(of: ".", with: "")
            }
        }
        
        // Extract traditional file extension
        let components = path.components(separatedBy: ".")
        guard components.count > 1 else { return nil }
        
        return components.last?.lowercased()
    }
    
    private func getContentTypeFromExtension(_ fileExtension: String?) -> DetectedContent.ContentType {
        guard let ext = fileExtension?.lowercased() else { return .unknown }
        return Self.extensionMappings[ext] ?? .unknown
    }
    
    private func calculatePathConfidence(for path: String, fileExtension: String?) -> Float {
        var confidence: Float = 0.5 // Base confidence for valid path
        
        // Increase confidence for absolute paths
        if path.hasPrefix("/") || path.matches("^[A-Za-z]:\\\\") {
            confidence += 0.2
        }
        
        // Increase confidence for known extensions
        if let ext = fileExtension, Self.extensionMappings[ext] != nil {
            confidence += 0.3
        }
        
        // Increase confidence for common file patterns
        let commonPatterns = ["src/", "lib/", "bin/", "test/", "tests/", "docs/", "config/"]
        if commonPatterns.contains(where: path.lowercased().contains) {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private func getMimeType(for fileExtension: String?) -> String? {
        guard let ext = fileExtension else { return nil }
        
        if #available(macOS 11.0, *) {
            let utType = UTType(filenameExtension: ext)
            return utType?.preferredMIMEType
        }
        
        // Fallback for older systems
        let commonMimeTypes: [String: String] = [
            "txt": "text/plain",
            "json": "application/json",
            "xml": "application/xml",
            "html": "text/html",
            "css": "text/css",
            "js": "text/javascript",
            "py": "text/x-python",
            "swift": "text/x-swift",
            "java": "text/x-java-source",
            "cpp": "text/x-c++src",
            "c": "text/x-csrc"
        ]
        
        return commonMimeTypes[ext]
    }
    
    private func generateDescription(for contentType: DetectedContent.ContentType, filePath: String?, fileExtension: String?) -> String {
        switch contentType {
        case .code(let language):
            return "\(language.displayName) source code"
        case .document(let docType):
            return docType.displayName
        case .media(let mediaType):
            return mediaType.displayName
        case .data(let dataType):
            return dataType.displayName
        case .configuration(let configType):
            return configType.displayName
        case .markup(let markupType):
            return markupType.displayName
        case .text:
            return "Plain text content"
        case .unknown:
            if let ext = fileExtension {
                return "File with .\(ext) extension"
            } else if filePath != nil {
                return "Unknown file type"
            } else {
                return "Unknown content type"
            }
        }
    }
}

// MARK: - String Extension for Regex Matching
extension String {
    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

// MARK: - Dynamic Content Analysis Extensions
extension ContentTypeDetector {
    
    // MARK: - Advanced Detection Methods
    
    /// Detects multiple content types from a complex prompt
    func detectMultipleContentTypes(from prompt: String) -> [DetectedContent] {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return [] }
        
        let lines = trimmedPrompt.components(separatedBy: .newlines)
        var results: [DetectedContent] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty && trimmedLine.count >= 3 else { continue }
            
            if let result = detectFilePath(in: trimmedLine) {
                results.append(result)
            }
        }
        
        // If no file paths found, analyze the entire content
        if results.isEmpty, let contentResult = analyzeContentPatterns(in: trimmedPrompt) {
            results.append(contentResult)
        }
        
        return results.sorted { $0.confidence > $1.confidence }
    }
    
    /// Provides contextual suggestions based on detected content
    func getContextualSuggestions(for detectedContent: DetectedContent) -> [String] {
        switch detectedContent.type {
        case .code(let language):
            return getCodeSuggestions(for: language)
        case .document(let docType):
            return getDocumentSuggestions(for: docType)
        case .media(let mediaType):
            return getMediaSuggestions(for: mediaType)
        case .data(let dataType):
            return getDataSuggestions(for: dataType)
        case .configuration(let configType):
            return getConfigSuggestions(for: configType)
        case .markup(let markupType):
            return getMarkupSuggestions(for: markupType)
        case .text:
            return ["Analyze content", "Extract key information", "Summarize", "Format text"]
        case .unknown:
            return ["Identify content type", "Analyze structure", "Extract information"]
        }
    }
    
    // MARK: - Suggestion Helpers
    
    private func getCodeSuggestions(for language: DetectedContent.ProgrammingLanguage) -> [String] {
        let commonSuggestions = ["Review code", "Explain functionality", "Find bugs", "Optimize performance", "Add comments"]
        
        switch language {
        case .swift:
            return commonSuggestions + ["Convert to SwiftUI", "Add error handling", "Implement protocols"]
        case .python:
            return commonSuggestions + ["Add type hints", "Follow PEP 8", "Create virtual environment"]
        case .javascript, .typescript:
            return commonSuggestions + ["Add TypeScript types", "Implement async/await", "Bundle for production"]
        case .java:
            return commonSuggestions + ["Add unit tests", "Implement design patterns", "Handle exceptions"]
        case .sql:
            return ["Optimize query", "Add indexes", "Explain execution plan", "Check performance"]
        default:
            return commonSuggestions
        }
    }
    
    private func getDocumentSuggestions(for docType: DetectedContent.DocumentType) -> [String] {
        switch docType {
        case .markdown:
            return ["Convert to HTML", "Add table of contents", "Format tables", "Check links"]
        case .pdf:
            return ["Extract text", "Convert to other format", "Analyze structure", "Extract metadata"]
        case .plaintext:
            return ["Format content", "Add structure", "Convert to markdown", "Analyze text"]
        default:
            return ["Open document", "Convert format", "Extract text", "Analyze content"]
        }
    }
    
    private func getMediaSuggestions(for mediaType: DetectedContent.MediaType) -> [String] {
        switch mediaType {
        case .image:
            return ["Analyze image", "Extract text (OCR)", "Resize/optimize", "Get metadata"]
        case .video:
            return ["Extract frames", "Get metadata", "Convert format", "Analyze content"]
        case .audio:
            return ["Transcribe audio", "Extract metadata", "Convert format", "Analyze audio"]
        default:
            return ["Open file", "Get information", "Convert format"]
        }
    }
    
    private func getDataSuggestions(for dataType: DetectedContent.DataType) -> [String] {
        switch dataType {
        case .csv, .tsv:
            return ["Analyze data", "Create charts", "Clean data", "Export to other format"]
        case .database:
            return ["Query data", "Analyze schema", "Backup database", "Optimize queries"]
        case .archive:
            return ["Extract files", "List contents", "Verify integrity", "Create new archive"]
        default:
            return ["Analyze structure", "Extract information", "Process data"]
        }
    }
    
    private func getConfigSuggestions(for configType: DetectedContent.ConfigType) -> [String] {
        switch configType {
        case .gitignore:
            return ["Add patterns", "Validate rules", "Generate template", "Check coverage"]
        case .eslint, .prettier:
            return ["Update rules", "Fix formatting", "Add plugins", "Validate config"]
        case .env:
            return ["Validate variables", "Add security check", "Document variables", "Create template"]
        default:
            return ["Validate syntax", "Update settings", "Add documentation", "Check security"]
        }
    }
    
    private func getMarkupSuggestions(for markupType: DetectedContent.MarkupType) -> [String] {
        switch markupType {
        case .markdown:
            return ["Convert to HTML", "Add table of contents", "Check links", "Format tables"]
        case .latex:
            return ["Compile to PDF", "Check syntax", "Add bibliography", "Format equations"]
        default:
            return ["Convert format", "Validate syntax", "Add formatting", "Export document"]
        }
    }
}

// MARK: - Usage Example and Testing
extension ContentTypeDetector {
    
    /// Example function demonstrating usage
    static func example() {
        let detector = ContentTypeDetector()
        
        let testCases = [
            "/Users/john/Documents/project/main.swift",
            "src/components/Button.tsx",
            "package.json",
            "def hello_world():\n    print('Hello, World!')",
            "SELECT * FROM users WHERE age > 21;",
            "# My Project\n\nThis is a **markdown** document with [links](http://example.com).",
            "function calculateSum(a, b) {\n    return a + b;\n}",
            "dockerfile",
            ".gitignore",
            "config.yaml"
        ]
        
        print("🔍 Content Type Detection Examples:\n")
        
        for testCase in testCases {
            if let result = detector.detectContentType(from: testCase) {
                print("📄 Content: '\(String(testCase.prefix(50)))...'")
                print("🏷️  Type: \(result.description)")
                print("📊 Confidence: \(String(format: "%.1f%%", result.confidence * 100))")
                print("💡 Suggestions: \(detector.getContextualSuggestions(for: result).joined(separator: ", "))")
                print("---")
            }
        }
    }
}
