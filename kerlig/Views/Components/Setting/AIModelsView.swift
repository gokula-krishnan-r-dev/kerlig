import SwiftUI

struct AIModelsView: View {
    @StateObject private var modelManager = AIModelManager()
    @EnvironmentObject var appState: AppState
    
    @State private var selectedLayout: LayoutOption = .card
    @State private var showingFilters: Bool = false
    
    enum LayoutOption: String, CaseIterable {
        case card = "Card"
        case compact = "Compact"
        case list = "List"
        
        var icon: String {
            switch self {
            case .card: return "rectangle.grid.1x2"
            case .compact: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search and Controls
            headerSection
            
            Divider()
            
            // Filters Section (if shown)
            if showingFilters {
                filtersSection
                Divider()
            }
            
            // Models Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Recommended Models Section
                    if !modelManager.recommendedModels.isEmpty && modelManager.selectedCategory == .all && modelManager.searchText.isEmpty {
                        recommendedSection
                    }
                    
                    // Main Models Content
                    modelsContent
                }
                .padding()
            }
        }
        .onAppear {
            // Sync selected model with app state
            if appState.aiModel != modelManager.selectedModelId {
                modelManager.selectedModelId = appState.aiModel
            }
        }
        .onChange(of: modelManager.selectedModelId) { newValue in
            // Update app state when model selection changes
            appState.aiModel = newValue
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Models")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Layout Toggle
                layoutToggle
                
                // Filter Toggle
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18))
                        .foregroundColor(showingFilters ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Toggle Filters")
            }
            
            // Search Bar
            searchBar
            
            // Stats Row
            statsRow
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            TextField("Search models, providers, or capabilities...", text: $modelManager.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
            
            if !modelManager.searchText.isEmpty {
                Button(action: modelManager.clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
    
    private var layoutToggle: some View {
        HStack(spacing: 4) {
            ForEach(LayoutOption.allCases, id: \.self) { layout in
                Button(action: { selectedLayout = layout }) {
                    Image(systemName: layout.icon)
                        .font(.system(size: 14))
                        .foregroundColor(selectedLayout == layout ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .help(layout.rawValue + " Layout")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
    }
    
    private var statsRow: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "cube.box")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("\(modelManager.filteredAndSortedModels.count) models")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            if let selectedModel = modelManager.selectedModel {
                Spacer()
                HStack(spacing: 4) {
                    Text("Selected:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(selectedModel.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Category Filter
            HStack {
                Text("Category:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ModelCategory.allCases, id: \.self) { category in
                            CategoryFilterChip(
                                category: category,
                                isSelected: modelManager.selectedCategory == category,
                                count: modelManager.getModelCount(for: category)
                            ) {
                                modelManager.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Sort Options
            HStack {
                Text("Sort by:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("Sort", selection: $modelManager.sortBy) {
                    ForEach(AIModelManager.SortOption.allCases, id: \.self) { option in
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.rawValue)
                        }
                        .tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 120)
                
                Spacer()
                
                Button("Reset Filters") {
                    modelManager.resetFilters()
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 12))
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // MARK: - Recommended Section
    
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                Text("Recommended Models")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(modelManager.recommendedModels) { model in
                    modelCardView(for: model)
                }
            }
        }
    }
    
    // MARK: - Models Content
    
    private var modelsContent: some View {
        LazyVStack(spacing: 20) {
            ForEach(sortedGroupKeys, id: \.self) { groupKey in
                if let models = modelManager.groupedModels[groupKey], !models.isEmpty {
                    ModelSection(
                        title: groupKey,
                        models: models,
                        selectedModelId: modelManager.selectedModelId,
                        layout: selectedLayout
                    ) { model in
                        modelManager.selectModel(model)
                    }
                }
            }
        }
    }
    
    private var sortedGroupKeys: [String] {
        modelManager.groupedModels.keys.sorted { first, second in
            if modelManager.sortBy == .provider {
                return first < second
            }
            return first < second
        }
    }
    
    private var gridColumns: [GridItem] {
        switch selectedLayout {
        case .card:
            return [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 12)]
        case .compact:
            return [GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 8)]
        case .list:
            return [GridItem(.flexible(), spacing: 4)]
        }
    }
    
    private func modelCardView(for model: ModelOption) -> some View {
        Group {
            switch selectedLayout {
            case .card:
                AIModelCard(
                    model: model,
                    isSelected: model.id == modelManager.selectedModelId,
                    onSelect: { modelManager.selectModel(model) }
                )
            case .compact:
                CompactAIModelCard(
                    model: model,
                    isSelected: model.id == modelManager.selectedModelId,
                    onSelect: { modelManager.selectModel(model) }
                )
            case .list:
                CompactAIModelCard(
                    model: model,
                    isSelected: model.id == modelManager.selectedModelId,
                    onSelect: { modelManager.selectModel(model) }
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct ModelSection: View {
    let title: String
    let models: [ModelOption]
    let selectedModelId: String
    let layout: AIModelsView.LayoutOption
    let onSelect: (ModelOption) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("(\(models.count))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Models Grid
            LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                ForEach(models) { model in
                    modelCardView(for: model)
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        switch layout {
        case .card:
            return [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 12)]
        case .compact:
            return [GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 8)]
        case .list:
            return [GridItem(.flexible(), spacing: 4)]
        }
    }
    
    private var gridSpacing: CGFloat {
        switch layout {
        case .card: return 12
        case .compact: return 8
        case .list: return 4
        }
    }
    
    private func modelCardView(for model: ModelOption) -> some View {
        Group {
            switch layout {
            case .card:
                AIModelCard(
                    model: model,
                    isSelected: model.id == selectedModelId,
                    onSelect: { onSelect(model) }
                )
            case .compact:
                CompactAIModelCard(
                    model: model,
                    isSelected: model.id == selectedModelId,
                    onSelect: { onSelect(model) }
                )
            case .list:
                CompactAIModelCard(
                    model: model,
                    isSelected: model.id == selectedModelId,
                    onSelect: { onSelect(model) }
                )
            }
        }
    }
}

struct CategoryFilterChip: View {
    let category: ModelCategory
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                
                Text("(\(count))")
                    .font(.system(size: 11))
                    .opacity(0.7)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AIModelsView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}