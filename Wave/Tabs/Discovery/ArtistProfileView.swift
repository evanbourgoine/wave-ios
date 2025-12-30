//
//  ArtistProfileView.swift
//  Wave
//
//  Redesigned artist profile with compact layout, songs grid, horizontal albums
//

import SwiftUI
import MusicKit

struct ArtistProfileView: View {
    let artist: ArtistSearchResult
    @StateObject private var musicService = MusicKitService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var topSongs: [Song] = []
    @State private var albums: [AlbumSearchResult] = []
    @State private var singles: [AlbumSearchResult] = []
    @State private var appearsOn: [AlbumSearchResult] = []
    @State private var isLoading = true
    @State private var dominantColor: Color = .blue
    @State private var showAboutSheet = false
    @State private var isPinned = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Artist Cover Photo
                artistCoverPhoto
                
                // Artist Info
                compactArtistInfo
                
                // Content
                if isLoading {
                    ProgressView("Loading...")
                        .padding(40)
                } else {
                    contentSections
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.15),
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAboutSheet = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.primary)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Swipe right to go back
                    if gesture.translation.width > 100 {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showAboutSheet) {
            aboutSheet
        }
        .onAppear {
            loadArtistData()
            loadSavedRating()
            checkIfPinned()
        }
    }
    
    // MARK: - Artist Cover Photo
    
    private var artistCoverPhoto: some View {
        Group {
            if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                            .onAppear { extractDominantColor(from: image) }
                    default:
                        placeholderPhoto
                    }
                }
            } else {
                placeholderPhoto
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var placeholderPhoto: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 300)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
    
    // MARK: - Compact Artist Info
    
    private var compactArtistInfo: some View {
        VStack(spacing: 0) {
            Color(.systemBackground)
                .frame(height: 10)
            
            VStack(spacing: 16) {
                // Artist Name - Uppercase poster style
                Text(artist.name.uppercased())
                    .font(.system(size: 36, weight: .black, design: .default))
                    .tracking(1.5) // Letter spacing for poster effect
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                
                // Star Rating
                starRatingView
                
                // Action Buttons - Below name
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                            Text("Follow")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [dominantColor, dominantColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(20)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Star Rating View
    
    @State private var userRating: Double = 0.0
    
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
                let ratings = try await firebaseService.getRatings(userId: userId, itemType: .artist)
                // Find rating for this artist (use artist name as ID)
                if let savedRating = ratings.first(where: { $0.itemTitle == artist.name }) {
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
                    itemId: artist.name, // Use artist name as ID
                    itemType: .artist,
                    itemTitle: artist.name,
                    itemSubtitle: "", // Artists don't have a subtitle
                    rating: userRating,
                    ratedAt: Date()
                )
                
                try await firebaseService.saveRating(rating)
                print("✅ Saved artist rating: \(userRating) stars")
            } catch {
                print("❌ Error saving rating: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var contentSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Songs Grid - Horizontal Scroll (3 rows of 3, 15 songs)
            if !topSongs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Songs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [
                            GridItem(.fixed(60)),
                            GridItem(.fixed(60)),
                            GridItem(.fixed(60))
                        ], spacing: 12) {
                            ForEach(topSongs.prefix(15)) { song in
                                CompactSongRow(song: song)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 200)
                }
            }
            
            // Albums - Scaling Carousel
            if !albums.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Albums")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    ScalingAlbumsCarousel(albums: albums.filter { !isSingleOrEP($0) })
                        .frame(height: 200)
                }
            }
            
            // Singles & EPs - Scaling Carousel
            if !singles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Singles & EPs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    ScalingAlbumsCarousel(albums: singles)
                        .frame(height: 200)
                }
            }
            
            // Appears On (Compilations/Features)
            if !appearsOn.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appears On")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(appearsOn) { album in
                                NavigationLink(destination: AlbumDetailView(album: album)) {
                                    CompactAlbumCard(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // Bottom Action Buttons
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
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Extra bottom padding for mini player
                Color.clear
                    .frame(height: musicService.currentSong != nil ? 80 : 40)
            }
        }
        .padding(.top, 16)
        .background(Color(.systemBackground))
    }
    
    private func checkIfPinned() {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        Task {
            do {
                let pinnedItems = try await firebaseService.getPinnedItems(userId: userId, itemType: .artist)
                await MainActor.run {
                    isPinned = pinnedItems.contains(where: { $0.itemTitle == artist.name })
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
                    try await firebaseService.unpinItem(itemId: artist.name, userId: userId)
                    await MainActor.run {
                        isPinned = false
                    }
                    print("📌 Unpinned artist")
                } else {
                    // Pin
                    let pinnedItem = PinnedItem(
                        userId: userId,
                        itemId: artist.name,
                        itemType: .artist,
                        itemTitle: artist.name,
                        itemSubtitle: "",
                        artworkURL: artist.imageURL,
                        pinnedAt: Date()
                    )
                    try await firebaseService.pinItem(pinnedItem)
                    await MainActor.run {
                        isPinned = true
                    }
                    print("📌 Pinned artist to profile")
                }
            } catch {
                print("❌ Error toggling pin: \(error.localizedDescription)")
            }
        }
    }
    
    private func isSingleOrEP(_ album: AlbumSearchResult) -> Bool {
        let title = album.title.lowercased()
        return title.contains("single") || title.contains(" ep") || title.contains("- ep")
    }
    
    // MARK: - About Sheet
    
    private var aboutSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Biographical information coming soon.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wave Community")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            CommunityFeatureCard(
                                icon: "person.2.fill",
                                title: "Friends Listening",
                                description: "See which friends also love \(artist.name)",
                                color: dominantColor
                            )
                            
                            CommunityFeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Trending",
                                description: "Track popularity among Wave users",
                                color: dominantColor.opacity(0.8)
                            )
                            
                            CommunityFeatureCard(
                                icon: "sparkles",
                                title: "AI Insights",
                                description: "Get personalized recommendations",
                                color: dominantColor.opacity(0.6)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(artist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAboutSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadArtistData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            let songs = await musicService.searchSongs(query: artist.name, limit: 25)
            topSongs = songs.filter { song in
                song.artist.lowercased().contains(artist.name.lowercased()) ||
                artist.name.lowercased().contains(song.artist.lowercased())
            }
            
            // Reduced limit to avoid API errors
            let albumResults = await musicService.searchAlbums(query: artist.name, limit: 25)
            let allAlbums = albumResults.map { album in
                AlbumSearchResult(
                    title: album.title,
                    artist: album.artistName,
                    artworkURL: album.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }.filter { album in
                album.artist.lowercased().contains(artist.name.lowercased()) ||
                artist.name.lowercased().contains(album.artist.lowercased())
            }
            
            // Simple categorization
            let singleEPAlbums = allAlbums.filter { isSingleOrEP($0) }
            let fullAlbums = allAlbums.filter { !isSingleOrEP($0) }
            
            // If we have a good split, use it. Otherwise show all in Albums
            if !singleEPAlbums.isEmpty && !fullAlbums.isEmpty {
                albums = fullAlbums
                singles = singleEPAlbums
            } else {
                // Show all albums in main section
                albums = allAlbums
                singles = []
            }
            
            // For now, leave Appears On empty (hard to detect accurately)
            appearsOn = []
        }
    }
    
    private func isMainArtist(_ album: AlbumSearchResult) -> Bool {
        // More lenient - include if artist name appears anywhere
        let albumArtist = album.artist.lowercased()
        let searchArtist = artist.name.lowercased()
        return albumArtist.contains(searchArtist) || searchArtist.contains(albumArtist)
    }
    
    private func extractDominantColor(from image: Image) {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo]
        dominantColor = colors.randomElement() ?? .blue
    }
}

