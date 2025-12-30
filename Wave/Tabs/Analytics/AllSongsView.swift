//
//  AllSongsView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import SwiftUI

struct AllSongsView: View {
    let songs: [Song]
    let period: String
    
    var body: some View {
        List {
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                HStack(spacing: 12) {
                    // Rank
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 35)
                    
                    // Artwork
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.title3)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.title3)
                            )
                    }
                    
                    // Song info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(song.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Text(song.album)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Stats
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(song.playCount)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("plays")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if song.totalMinutes > 0 {
                            Text("\(song.totalMinutes)m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("All Songs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("All Songs")
                        .font(.headline)
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AllSongsView(
            songs: MockDataService.shared.topSongs,
            period: "This Month"
        )
    }
}
