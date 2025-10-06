import Foundation
import SwiftUI
import Combine

// MARK: - AI Model Data Structures

struct ModelOption: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let iconColor: Color
    let cost: Double
    let provider: String
    let capabilities: String
    let speed: String
    let description: String?
    let isRecommended: Bool
    let category: ModelCategory
    
    init(id: String, name: String, iconName: String, iconColor: Color, cost: Double, provider: String, capabilities: String, speed: String, description: String? = nil, isRecommended: Bool = false, category: ModelCategory = .textGeneration) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.iconColor = iconColor
        self.cost = cost
        self.provider = provider
        self.capabilities = capabilities
        self.speed = speed
        self.description = description
        self.isRecommended = isRecommended
        self.category = category
    }
    
    var formattedCost: String {
        return "$\(String(format: "%.5f", cost))/request"
    }
    
    var speedLevel: SpeedLevel {
        switch speed.lowercased() {
        case "very fast": return .veryFast
        case "fast": return .fast
        case "medium": return .medium
        case "slow": return .slow
        default: return .medium
        }
    }
    
    var capabilityLevel: CapabilityLevel {
        switch capabilities.lowercased() {
        case "excellent": return .excellent
        case "very good": return .veryGood
        case "good": return .good
        case "basic": return .basic
        default: return .good
        }
    }
}

enum ModelCategory: String, CaseIterable, Codable {
    case textGeneration = "Text Generation"
    case vision = "Vision"
    case embeddings = "Embeddings"
    case imageGeneration = "Image Generation"
    case translation = "Translation"
    case speechToText = "Speech-to-Text"
    case all = "All"
    
    var icon: String {
        switch self {
        case .textGeneration: return "text.bubble"
        case .vision: return "eye"
        case .embeddings: return "square.stack.3d.up"
        case .imageGeneration: return "paintbrush"
        case .translation: return "globe"
        case .speechToText: return "waveform"
        case .all: return "grid"
        }
    }
}

enum SpeedLevel: Int, CaseIterable {
    case veryFast = 4
    case fast = 3
    case medium = 2
    case slow = 1
    
    var color: Color {
        switch self {
        case .veryFast: return .green
        case .fast: return .blue
        case .medium: return .orange
        case .slow: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .veryFast: return "Very Fast"
        case .fast: return "Fast"
        case .medium: return "Medium"
        case .slow: return "Slow"
        }
    }
}

enum CapabilityLevel: Int, CaseIterable {
    case excellent = 4
    case veryGood = 3
    case good = 2
    case basic = 1
    
    var color: Color {
        switch self {
        case .excellent: return .purple
        case .veryGood: return .blue
        case .good: return .green
        case .basic: return .orange
        }
    }
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .veryGood: return "Very Good"
        case .good: return "Good"
        case .basic: return "Basic"
        }
    }
}

// MARK: - AI Model Manager

class AIModelManager: ObservableObject {
    @Published var selectedModelId: String = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    @Published var searchText: String = ""
    @Published var selectedCategory: ModelCategory = .all
    @Published var sortBy: SortOption = .provider
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption: String, CaseIterable {
        case provider = "Provider"
        case cost = "Cost"
        case speed = "Speed"
        case capabilities = "Capabilities"
        case name = "Name"
        
        var icon: String {
            switch self {
            case .provider: return "building.2"
            case .cost: return "dollarsign.circle"
            case .speed: return "speedometer"
            case .capabilities: return "star"
            case .name: return "textformat.abc"
            }
        }
    }
    
