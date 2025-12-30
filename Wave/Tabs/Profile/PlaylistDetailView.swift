//
//  PlaylistDetailView.swift
//  Wave
//
//  Shows playlist details with songs and playback controls
//

import SwiftUI
import MusicKit

struct PlaylistDetailView: View {
    let playlistId: String
    let playlistName: String
    let playlistArtwork: String?
    let trackCount: Int
    
    @StateObject private var musicService = MusicKitService.shared
    @State private var songItems: [PlaylistSongItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var dominantColor: Color = .blue
    
    // Helper struct to hold both Song and MusicKit Track
    struct PlaylistSongItem: Identifiable {
        let id = UUID()
        let song: Song
        let track: MusicKit.Track
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Playlist Header with Artwork
                playlistHeader
                
                // Play & Shuffle Buttons
                playbackControls
                
                // Songs List
                if isLoading {
                    ProgressView("Loading songs...")
                        .padding(.top, 40)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Error Loading Songs")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            loadPlaylistSongs()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 60)
                } else if songItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No songs in this playlist")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    songsList
                }
                
                // Bottom padding for mini player
                Color.clear
                    .frame(height: musicService.currentSong != nil ? 80 : 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPlaylistSongs()
            extractDominantColor()
        }
    }
    
    // MARK: - Playlist Header
    
    private var playlistHeader: some View {
        VStack(spacing: 16) {
            // Artwork
            if let artworkURL = playlistArtwork, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .cornerRadius(12)
                            .shadow(color: dominantColor.opacity(0.3), radius: 20, x: 0, y: 10)
                    default:
                        placeholderArtwork
                    }
                }
            } else {
                placeholderArtwork
            }
            
            // Playlist Info
            VStack(spacing: 8) {
                Text(playlistName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !songItems.isEmpty {
                    Text("\(songItems.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [dominantColor.opacity(0.3), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [dominantColor, dominantColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 200)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            )
            .shadow(color: dominantColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: 12) {
            // Play Button
            Button(action: {
                playPlaylist()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [dominantColor, dominantColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(songItems.isEmpty)
            
            // Shuffle Button
            Button(action: {
                shufflePlaylist()
            }) {
                HStack {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .disabled(songItems.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Songs List
    
    private var songsList: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Songs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Song Rows
            VStack(spacing: 8) {
                ForEach(Array(songItems.enumerated()), id: \.element.id) { index, item in
                    PlaylistSongRow(
                        song: item.song,
                        number: index + 1,
                        isPlaying: musicService.currentSong?.id == item.song.id && musicService.isPlaying
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🎵 Tapped song #\(index + 1): \(item.song.title)")
                        
                        // Use exact same pattern as search (which works)
                        Task {
                            print("   Task started for: \(item.song.title)")
                            await musicService.playSong(item.song)
                            print("   Playback completed")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions
    
    private func loadPlaylistSongs() {
        isLoading = true
        errorMessage = nil
        
        print("🎵 PlaylistDetailView: Starting to load playlist \(playlistId)")
        print("   Track count from list: \(trackCount)")
        
        Task {
            print("   📡 Loading all playlists to find tracks...")
            
            do {
                // Fetch all playlists (already loaded with tracks)
                let allPlaylists = try await musicService.fetchUserPlaylists()
                
                print("   📋 Got \(allPlaylists.count) playlists")
                
                // Find our specific playlist
                guard let playlist = allPlaylists.first(where: { $0.id.rawValue == playlistId }) else {
                    throw NSError(domain: "PlaylistNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist not found"])
                }
                
                print("   ✅ Found playlist: \(playlist.name)")
                
                // Get tracks
                guard let tracks = playlist.tracks else {
                    throw NSError(domain: "NoTracks", code: 404, userInfo: [NSLocalizedDescriptionKey: "No tracks in playlist"])
                }
                
                print("   📝 Converting \(tracks.count) tracks...")
                
                // Convert to PlaylistSongItems (holding both Song and Track)
                let loadedItems = tracks.map { track in
                    let song = Song(
                        title: track.title,
                        artist: track.artistName,
                        album: track.albumTitle ?? "Unknown Album",
                        artworkURL: track.artwork?.url(width: 300, height: 300)?.absoluteString,
                        playCount: 0,
                        totalMinutes: Int((track.duration ?? 0) / 60)
                    )
                    return PlaylistSongItem(song: song, track: track)
                }
                
                print("   🎯 About to update UI with \(loadedItems.count) songs...")
                
                // Use DispatchQueue to avoid MainActor deadlock
                DispatchQueue.main.async {
                    print("✅ PlaylistDetailView: Displaying \(loadedItems.count) songs")
                    self.songItems = loadedItems
                    self.isLoading = false
                }
            } catch {
                print("❌ PlaylistDetailView: Error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load songs: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func playPlaylist() {
        guard !songItems.isEmpty else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let firstItem = songItems[0]
        print("▶️ Playing playlist: \(playlistName)")
        print("   First song: \(firstItem.song.title)")
        
        // Use exact same pattern as search
        Task {
            print("   Play task started...")
            await musicService.playSong(firstItem.song)
            print("✅ Playlist playback started")
        }
    }
    
    private func shufflePlaylist() {
        guard !songItems.isEmpty else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let shuffledItems = songItems.shuffled()
        let firstItem = shuffledItems[0]
        print("🔀 Shuffling playlist: \(playlistName)")
        print("   First shuffled song: \(firstItem.song.title)")
        
        // Use exact same pattern as search
        Task {
            print("   Shuffle task started...")
            await musicService.playSong(firstItem.song)
            print("✅ Shuffled playlist playback started")
        }
    }
    
    private func extractDominantColor() {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo, .red]
        dominantColor = colors.randomElement() ?? .blue
    }
}

// MARK: - Playlist Song Row

struct PlaylistSongRow: View {
    let song: Song
    let number: Int
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Track Number or Playing Indicator
            ZStack {
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("\(number)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 24)
            
            // Album Artwork
            if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                    default:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                    }
                }
            }
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(isPlaying ? .semibold : .regular)
                    .foregroundColor(isPlaying ? .green : .primary)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // More Options (placeholder)
            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isPlaying ? Color.green.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        PlaylistDetailView(
            playlistId: "123",
            playlistName: "My Awesome Playlist",
            playlistArtwork: nil,
            trackCount: 25
        )
    }
}
