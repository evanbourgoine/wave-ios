//
//  ProfileView.swift
//  Wave
//
//  User profile view with stats, pinned items, and settings
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var musicService = MusicKitService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var selectedTab: ProfileContentTab = .playlists
    @State private var showEditProfile = false
    
    enum ProfileContentTab: Int, CaseIterable {
        case playlists = 0
        case pinned = 1
        case ratings = 2
        case stats = 3
        
        var title: String {
            switch self {
            case .playlists: return "Playlists"
            case .pinned: return "Pinned"
            case .ratings: return "Ratings"
            case .stats: return "Stats"
            }
        }
        
        var icon: String {
            switch self {
            case .playlists: return "music.note.list"
            case .pinned: return "pin.fill"
            case .ratings: return "star.fill"
            case .stats: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instagram-Style Profile Header (Non-scrolling)
                profileHeader
                
                // Tab Bar (Non-scrolling)
                tabBar
                
                // Swipeable Content
                TabView(selection: $selectedTab) {
                    // Playlists Tab
                    ScrollView {
                        VStack(spacing: 20) {
                            playlistsSection
                        }
                        .padding()
                        .padding(.bottom, musicService.currentSong != nil ? 80 : 40)
                    }
                    .tag(ProfileContentTab.playlists)
                    
                    // Pinned Tab
                    ScrollView {
                        VStack(spacing: 20) {
                            pinnedArtistsSection
                        }
                        .padding()
                        .padding(.bottom, musicService.currentSong != nil ? 80 : 40)
                    }
                    .tag(ProfileContentTab.pinned)
                    
                    // Ratings Tab
                    ScrollView {
                        VStack(spacing: 20) {
                            ratingsShowcase
                        }
                        .padding()
                        .padding(.bottom, musicService.currentSong != nil ? 80 : 40)
                    }
                    .tag(ProfileContentTab.ratings)
                    
                    // Stats Tab (now includes Top Artists)
                    ScrollView {
                        VStack(spacing: 32) {
                            topArtistsSection
                            statsSection
                        }
                        .padding()
                        .padding(.bottom, musicService.currentSong != nil ? 80 : 40)
                    }
                    .tag(ProfileContentTab.stats)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(firebaseService.currentUser?.username ?? "waveuser")
            .onAppear {
                // Load sequentially to avoid overwhelming the system
                Task {
                    await loadMetrics()
                    await loadTopRatingsSequentially()
                    await loadPinnedArtistsSequentially()
                    await loadPlaylistsSequentially()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileContentTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    )
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Instagram-Style Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 20) {
                // Profile Picture - Left Side
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Metrics - Right Side
                HStack(spacing: 0) {
                    MetricView(
                        value: "\(totalRatings)",
                        label: "Ratings"
                    )
                    
                    MetricView(
                        value: "\(totalFriends)",
                        label: "Friends"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Real Name and Bio - Instagram Style (Left-aligned)
            VStack(alignment: .leading, spacing: 4) {
                // Real Name (bold)
                if let realName = firebaseService.currentUser?.realName, !realName.isEmpty {
                    Text(realName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // Bio
                if let bio = firebaseService.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            // Edit Profile Button
            Button(action: {
                showEditProfile = true
            }) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showEditProfile) {
            NavigationView {
                EditProfileView(isPresentedAsSheet: true)
            }
        }
    }
    
    @State private var totalRatings = 0
    @State private var totalFriends = 0
    
    // MARK: - My Playlists Section
    
    @State private var userPlaylists: [UserPlaylist] = []
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userPlaylists.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Playlists Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Create playlists in Apple Music to see them here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                Text("My Playlists")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(userPlaylists.count) playlists")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    ForEach(userPlaylists) { playlist in
                        PlaylistCard(playlist: playlist)
                    }
                }
            }
        }
    }
    
    private func loadPlaylists() {
        Task {
            do {
                let playlists = try await musicService.fetchUserPlaylists()
                await MainActor.run {
                    userPlaylists = playlists.compactMap { musicKitPlaylist in
                        // Get track count - handle optional tracks
                        let trackCount: Int
                        if let tracks = musicKitPlaylist.tracks {
                            trackCount = tracks.count
                        } else {
                            trackCount = 0
                        }
                        
                        // Get artwork URL - try different sizes
                        let artworkURL: String?
                        if let artwork = musicKitPlaylist.artwork {
                            // Try multiple sizes
                            if let url = artwork.url(width: 300, height: 300) {
                                artworkURL = url.absoluteString
                            } else if let url = artwork.url(width: 200, height: 200) {
                                artworkURL = url.absoluteString
                            } else {
                                artworkURL = nil
                            }
                        } else {
                            artworkURL = nil
                        }
                        
                        return UserPlaylist(
                            id: musicKitPlaylist.id.rawValue,
                            name: musicKitPlaylist.name,
                            trackCount: trackCount,
                            artworkURL: artworkURL
                        )
                    }
                    
                    print("✅ Loaded \(userPlaylists.count) playlists for display")
                }
            } catch {
                print("❌ Error loading playlists: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Pinned Artists Section
    
    @State private var pinnedArtists: [PinnedItem] = []
    
    private var pinnedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pinnedArtists.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Pinned Artists")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Pin your favorite artists to showcase them here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(pinnedArtists) { item in
                    PinnedItemCard(item: item)
                }
            }
        }
        .onAppear {
            loadPinnedArtists()
        }
    }
    
    private func loadPinnedArtistsSequentially() async {
        guard let userId = firebaseService.currentUser?.id else {
            print("❌ No user ID for pinned artists")
            return
        }
        
        print("🔍 Loading pinned artists for user: \(userId)")
        
        do {
            let allPinned = try await withTimeout(seconds: 5) {
                try await firebaseService.getPinnedItems(userId: userId, itemType: .artist)
            }
            
            await MainActor.run {
                pinnedArtists = allPinned
                print("✅ Loaded \(pinnedArtists.count) pinned artists")
                if !pinnedArtists.isEmpty {
                    print("   Pinned: \(pinnedArtists.map { $0.itemTitle }.prefix(3).joined(separator: ", "))")
                }
            }
        } catch {
            print("❌ Error loading pinned: \(error.localizedDescription)")
            await MainActor.run {
                pinnedArtists = []
            }
        }
    }
    
    private func loadTopRatingsSequentially() async {
        guard let userId = firebaseService.currentUser?.id else {
            print("❌ No user ID for ratings")
            return
        }
        
        print("🔍 Loading top ratings for user: \(userId)")
        
        do {
            // Load one at a time
            let songs = try await withTimeout(seconds: 5) {
                try await firebaseService.getTopRatings(userId: userId, itemType: .song, limit: 5)
            }
            
            let albums = try await withTimeout(seconds: 5) {
                try await firebaseService.getTopRatings(userId: userId, itemType: .album, limit: 5)
            }
            
            let artists = try await withTimeout(seconds: 5) {
                try await firebaseService.getTopRatings(userId: userId, itemType: .artist, limit: 5)
            }
            
            await MainActor.run {
                topRatedSongs = songs
                topRatedAlbums = albums
                topRatedArtists = artists
                print("✅ Loaded ratings: \(songs.count) songs, \(albums.count) albums, \(artists.count) artists")
            }
        } catch {
            print("❌ Error loading ratings: \(error.localizedDescription)")
            await MainActor.run {
                topRatedSongs = []
                topRatedAlbums = []
                topRatedArtists = []
            }
        }
    }
    
    private func loadPlaylistsSequentially() async {
        print("🔍 Loading playlists")
        
        do {
            let playlists = try await musicService.fetchUserPlaylists()
            await MainActor.run {
                userPlaylists = playlists.compactMap { musicKitPlaylist in
                    let trackCount: Int
                    if let tracks = musicKitPlaylist.tracks {
                        trackCount = tracks.count
                    } else {
                        trackCount = 0
                    }
                    
                    let artworkURL: String?
                    if let artwork = musicKitPlaylist.artwork {
                        if let url = artwork.url(width: 300, height: 300) {
                            artworkURL = url.absoluteString
                        } else if let url = artwork.url(width: 200, height: 200) {
                            artworkURL = url.absoluteString
                        } else {
                            artworkURL = nil
                        }
                    } else {
                        artworkURL = nil
                    }
                    
                    return UserPlaylist(
                        id: musicKitPlaylist.id.rawValue,
                        name: musicKitPlaylist.name,
                        trackCount: trackCount,
                        artworkURL: artworkURL
                    )
                }
                
                print("✅ Loaded \(userPlaylists.count) playlists for display")
            }
        } catch {
            print("❌ Error loading playlists: \(error.localizedDescription)")
        }
    }
    
    private func loadPinnedArtists() {
        guard let userId = firebaseService.currentUser?.id else {
            print("❌ No user ID for pinned artists")
            return
        }
        
        print("🔍 Loading pinned artists for user: \(userId)")
        
        Task {
            do {
                // Add timeout of 10 seconds
                let allPinned = try await withTimeout(seconds: 10) {
                    try await firebaseService.getPinnedItems(userId: userId, itemType: .artist)
                }
                
                await MainActor.run {
                    pinnedArtists = allPinned
                    print("✅ Loaded \(pinnedArtists.count) pinned artists")
                    if pinnedArtists.isEmpty {
                        print("⚠️ No pinned artists found - try pinning an artist first")
                    } else {
                        print("   Pinned artists: \(pinnedArtists.map { $0.itemTitle }.joined(separator: ", "))")
                    }
                }
            } catch {
                print("❌ Error loading pinned artists: \(error.localizedDescription)")
                await MainActor.run {
                    pinnedArtists = []
                }
            }
        }
    }
    
    // MARK: - Top Artists Section
    
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Top Artists")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Based on your listening this month")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(0..<5) { index in
                    TopArtistCard(rank: index + 1, artistName: "Artist \(index + 1)")
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Track your listening habits")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Listening Time
                ProfileStatCard(
                    title: "Total Listening Time",
                    value: "\(Int(firebaseService.currentUser?.totalListeningHours ?? 0)) hours",
                    icon: "clock.fill",
                    color: .blue,
                    trend: nil
                )
                
                // Total Songs
                ProfileStatCard(
                    title: "Songs Played",
                    value: "\(firebaseService.currentUser?.totalSongsPlayed ?? 0)",
                    icon: "music.note",
                    color: .purple,
                    trend: nil
                )
                
                // Unique Artists
                ProfileStatCard(
                    title: "Unique Artists",
                    value: "\(firebaseService.currentUser?.uniqueArtistsCount ?? 0)",
                    icon: "person.2",
                    color: .pink,
                    trend: nil
                )
            }
        }
    }
    
    // MARK: - Ratings Showcase
    
    private var ratingsShowcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Your Top Ratings", icon: "star.fill")
                Spacer()
                NavigationLink(destination: AllRatingsView()) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Rating Category Tabs
            HStack(spacing: 8) {
                ForEach(RatingCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedRatingCategory = category
                    }) {
                        Text(category.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedRatingCategory == category ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedRatingCategory == category ? Color.blue : Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Top 5 Rated Items - Real Data
            if currentTopRatings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No ratings yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Rate \(selectedRatingCategory.title.lowercased()) to see them here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(currentTopRatings.prefix(5).enumerated()), id: \.element.id) { index, rating in
                        TopRatedItemRow(
                            rank: index + 1,
                            title: rating.itemTitle,
                            subtitle: rating.itemSubtitle,
                            rating: rating.rating,
                            category: selectedRatingCategory
                        )
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .onAppear {
            loadTopRatings()
        }
        .onChange(of: selectedRatingCategory) { _ in
            // Data already loaded, just switches display
        }
    }
    
    private func loadTopRatings() {
        guard let userId = firebaseService.currentUser?.id else {
            print("❌ No user ID for ratings")
            return
        }
        
        print("🔍 Loading top ratings for user: \(userId)")
        
        Task {
            do {
                // Load with timeout
                async let songsTask = withTimeout(seconds: 10) {
                    try await firebaseService.getTopRatings(userId: userId, itemType: .song, limit: 5)
                }
                async let albumsTask = withTimeout(seconds: 10) {
                    try await firebaseService.getTopRatings(userId: userId, itemType: .album, limit: 5)
                }
                async let artistsTask = withTimeout(seconds: 10) {
                    try await firebaseService.getTopRatings(userId: userId, itemType: .artist, limit: 5)
                }
                
                let (songs, albums, artists) = try await (songsTask, albumsTask, artistsTask)
                
                await MainActor.run {
                    topRatedSongs = songs
                    topRatedAlbums = albums
                    topRatedArtists = artists
                    
                    print("✅ Loaded ratings:")
                    print("   Songs: \(topRatedSongs.count)")
                    print("   Albums: \(topRatedAlbums.count)")
                    print("   Artists: \(topRatedArtists.count)")
                    
                    let totalRatings = topRatedSongs.count + topRatedAlbums.count + topRatedArtists.count
                    if totalRatings == 0 {
                        print("⚠️ No ratings found - try rating some albums/songs/artists first")
                    }
                }
            } catch {
                print("❌ Error loading ratings: \(error.localizedDescription)")
                await MainActor.run {
                    topRatedSongs = []
                    topRatedAlbums = []
                    topRatedArtists = []
                }
            }
        }
    }
    
    @State private var selectedRatingCategory: RatingCategory = .songs
    @State private var topRatedSongs: [Rating] = []
    @State private var topRatedAlbums: [Rating] = []
    @State private var topRatedArtists: [Rating] = []
    
    private var currentTopRatings: [Rating] {
        switch selectedRatingCategory {
        case .songs: return topRatedSongs
        case .albums: return topRatedAlbums
        case .artists: return topRatedArtists
        }
    }
    
    enum RatingCategory: CaseIterable {
        case songs, albums, artists
        
        var title: String {
            switch self {
            case .songs: return "Songs"
            case .albums: return "Albums"
            case .artists: return "Artists"
            }
        }
        
        var icon: String {
            switch self {
            case .songs: return "music.note"
            case .albums: return "square.stack"
            case .artists: return "person.fill"
            }
        }
    }
    
    // MARK: - Stats Content
    
    
    // MARK: - Load Metrics
    
    private func loadMetrics() async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        print("🔍 Loading metrics for user: \(userId)")
        
        do {
            // Count total ratings with timeout
            let allRatings = try await withTimeout(seconds: 5) {
                try await firebaseService.getRatings(userId: userId)
            }
            
            await MainActor.run {
                totalRatings = allRatings.count
                totalFriends = 0
                print("✅ Loaded metrics: \(totalRatings) ratings")
            }
        } catch {
            print("❌ Error loading metrics: \(error.localizedDescription)")
            await MainActor.run {
                totalRatings = 0
                totalFriends = 0
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}


struct TopArtistCard: View {
    let rank: Int
    let artistName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            Text("#\(rank)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: rankColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
            
            // Artist Image
            Circle()
                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            // Artist Info
            VStack(alignment: .leading, spacing: 4) {
                Text(artistName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Your top artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var rankColors: [Color] {
        switch rank {
        case 1: return [.yellow, .orange]
        case 2: return [.gray, .white]
        case 3: return [.orange, .brown]
        default: return [.blue, .purple]
        }
    }
}

struct TopRatedItemRow: View {
    let rank: Int
    let title: String
    let subtitle: String
    let rating: Double
    let category: ProfileView.RatingCategory
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Icon based on category
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Star rating
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: starImage(for: index, rating: rating))
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func starImage(for index: Int, rating: Double) -> String {
        let position = Double(index)
        if rating >= position + 1 {
            return "star.fill"
        } else if rating > position && rating < position + 1 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - All Ratings View

struct AllRatingsView: View {
    @State private var selectedFilter: RatingFilter = .all
    @State private var selectedCategory: ProfileView.RatingCategory = .songs
    
    enum RatingFilter: String, CaseIterable {
        case all = "All"
        case fiveStar = "5 ★"
        case fourToFive = "4-4.5 ★"
        case threeToFour = "3-4 ★"
        case twoToThree = "2-3 ★"
        case oneToTwo = "1-2 ★"
        case zeroToOne = "0-1 ★"
        
        func matches(rating: Double) -> Bool {
            switch self {
            case .all: return true
            case .fiveStar: return rating == 5.0
            case .fourToFive: return rating >= 4.0 && rating < 5.0
            case .threeToFour: return rating >= 3.0 && rating < 4.0
            case .twoToThree: return rating >= 2.0 && rating < 3.0
            case .oneToTwo: return rating >= 1.0 && rating < 2.0
            case .zeroToOne: return rating >= 0.0 && rating < 1.0
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category Tabs
                HStack(spacing: 8) {
                    ForEach(ProfileView.RatingCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Star Filter Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RatingFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedFilter == filter ? .white : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFilter == filter ? Color.yellow : Color(.tertiarySystemGroupedBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Filtered List
                VStack(spacing: 0) {
                    ForEach(filteredRatings, id: \.0) { index, rating in
                        TopRatedItemRow(
                            rank: index + 1,
                            title: "Item \(index + 1)",
                            subtitle: "Details",
                            rating: rating,
                            category: selectedCategory
                        )
                        
                        if index < filteredRatings.count - 1 {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("All Ratings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Placeholder data - will be replaced with real ratings
    private var allRatings: [Double] {
        [5.0, 4.5, 4.5, 4.0, 4.0, 3.5, 3.0, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5]
    }
    
    private var filteredRatings: [(Int, Double)] {
        allRatings
            .filter { selectedFilter.matches(rating: $0) }
            .enumerated()
            .map { ($0.offset, $0.element) }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


struct PinnedItemCard: View {
    let item: PinnedItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = item.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if !item.itemSubtitle.isEmpty {
                    Text(item.itemSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(item.itemType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "pin.fill")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Timeout Helper

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out"
    }
}

// MARK: - Playlist Model & Card

struct UserPlaylist: Identifiable {
    let id: String
    let name: String
    let trackCount: Int
    let artworkURL: String?
}

struct PlaylistCard: View {
    let playlist: UserPlaylist
    
    var body: some View {
        NavigationLink(destination: PlaylistDetailView(
            playlistId: playlist.id,
            playlistName: playlist.name,
            playlistArtwork: playlist.artworkURL,
            trackCount: playlist.trackCount
        )) {
            HStack(spacing: 12) {
                // Playlist Artwork
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .foregroundColor(.white)
                        )
                }
                
                // Playlist Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(playlist.trackCount) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}
