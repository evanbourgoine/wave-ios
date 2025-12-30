//
//  ContentView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        if firebaseService.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

#Preview {
    ContentView()
}