// MARK: - Supporting Views

struct CompactSongRow: View {
    let song: Song
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            Task {
                await musicService.playSong(song)
            }
        }) {
            HStack(spacing: 10) {
                // Artwork
                ZStack(alignment: .bottomTrailing) {
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
                                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                    
                    // Playing indicator
                    if musicService.currentSong?.id == song.id && musicService.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.green)
                            .clipShape(Circle())
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .frame(width: 250)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScalingAlbumsCarousel: View {
    let albums: [AlbumSearchResult]
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                    GeometryReader { geometry in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            ScalingAlbumCard(album: album, geometry: geometry)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(width: 160, height: 180)
                }
            }
            .padding(.horizontal, 60)
        }
    }
}

struct ScalingAlbumCard: View {
    let album: AlbumSearchResult
    let geometry: GeometryProxy
    
    var scale: CGFloat {
        let midX = geometry.frame(in: .global).midX
        let screenMidX = UIScreen.main.bounds.width / 2
        let distance = abs(midX - screenMidX)
        let maxDistance: CGFloat = 200
        
        // Scale between 0.8 and 1.0 based on distance from center
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - (normalizedDistance * 0.2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 160)
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scale)
    }
}

struct SongGridCard: View {
    let song: Song
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            Task {
                await musicService.playSong(song)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .cornerRadius(8)
                            default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    
                    // Play indicator if this song is currently playing
                    if musicService.currentSong?.id == song.id && musicService.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactAlbumCard: View {
    let album: AlbumSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120)
        }
    }
}

struct AlbumCard: View {
    let album: AlbumSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 140)
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 140, height: 140)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 140)
        }
    }
}

struct CommunityFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Utilities

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationView {
        ArtistProfileView(artist: ArtistSearchResult(name: "Taylor Swift", imageURL: nil))
    }
}
