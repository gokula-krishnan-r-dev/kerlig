import SwiftUI

struct TabFeature: View {
    @State private var selection: Int = 0
    @EnvironmentObject var appState: AppState
    
    // Tab model with title, icon and optional beta flag
    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let isBeta: Bool
        let content: AnyView
        let isDefaultSelected: Bool
        let badge: String?
        
        init(title: String, icon: String, isBeta: Bool = false, content: AnyView, isDefaultSelected: Bool = false, badge: String? = nil) {
            self.title = title
            self.icon = icon
            self.isBeta = isBeta
            self.content = content
            self.isDefaultSelected = isDefaultSelected
            self.badge = badge
        }
    }
    
    // List of tabs with their properties
    let tabs = [
        TabItem(
            title: "Hotkeys", 
            icon: "keyboard", 
            content: AnyView(HotkeysView()), 
            isDefaultSelected: false
        ),
        TabItem(
            title: "Actions", 
            icon: "bolt.circle", 
            content: AnyView(CustomActionsManager()), 
            isDefaultSelected: true
        ),
        TabItem(
            title: "AI Models", 
            icon: "brain.head.profile", 
            content: AnyView(AIModelsView()), 
            isDefaultSelected: false,
            badge: "New"
        ),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    tab.content
                        .tabItem {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .tag(index)
                }
            }
            .onAppear {
                // Set default selection
                if let defaultIndex = tabs.firstIndex(where: { $0.isDefaultSelected }) {
                    selection = defaultIndex
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TabFeature()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}