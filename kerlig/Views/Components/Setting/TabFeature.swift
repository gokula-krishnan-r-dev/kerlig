import SwiftUI

struct TabFeature: View {
    @State private var selection: Int = 0
    
    // Tab model with title, icon and optional beta flag
    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let isBeta: Bool
        let content: AnyView
        let isDefaultSelected: Bool
        
        init(title: String, icon: String, isBeta: Bool = false, content: AnyView, isDefaultSelected: Bool = false) {
            self.title = title
            self.icon = icon
            self.isBeta = isBeta
            self.content = content
            self.isDefaultSelected = isDefaultSelected
        }
    }
    
    // List of tabs with their properties
    let tabs = [
        TabItem(title: "Hotkey", icon: "tray.and.arrow.down.fill", content: AnyView(Text("Hotkey")) , isDefaultSelected: false),
        TabItem(title: "Actions", icon: "tray.and.arrow.up.fill", content: AnyView(    CustomActionsManager()) , isDefaultSelected: true),
        TabItem(title: "AI Model", icon: "chart.bar.fill", isBeta: true, content: AnyView(Text("AI Model")) , isDefaultSelected: false),
        TabItem(title: "Profile", icon: "person.crop.circle.fill", content: AnyView(Text("profile")) , isDefaultSelected: false),
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $selection) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    tab.content
                        .tabItem {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .tag(index)
                        .onAppear {
                            if tab.isDefaultSelected {
                                selection = index
                            }
                        }
                }
            }
        }
    }
}

// Separate component for tab content
struct TabContentView: View {
    let title: String
    let isBeta: Bool
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}