/*
 * CustomActionsManager.swift
 * 
 * A comprehensive split-screen interface for managing custom AI actions with:
 * - Left navigation panel with categorized action lists
 * - Right content panel showing action details or grid view
 * - Full CRUD operations (Create, Read, Update, Delete)
 * - localStorage synchronization via UserDefaults
 * - Modern, responsive UI with animations and hover effects
 * - Lazy loading for optimal performance
 * - Search and filtering capabilities
 * - System prompt management for each action
 * - Keyboard shortcuts for quick access
 */

import SwiftUI
import Foundation


// MARK: - Main View
struct CustomActionsManager: View {
    @StateObject private var storage = CustomActionsStorage()
    @State private var selectedNavigation: NavigationItem = .allActions
    @State private var selectedAction: CustomAction?
    @State private var showingCreateAction = false
    @State private var searchText = ""
    @State private var isEditing = false
    
    // Animation and UI state
    @State private var animateContent = false
    
    var body: some View {
        HSplitView {
            // Left Navigation Panel
            navigationPanel
                .frame(minWidth: 280, maxWidth: 350)
                .background(Color(NSColor.controlBackgroundColor))
            
            // Right Content Panel
            contentPanel
                .frame(minWidth: 400)
                .background(Color(NSColor.textBackgroundColor))
        }
        .navigationTitle("Custom Actions")
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
                selectedAction = storage.actions.first
            }
        }
        .sheet(isPresented: $showingCreateAction) {
            ActionEditorView(storage: storage, action: nil) { newAction in
                storage.addAction(newAction)
                selectedAction = newAction
            }
        }
    }
    
    // MARK: - Navigation Panel
    private var navigationPanel: some View {
        VStack(spacing: 0) {
            navigationHeader
            searchBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            navigationList
            Spacer()
            navigationFooter
        }
        .padding(8)
    }
    
    private var navigationHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("Actions")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingCreateAction = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.purple))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 16)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search actions...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var navigationList: some View {
        ScrollView {
             ActionListView(
                        actions: storage.actions,
                    storage: storage,
                    searchText: searchText,
                    selectedNavigation: selectedNavigation,
                    onSelectAction: { action in
                        selectedAction = action
                    }
                )
        }
    }
    
    private var navigationFooter: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 16)
            
            HStack {
                Text("\(storage.actions.count) total actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(storage.actions.filter { $0.isEnabled }.count) enabled")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Content Panel
    private var contentPanel: some View {
        Group {
            if let selectedAction = selectedAction {
                ActionDetailView(
                    action: selectedAction,
                    storage: storage,
                    onEdit: { action in
                        isEditing = true
                    },
                    onDelete: { action in
                        storage.deleteAction(action)
                        self.selectedAction = nil
                    }
                )
            } else {
                ActionListView(
                    actions: filteredActions,
                    storage: storage,
                    searchText: searchText,
                    selectedNavigation: selectedNavigation,
                    onSelectAction: { action in
                        selectedAction = action
                    }
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: animateContent)
        .sheet(isPresented: $isEditing) {
            if let action = selectedAction {
                ActionEditorView(storage: storage, action: action) { updatedAction in
                    storage.updateAction(updatedAction)
                    selectedAction = updatedAction
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var filteredActions: [CustomAction] {
        var actions = storage.actions
        
        switch selectedNavigation {
        case .allActions:
            break
        case .enabledActions:
            actions = actions.filter { $0.isEnabled }
        case .recentlyUsed:
            actions = actions.sorted { $0.updatedAt > $1.updatedAt }.prefix(10).map { $0 }
        case .createNew:
            return []
        }
        
        if !searchText.isEmpty {
            actions = actions.filter { action in
                action.name.localizedCaseInsensitiveContains(searchText) ||
                action.description.localizedCaseInsensitiveContains(searchText) ||
                action.systemPrompt.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return actions
    }
    
    private func getActionCount(for item: NavigationItem) -> Int {
        switch item {
        case .allActions:
            return storage.actions.count
        case .enabledActions:
            return storage.actions.filter { $0.isEnabled }.count
        case .recentlyUsed:
            return min(10, storage.actions.count)
        case .createNew:
            return 0
        }
    }
}


#Preview {
    CustomActionsManager()
        .frame(width: 1200, height: 800)
} 
