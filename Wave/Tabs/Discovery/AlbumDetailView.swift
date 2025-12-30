//
//  AlbumDetailView.swift
//  Wave
//
//  Shows album details and all songs in the album
//

import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: AlbumSearchResult
    @StateObject private var musicService = MusicKitService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var albumSongs: [Song] = []
    @State private var isLoading = true
    @State private var dominantColor: Color = .blue
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Album Header
                albumHeader
                
                // Songs List
                if isLoading {
                    ProgressView("Loading songs...")
                        .padding(.top, 40)
                } else if albumSongs.isEmpty {
                    Text("No songs found")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    songsSection
                    
                    // Bottom Action Buttons (Placeholder)
                    bottomActionButtons
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAlbumSongs()
            extractDominantColor()
            loadSavedRating()
            checkIfPinned()
        }
    }
    
    // MARK: - Album Header
    
    @State private var userRating: Double = 0.0
    
    private var albumHeader: some View {
        VStack(spacing: 16) {
            // Album Artwork - Larger
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 220)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 220, height: 220)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 220, height: 220)
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 220, height: 220)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            // Album Info
            VStack(spacing: 8) {
                Text(album.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(album.artist)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !albumSongs.isEmpty {
                    Text("\(albumSongs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Star Rating
            starRatingView
            
            // Show Artist Button
            showArtistButton
        }
        .padding(.top)
    }
    
    @State private var foundArtist: ArtistSearchResult?
    
    private var showArtistButton: some View {
        Group {
            if let artist = foundArtist {
                NavigationLink(destination: ArtistProfileView(artist: artist)) {
                    Text("Show Artist")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            } else {
                Button(action: {
                    Task {
                        await searchForArtist()
                    }
                }) {
                    Text("Show Artist")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private func searchForArtist() async {
        let artists = await musicService.searchArtists(query: album.artist, limit: 1)
        if let firstArtist = artists.first {
            await MainActor.run {
                foundArtist = ArtistSearchResult(
                    name: firstArtist.name,
                    imageURL: firstArtist.artwork?.url(width: 1000, height: 1000)?.absoluteString
                )
            }
        }
    }
    
    // MARK: - Star Rating View
    
    private var starRatingView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Button(action: {
                        handleStarTap(at: index)
                    }) {
                        Image(systemName: starImage(for: index))
                            .font(.system(size: 24))
                            .foregroundColor(index < Int(userRating.rounded(.up)) ? .yellow : .gray.opacity(0.3))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if userRating > 0 {
                Text(String(format: "%.1f / 5.0", userRating))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap to rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func starImage(for index: Int) -> String {
        let position = Double(index)
        
        if userRating >= position + 1 {
            return "star.fill"
        } else if userRating > position && userRating < position + 1 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func handleStarTap(at index: Int) {
        let position = Double(index)
        
        // If tapping the same star, toggle between full and half
        if userRating > position && userRating <= position + 1 {
            // Already filled or half-filled, check which
            if userRating == position + 0.5 {
                userRating = position + 1.0 // Make it full
            } else if userRating == position + 1.0 {
                userRating = position + 0.5 // Make it half
            }
        } else {
            // First tap on this star, make it full
            userRating = position + 1.0
        }
        
        // Save rating to Firebase
        saveRating()
    }
    
    private func loadSavedRating() {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        Task {
            do {
                let ratings = try await firebaseService.getRatings(userId: userId, itemType: .album)
                // Find rating for this album
                if let savedRating = ratings.first(where: { $0.itemId == album.id.uuidString }) {
                    await MainActor.run {
                        userRating = savedRating.rating
                    }
                }
            } catch {
                print("❌ Error loading rating: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveRating() {
        guard let userId = firebaseService.currentUser?.id else { return }
        guard userRating > 0 else { return }
        
        Task {
            do {
                let rating = Rating(
                    userId: userId,
                    itemId: album.id.uuidString,
                    itemType: .album,
                    itemTitle: album.title,
                    itemSubtitle: album.artist,
                    rating: userRating,
                    ratedAt: Date()
                )
                
                try await firebaseService.saveRating(rating)
                print("✅ Saved album rating: \(userRating) stars")
            } catch {
                print("❌ Error saving rating: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Songs Section
    
    private var songsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Songs")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(albumSongs.enumerated()), id: \.element.id) { index, song in
                    AlbumSongRow(song: song, trackNumber: index + 1)
                    
                    if index < albumSongs.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Load Album Songs
    
    private func loadAlbumSongs() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Search for the album title to get more specific results
            let allSongs = await musicService.searchSongs(query: album.title, limit: 25)
            
            // Filter to only songs that match this album and artist
            albumSongs = allSongs.filter { song in
                // Match if album title contains our search term or vice versa
                let albumMatch = song.album.lowercased().contains(album.title.lowercased()) ||
                                album.title.lowercased().contains(song.album.lowercased())
                
                // Also check artist matches
                let artistMatch = song.artist.lowercased().contains(album.artist.lowercased()) ||
                                 album.artist.lowercased().contains(song.artist.lowercased())
                
                return albumMatch && artistMatch
            }
            
            // If we didn't find many songs, try searching with artist name too
            if albumSongs.count < 3 {
                let moreResults = await musicService.searchSongs(query: "\(album.artist) \(album.title)", limit: 25)
                
                let filteredMore = moreResults.filter { song in
                    let albumMatch = song.album.lowercased().contains(album.title.lowercased())
                    let artistMatch = song.artist.lowercased().contains(album.artist.lowercased())
                    return albumMatch && artistMatch
                }
                
                // Merge and deduplicate
                var songIds = Set(albumSongs.map { $0.id })
                for song in filteredMore {
                    if !songIds.contains(song.id) {
                        albumSongs.append(song)
                        songIds.insert(song.id)
                    }
                }
            }
            
            print("📀 Loaded \(albumSongs.count) songs for album '\(album.title)'")
        }
    }
    
    // MARK: - Bottom Action Buttons
    
    @State private var isPinned = false
    
    private var bottomActionButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Pin to Profile Button
                Button(action: {
                    togglePin()
                }) {
                    HStack {
                        Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        Text(isPinned ? "Unpin from Profile" : "Pin to Profile")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: isPinned ? [.gray, .gray.opacity(0.8)] : [dominantColor, dominantColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // Share with Friend Button
                Button(action: {
                    // TODO: Implement share with friend
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Share with Friend")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(dominantColor.opacity(0.3), lineWidth: 1.5)
                    )
                }
            }
            .padding(.top, 8)
            
            // Extra bottom padding for mini player
            Color.clear
                .frame(height: musicService.currentSong != nil ? 80 : 20)
        }
    }
    
    private func checkIfPinned() {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        Task {
            do {
                let pinnedItems = try await firebaseService.getPinnedItems(userId: userId, itemType: .album)
                await MainActor.run {
                    isPinned = pinnedItems.contains(where: { $0.itemId == album.id.uuidString })
                }
            } catch {
                print("❌ Error checking pin status: \(error.localizedDescription)")
            }
        }
    }
    
    private func togglePin() {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        Task {
            do {
                if isPinned {
                    // Unpin
                    try await firebaseService.unpinItem(itemId: album.id.uuidString, userId: userId)
                    await MainActor.run {
                        isPinned = false
                    }
                    print("📌 Unpinned album")
                } else {
                    // Pin
                    let pinnedItem = PinnedItem(
                        userId: userId,
                        itemId: album.id.uuidString,
                        itemType: .album,
                        itemTitle: album.title,
                        itemSubtitle: album.artist,
                        artworkURL: album.artworkURL,
                        pinnedAt: Date()
                    )
                    try await firebaseService.pinItem(pinnedItem)
                    await MainActor.run {
                        isPinned = true
                    }
                    print("📌 Pinned album to profile")
                }
            } catch {
                print("❌ Error toggling pin: \(error.localizedDescription)")
            }
        }
    }
    
    private func extractDominantColor() {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo, .red]
        dominantColor = colors.randomElement() ?? .blue
    }
}

// MARK: - Album Song Row

struct AlbumSongRow: View {
    let song: Song
    let trackNumber: Int
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            Task {
                await musicService.playSong(song)
            }
        }) {
            HStack(spacing: 12) {
                // Track number or playing indicator
                if musicService.currentSong?.id == song.id && musicService.isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .frame(width: 30)
                } else {
                    Text("\(trackNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration (if available)
                if song.totalMinutes > 0 {
                    Text("\(song.totalMinutes / song.playCount):\(String(format: "%02d", (song.totalMinutes * 60 / song.playCount) % 60))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        AlbumDetailView(album: AlbumSearchResult(
            title: "1989",
            artist: "Taylor Swift",
            artworkURL: nil
        ))
    }
}
