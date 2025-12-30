//
//  MainTabView.swift
//  Wave
//
//  Tab bar navigation for the Wave app
//

import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var musicService = MusicKitService.shared
    @State private var selectedTab = 2 // Start on Analytics tab
    @State private var keyboardHeight: CGFloat = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Group {
            if musicService.isAuthorized {
                tabView
            } else {
                MusicAuthorizationView()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            print("📱 MainTabView appeared")
            musicService.checkAuthorization()
            
            // Test MusicKit API connection after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task {
                    print("🔍 About to test MusicKit connection...")
                    await musicService.testMusicKitConnection()
                }
            }
        }
        .onReceive(Publishers.keyboardHeight) { height in
            keyboardHeight = height
        }
    }
    
    private var tabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Home/Feed Tab
                FeedView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // Search/Discovery Tab
                SearchDiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                // Analytics Tab
                AnalyticsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                // AI Chat Tab
                AIChatView()
                    .tabItem {
                        Label("AI", systemImage: "sparkles")
                    }
                    .tag(3)
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
            
            // Mini player - only show when keyboard is NOT visible
            if musicService.currentSong != nil && keyboardHeight == 0 {
                VStack {
                    Spacer()
                    MiniPlayerView()
                        .padding(.bottom, 49) // Tab bar height
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.25), value: keyboardHeight == 0)
            }
        }
    }
}

// Placeholder views for other tabs
struct FeedView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Home Feed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wave")
        }
    }
}

struct AIChatView: View {
    var body: some View {
        NavigationView {
            Text("AI Chat - Coming Soon")
                .navigationTitle("AI Assistant")
        }
    }
}

#Preview {
    MainTabView()
}
