//
//  ContentView.swift
//  Streamline
//
//  Created by gokul on 17/04/25.
//

import SwiftUI
import Foundation

struct NoteUIView: View {
    @StateObject private var noteStore = NoteStore()
    
    var body: some View {
       Text("Demo")
    }
}

#Preview {
    NoteUIView()
}