    // All available AI models with enhanced categorization
    private let allModels: [String: [ModelOption]] = [
        "OpenAI": [
            ModelOption(
                id: "gpt-4o", name: "GPT-4o", iconName: "sparkle.magnifyingglass",
                iconColor: .green, cost: 0.01, provider: "OpenAI", capabilities: "Excellent",
                speed: "Fast", description: "Most capable GPT-4 model with vision capabilities",
                isRecommended: true, category: .textGeneration),
            ModelOption(
                id: "gpt-4o-mini", name: "GPT-4o Mini", iconName: "sparkle", iconColor: .green,
                cost: 0.001, provider: "OpenAI", capabilities: "Good", speed: "Very Fast",
                description: "Smaller, faster version of GPT-4o", category: .textGeneration),
        ],
        "Anthropic": [
            ModelOption(
                id: "claude-3-opus", name: "Claude 3 Opus", iconName: "wand.and.stars",
                iconColor: .purple, cost: 0.015, provider: "Anthropic", capabilities: "Excellent",
                speed: "Medium", description: "Most powerful Claude model for complex reasoning",
                isRecommended: true, category: .textGeneration),
            ModelOption(
                id: "claude-3-sonnet", name: "Claude 3 Sonnet", iconName: "wand.and.stars.inverse",
                iconColor: .blue, cost: 0.003, provider: "Anthropic", capabilities: "Very Good",
                speed: "Fast", description: "Balanced performance and speed", category: .textGeneration),
            ModelOption(
                id: "claude-3-haiku", name: "Claude 3 Haiku", iconName: "wand.and.rays",
                iconColor: .teal, cost: 0.00025, provider: "Anthropic", capabilities: "Good",
                speed: "Very Fast", description: "Fastest Claude model for quick tasks", category: .textGeneration),
        ],
        "Google": [
            ModelOption(
                id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", iconName: "g.circle",
                iconColor: .orange, cost: 0.0005, provider: "Google", capabilities: "Good",
                speed: "Fast", description: "Latest Gemini model with improved performance", category: .textGeneration),
            ModelOption(
                id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", iconName: "g.circle",
                iconColor: .orange, cost: 0.0005, provider: "Google", capabilities: "Good",
                speed: "Fast", description: "Professional-grade Gemini model", category: .textGeneration),
            ModelOption(
                id: "gemini-2.5-flash", name: "Gemini 2.5 Flash", iconName: "g.circle",
                iconColor: .orange, cost: 0.0005, provider: "Google", capabilities: "Good",
                speed: "Fast", description: "Enhanced Flash model", category: .textGeneration),
        ],
        "Cloudflare Workers AI": [
            // Text Generation Models
            ModelOption(
                id: "@cf/meta/llama-3-8b-instruct", name: "Llama 3 8B Instruct", iconName: "cloud",
                iconColor: .orange, cost: 0.0005, provider: "Cloudflare", capabilities: "Good",
                speed: "Fast", description: "Meta's Llama 3 8B parameter model", category: .textGeneration),
            ModelOption(
                id: "@cf/meta/llama-3-70b-instruct", name: "Llama 3 70B Instruct",
                iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare",
                capabilities: "Very Good", speed: "Medium", description: "Large Llama 3 model for complex tasks", category: .textGeneration),
            ModelOption(
                id: "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b",
                name: "DeepSeek R1 Distill Qwen 32B", iconName: "cloud.bolt", iconColor: .orange,
                cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium",
                description: "Advanced reasoning model from DeepSeek", category: .textGeneration),
            
            // Vision Models
            ModelOption(
                id: "@cf/openai/clip-vit-b-32", name: "CLIP ViT-B/32", iconName: "eye",
                iconColor: .purple, cost: 0.0001, provider: "Cloudflare", capabilities: "Vision",
                speed: "Fast", description: "OpenAI's CLIP vision model", category: .vision),
            ModelOption(
                id: "@cf/openai/clip-vit-l-14", name: "CLIP ViT-L/14", iconName: "eye.fill",
                iconColor: .purple, cost: 0.0002, provider: "Cloudflare", capabilities: "Vision",
                speed: "Medium", description: "Larger CLIP vision model", category: .vision),
            
            // Embedding Models
            ModelOption(
                id: "@cf/baai/bge-base-en-v1.5", name: "BGE Base English",
                iconName: "square.stack.3d.up", iconColor: .teal, cost: 0.0001,
                provider: "Cloudflare", capabilities: "Embeddings", speed: "Very Fast",
                description: "Base English embedding model", category: .embeddings),
            ModelOption(
                id: "@cf/baai/bge-large-en-v1.5", name: "BGE Large English",
                iconName: "square.stack.3d.up.fill", iconColor: .teal, cost: 0.0002,
                provider: "Cloudflare", capabilities: "Embeddings", speed: "Fast",
                description: "Large English embedding model", category: .embeddings),
            
            // Image Generation Models
            ModelOption(
                id: "@cf/stabilityai/stable-diffusion-xl-base-1.0", name: "Stable Diffusion XL",
                iconName: "paintbrush", iconColor: .pink, cost: 0.002, provider: "Cloudflare",
                capabilities: "Image Generation", speed: "Slow", description: "High-quality image generation",
                category: .imageGeneration),
            ModelOption(
                id: "@cf/lykon/dreamshaper-8-lcm", name: "Dreamshaper 8 LCM", iconName: "sparkles",
                iconColor: .pink, cost: 0.001, provider: "Cloudflare",
                capabilities: "Image Generation", speed: "Medium", description: "Fast image generation with LCM",
                category: .imageGeneration),
            
            // Translation Models
            ModelOption(
                id: "@cf/meta/m2m100-1.2b", name: "M2M100 1.2B", iconName: "globe",
                iconColor: .green, cost: 0.0002, provider: "Cloudflare",
                capabilities: "Translation", speed: "Fast", description: "Multilingual translation model",
                category: .translation),
            
            // Speech Models
            ModelOption(
                id: "@cf/openai/whisper", name: "Whisper", iconName: "waveform", iconColor: .blue,
                cost: 0.0005, provider: "Cloudflare", capabilities: "Speech-to-Text",
                speed: "Medium", description: "OpenAI's speech recognition model", category: .speechToText),
        ],
    ]
    
