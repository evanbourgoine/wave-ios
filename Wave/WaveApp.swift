//
//  WaveApp.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

//
//  WaveApp.swift
//  Wave
//
//  Created on December 23, 2024
//

import SwiftUI
import FirebaseCore

@main
struct WaveApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            // Check if user is authenticated
            if firebaseService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}
