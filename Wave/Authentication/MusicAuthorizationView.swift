//
//  MusicAuthorizationView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import SwiftUI
import MusicKit

struct MusicAuthorizationView: View {
    @StateObject private var musicService = MusicKitService.shared
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "music.note")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)
            
            // Title
            Text("Connect Apple Music")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            
            // Description
            Text("Wave needs access to your Apple Music library to show your listening stats and create personalized playlists.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Features List
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Your Stats",
                    description: "See your top songs, artists, and listening habits"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    title: "AI Playlists",
                    description: "Get personalized playlist recommendations"
                )
                
                FeatureRow(
                    icon: "person.2.fill",
                    title: "Share with Friends",
                    description: "Connect and share music with your friends"
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Spacer()
            
            // Authorization Button
            Button(action: {
                requestAuthorization()
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isRequesting)
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
            
            // Privacy Note
            Text("We only read your listening history. We never modify your library or playlists without permission.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
    
    private func requestAuthorization() {
        isRequesting = true
        
        Task {
            await musicService.requestAuthorization()
            isRequesting = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    MusicAuthorizationView()
}