    init() {
        // Load saved model selection
        loadSelectedModel()
    }
    
    // MARK: - Computed Properties
    
    var groupedModels: [String: [ModelOption]] {
        let filteredModels = filteredAndSortedModels
        
        switch sortBy {
        case .provider:
            return Dictionary(grouping: filteredModels) { $0.provider }
        case .cost:
            return ["Models": filteredModels]
        case .speed:
            return Dictionary(grouping: filteredModels) { $0.speed }
        case .capabilities:
            return Dictionary(grouping: filteredModels) { $0.capabilities }
        case .name:
            return ["Models": filteredModels]
        }
    }
    
    var filteredAndSortedModels: [ModelOption] {
        let flatModels = allModels.values.flatMap { $0 }
        
        // Filter by search text
        let searchFiltered = searchText.isEmpty ? flatModels : flatModels.filter { model in
            model.name.localizedCaseInsensitiveContains(searchText) ||
            model.provider.localizedCaseInsensitiveContains(searchText) ||
            model.capabilities.localizedCaseInsensitiveContains(searchText)
        }
        
        // Filter by category
        let categoryFiltered = selectedCategory == .all ? searchFiltered : searchFiltered.filter { model in
            model.category == selectedCategory
        }
        
        // Sort by selected option
        return categoryFiltered.sorted { first, second in
            switch sortBy {
            case .provider:
                return first.provider < second.provider
            case .cost:
                return first.cost < second.cost
            case .speed:
                return first.speedLevel.rawValue > second.speedLevel.rawValue
            case .capabilities:
                return first.capabilityLevel.rawValue > second.capabilityLevel.rawValue
            case .name:
                return first.name < second.name
            }
        }
    }
    
    var selectedModel: ModelOption? {
        allModels.values.flatMap { $0 }.first { $0.id == selectedModelId }
    }
    
    var recommendedModels: [ModelOption] {
        allModels.values.flatMap { $0 }.filter { $0.isRecommended }
    }
    
    // MARK: - Methods
    
    func selectModel(_ model: ModelOption) {
        selectedModelId = model.id
        saveSelectedModel()
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func resetFilters() {
        searchText = ""
        selectedCategory = .all
        sortBy = .provider
    }
    
    private func saveSelectedModel() {
        UserDefaults.standard.set(selectedModelId, forKey: "selectedAIModel")
    }
    
    private func loadSelectedModel() {
        if let savedModel = UserDefaults.standard.string(forKey: "selectedAIModel") {
            selectedModelId = savedModel
        }
    }
    
    // Get models by provider
    func getModelsByProvider(_ provider: String) -> [ModelOption] {
        return allModels[provider] ?? []
    }
    
    // Get all providers
    var allProviders: [String] {
        return Array(allModels.keys).sorted()
    }
    
    // Get model count for category
    func getModelCount(for category: ModelCategory) -> Int {
        if category == .all {
            return allModels.values.flatMap { $0 }.count
        }
        return allModels.values.flatMap { $0 }.filter { $0.category == category }.count
    }
}

// MARK: - Color Extensions

