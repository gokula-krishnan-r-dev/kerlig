import SwiftUI
import Foundation



// MARK: - Storage Manager
class CustomActionsStorage: ObservableObject {
    @Published var actions: [CustomAction] = []
    private let storageKey = "customActions_new_v2"
  @Published var selectedActionId: String? = UserDefaults.standard.string(forKey: "selectedActionId")

    //selected action
    @Published var selectedAction: CustomAction? = CustomAction(
        id: UUID(),
        name: "Ask",
        description: "Ask a question",
        systemPrompt: "Ask a question",
        icon: "questionmark.circle",
        shortcutKey: "A"
    )
    
    init() {

        // Initialize selected action from saved preference or use default
        loadSelectedAction()

        loadActions()
        
        // Listen for external changes to UserDefaults
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func userDefaultsDidChange(_ notification: Notification) {
        // Reload actions when UserDefaults changes
        DispatchQueue.main.async { [weak self] in
            self?.loadActions()
        }
    }
    
    // Update actions from localStorage and notify observers
    func updateActions() {
        loadActions()
        
        // Post notification for real-time updates across the app
        NotificationCenter.default.post(name: Notification.Name("CustomActionsDidUpdate"), object: nil)
    }


    func loadSelectedAction() {
        if let id = UserDefaults.standard.string(forKey: "selectedActionId") {
            // First ensure actions are loaded before trying to find the selected one
            if actions.isEmpty {
                loadActions()
            }

            print("loadSelectedAction: \(id)")

            print("loadSelectedAction: \(actions)")

            // Find the action with matching ID
            selectedAction = actions.first(where: { $0.id.uuidString == id })
            
            // If the saved ID doesn't match any action, fall back to the first action
            if selectedAction == nil && !actions.isEmpty {
                selectedAction = actions.first
            }
        } else if !actions.isEmpty {
            // No saved selection, default to first action
            selectedAction = actions.first
        }
    }
    
    func loadActions() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomAction].self, from: data) {
            // Sort actions by enabled status (enabled first) and then by name
            actions = decoded.sorted { 
                if $0.isEnabled != $1.isEnabled {
                    return $0.isEnabled && !$1.isEnabled
                }
                return $0.name < $1.name
            }
        } else {
            // Load default actions if none exist
            actions = createDefaultActions()
            saveActions()
        }
    }
    
    func saveActions() {
        if let encoded = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            
            // Post notification for real-time updates
            NotificationCenter.default.post(name: Notification.Name("CustomActionsDidUpdate"), object: nil)
        }
    }
    
    func addAction(_ action: CustomAction) {
        actions.append(action)
        saveActions()
    }
    
    func updateAction(_ action: CustomAction) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
            saveActions()
        }
    }
    
    func deleteAction(_ action: CustomAction) {
        actions.removeAll { $0.id == action.id }
        saveActions()
    }
    
    func toggleAction(_ action: CustomAction) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index].isEnabled.toggle()
            actions[index].updatedAt = Date()
            saveActions()
        }
    }
    
    // Get only enabled actions
    func enabledActions() -> [CustomAction] {
        return actions.filter { $0.isEnabled }
    }
    
    private func createDefaultActions() -> [CustomAction] {
        return [

            //add ask
            CustomAction(
                id: UUID(),
                name: "Ask",
                description: "Ask a question",
                systemPrompt: "Ask a question",
                icon: "questionmark.circle",
                shortcutKey: "A"
            ),
            //enhance sentence
            CustomAction(
                id: UUID(),
                name: "Enhance Sentence",
                description: "Enhance a sentence",
                systemPrompt: "Enhance a sentence",
                icon: "arrow.up.right.and.arrow.down.left.circle",
                shortcutKey: "E"
            ),

            //add translate
            CustomAction(
                id: UUID(),
                name: "Translate",
                description: "Translate a sentence",
                systemPrompt: "Translate a sentence",
                icon: "globe",
                shortcutKey: "T"
            ),

            //improve grammar
            CustomAction(
                id: UUID(),
                name: "Improve Grammar",
                description: "Improve the grammar of a sentence",
                systemPrompt: "Improve the grammar of a sentence",
                icon: "checkmark.seal",
                shortcutKey: "G"
            ),

            //add summarize
            CustomAction(
                id: UUID(),
                name: "Summarize",
                description: "Summarize a text",
                systemPrompt: "Summarize a text",
                icon: "text.book.closed",
                shortcutKey: "S"
            ),

            //add explain
            CustomAction(
                id: UUID(),
                name: "Explain",
                description: "Explain a text",
                systemPrompt: "Explain a text",
                icon: "text.book.closed",
                shortcutKey: "X"
            ),

            //add rewrite
            CustomAction(
                id: UUID(),
                name: "Rewrite",
                description: "Rewrite a text",
                systemPrompt: "Rewrite a text",
                icon: "arrow.up.left.and.arrow.down.right.circle",
                shortcutKey: "R"
            ),

            //add proofread
            CustomAction(
                id: UUID(),
                name: "Proofread",
                description: "Proofread a text",
                systemPrompt: "Proofread a text",
                icon: "checkmark.seal",
                shortcutKey: "P"
            ),
        ]
    }
}
