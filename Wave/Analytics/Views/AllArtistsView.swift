//
//  AllArtistsView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import SwiftUI

struct AllArtistsView: View {
    let artists: [Artist]
    let period: String
    
    var body: some View {
        List {
            ForEach(Array(artists.enumerated()), id: \.element.id) { index, artist in
                HStack(spacing: 12) {
                    // Rank
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 35)
                    
                    // Artist image placeholder
                    Circle()
                        .fill(LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.title3)
                        )
                    
                    // Artist info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(artist.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        if !artist.topSongs.isEmpty {
                            Text(artist.topSongs.prefix(2).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Stats
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(artist.playCount)")
                            .font(.headline)
                            .foregroundColor(.pink)
                        
                        Text("plays")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if artist.totalMinutes > 0 {
                            Text(formatMinutes(artist.totalMinutes))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("All Artists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("All Artists")
                        .font(.headline)
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    NavigationView {
        AllArtistsView(
            artists: MockDataService.shared.topArtists,
            period: "This Month"
        )
    }
}
