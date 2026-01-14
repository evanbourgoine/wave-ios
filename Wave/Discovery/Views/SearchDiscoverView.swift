//
//  SearchDiscoverView.swift
//  Wave
//
//  Search for music, discover new content, and find friends
//

import SwiftUI
import MusicKit

struct SearchDiscoverView: View {
    @StateObject private var musicService = MusicKitService.shared
    @State private var searchText = ""
    @State private var selectedTab: SearchTab = .music
    @State private var searchResults = SearchResults()
    @State private var isSearching = false
    @State private var recommendations: [Song] = []
    @State private var isLoadingRecommendations = false
    @State private var showAllResults = false // Track if user wants to see all results
    
    enum SearchTab: String, CaseIterable {
        case music = "Music"
        case friends = "Friends"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Tab selector (Music/Friends)
                if !searchText.isEmpty {
                    searchTabPicker
                }
                
                // Content
                ScrollView {
                    if searchText.isEmpty {
                        // Discover content when not searching
                        discoverContent
                    } else {
                        // Search results
                        searchResultsContent
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .onTapGesture {
                // Dismiss keyboard when tapping outside search field
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onAppear {
            loadRecommendations()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search songs, artists, albums...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled()
                    .onSubmit {
                        // When user presses search/return, show all results
                        showAllResults = true
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = SearchResults()
                        showAllResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .onChange(of: searchText) { newValue in
            showAllResults = false // Reset when search text changes
            performSearch(query: newValue)
        }
    }
    
    // MARK: - Search Tab Picker
    
    private var searchTabPicker: some View {
        Picker("Search Type", selection: $selectedTab) {
            ForEach(SearchTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Discover Content
    
    private var discoverContent: some View {
        VStack(spacing: 32) {
            // 1. Recommended for You
            recommendedSection
            
            // 2. Friends Are Listening To
            friendsListeningSection
            
            // 3. Browse by Genre
            genreSection
            
            // 4. Trending Now
            trendingSection
            
            // 5. Browse by Mood
            categoriesSection
            
            // 6. New Releases
            newReleasesSection
        }
        .padding()
    }
    
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended for You")
                .font(.title2)
                .fontWeight(.bold)
            
            if isLoadingRecommendations {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if recommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Listen to more music to get personalized recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(recommendations.prefix(10)) { song in
                            RecommendedSongCard(song: song)
                        }
                    }
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Mood")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CategoryCard(title: "Chill", icon: "cloud.fill", color: .blue)
                CategoryCard(title: "Workout", icon: "figure.run", color: .orange)
                CategoryCard(title: "Focus", icon: "brain.head.profile", color: .purple)
                CategoryCard(title: "Party", icon: "party.popper.fill", color: .pink)
                CategoryCard(title: "Sleep", icon: "moon.stars.fill", color: .indigo)
                CategoryCard(title: "Happy", icon: "sun.max.fill", color: .yellow)
            }
        }
    }
    
    private var friendsListeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends Are Listening To")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
            }
            
            // Placeholder friend listening cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        FriendListeningCard(
                            friendName: "Friend \(index + 1)",
                            songTitle: "Song Title",
                            artistName: "Artist Name"
                        )
                    }
                }
            }
        }
    }
    
    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Genre")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                GenreCard(title: "Pop", gradient: [.pink, .purple])
                GenreCard(title: "Hip-Hop", gradient: [.orange, .red])
                GenreCard(title: "Rock", gradient: [.gray, .black])
                GenreCard(title: "Electronic", gradient: [.cyan, .blue])
                GenreCard(title: "Country", gradient: [.brown, .orange])
                GenreCard(title: "Jazz", gradient: [.indigo, .purple])
                GenreCard(title: "Classical", gradient: [.blue, .teal])
                GenreCard(title: "R&B", gradient: [.purple, .pink])
            }
        }
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trending Now")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
            }
            
            // Use recommendations as trending placeholder
            if !recommendations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(recommendations.prefix(8).enumerated()), id: \.element.id) { index, song in
                            TrendingSongCard(song: song, rank: index + 1)
                        }
                    }
                }
            }
        }
    }
    
    private var newReleasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Releases")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
            }
            
            if !recommendations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(recommendations.suffix(6)) { song in
                            NewReleaseCard(song: song)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search Results Content
    
    private var searchResultsContent: some View {
        VStack(spacing: 16) {
            if isSearching {
                ProgressView("Searching...")
                    .padding(.top, 40)
            } else {
                if selectedTab == .music {
                    musicSearchResults
                } else {
                    friendsSearchResults
                }
            }
        }
        .padding()
    }
    
    private var musicSearchResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            let results = showAllResults ? searchResults.allResults : searchResults.topResults
            
            if !results.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(results) { item in
                        Group {
                            switch item {
                            case .song(let song):
                                SearchSongRow(song: song)
                            case .artist(let artist):
                                NavigationLink(destination: ArtistProfileView(artist: artist)) {
                                    SearchArtistRow(artist: artist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            case .album(let album):
                                NavigationLink(destination: AlbumDetailView(album: album)) {
                                    SearchAlbumRow(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        if item.id != results.last?.id {
                            Divider()
                                .padding(.leading, 74)
                        }
                    }
                    
                    // Show "See all results" button if not already showing all
                    if !showAllResults && searchResults.hasMoreResults {
                        Button(action: {
                            showAllResults = true
                        }) {
                            HStack {
                                Spacer()
                                Text("See All Results")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
            } else if !isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }
        }
    }
    
    private var friendsSearchResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Friend Search")
                .font(.headline)
            Text("Coming soon! You'll be able to find and connect with friends here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private func performSearch(query: String) {
        print("🔎 performSearch CALLED with query: '\(query)'")
        
        guard !query.isEmpty else {
            print("   Query is empty, clearing results")
            searchResults = SearchResults()
            return
        }
        
        print("   Starting search task...")
        
        // Debounce search
        Task {
            print("   Waiting 0.5s for debounce...")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            guard query == searchText else {
                print("   Search text changed, aborting")
                return
            }
            
            print("   Setting isSearching = true")
            isSearching = true
            defer {
                print("   Setting isSearching = false")
                isSearching = false
            }
            
            print("   Calling musicService.search functions...")
            async let songs = musicService.searchSongs(query: query, limit: 25)
            async let artists = musicService.searchArtists(query: query, limit: 25)
            async let albums = musicService.searchAlbums(query: query, limit: 25)
            
            print("   Awaiting results...")
            searchResults.songs = await songs
            
            // Convert MusicKit artists to our model
            let musicKitArtists = await artists
            searchResults.artists = musicKitArtists.map { artist in
                ArtistSearchResult(
                    name: artist.name,
                    imageURL: artist.artwork?.url(width: 1000, height: 1000)?.absoluteString
                )
            }
            
            // Convert MusicKit albums to our model
            let musicKitAlbums = await albums
            searchResults.albums = musicKitAlbums.map { album in
                AlbumSearchResult(
                    title: album.title,
                    artist: album.artistName,
                    artworkURL: album.artwork?.url(width: 300, height: 300)?.absoluteString
                )
            }
            
            print("🔍 Found \(searchResults.songs.count) songs, \(searchResults.artists.count) artists, \(searchResults.albums.count) albums for '\(query)'")
        }
    }
    
    private func loadRecommendations() {
        guard musicService.isAuthorized else { return }
        
        isLoadingRecommendations = true
        
        Task {
            defer { isLoadingRecommendations = false }
            
            // Get user's top songs as recommendations for now
            // In the future, this could use a recommendation algorithm
            recommendations = await musicService.fetchTopSongs(limit: 15)
        }
    }
}

// MARK: - Search Results Model

struct SearchResults {
    var songs: [Song] = []
    var artists: [ArtistSearchResult] = []
    var albums: [AlbumSearchResult] = []
    
    // Top 10 results (like Apple Music initial display)
    var topResults: [SearchResultItem] {
        getSmartResults(limit: 10)
    }
    
    // All results (when user presses search or "See All")
    var allResults: [SearchResultItem] {
        getSmartResults(limit: nil)
    }
    
    var hasMoreResults: Bool {
        topResults.count < allResults.count
    }
    
    // Smart algorithm that mimics Apple Music's search ranking
    private func getSmartResults(limit: Int?) -> [SearchResultItem] {
        var results: [SearchResultItem] = []
        
        // Apple Music shows results in this priority:
        // 1. If there's a clear top match (exact or very close), show that type first
        // 2. Then show a few of the other types
        // 3. Then more of the primary type
        
        // Determine primary result type based on what we got back
        let primaryType = determinePrimaryType()
        
        switch primaryType {
        case .artist:
            // Artist search (e.g., "Taylor Swift")
            // Show: Artist -> Albums -> Songs
            if !artists.isEmpty {
                results.append(.artist(artists[0]))
            }
            
            // Add first few albums
            for album in albums.prefix(3) {
                results.append(.album(album))
            }
            
            // Add songs
            for song in songs.prefix(6) {
                results.append(.song(song))
            }
            
            // If showing all, add remaining
            if limit == nil {
                for artist in artists.dropFirst() {
                    results.append(.artist(artist))
                }
                for album in albums.dropFirst(3) {
                    results.append(.album(album))
                }
                for song in songs.dropFirst(6) {
                    results.append(.song(song))
                }
            }
            
        case .album:
            // Album search (e.g., "1989")
            // Show: Album -> Artist -> Songs from album -> Other songs
            if !albums.isEmpty {
                results.append(.album(albums[0]))
            }
            
            if !artists.isEmpty {
                results.append(.artist(artists[0]))
            }
            
            for song in songs.prefix(8) {
                results.append(.song(song))
            }
            
            if limit == nil {
                for album in albums.dropFirst() {
                    results.append(.album(album))
                }
                for artist in artists.dropFirst() {
                    results.append(.artist(artist))
                }
                for song in songs.dropFirst(8) {
                    results.append(.song(song))
                }
            }
            
        case .song:
            // Song search (e.g., "Style")
            // Show: Songs primarily, with artist/album sprinkled in
            for (index, song) in songs.prefix(limit ?? 25).enumerated() {
                results.append(.song(song))
                
                // Sprinkle in artist after first song
                if index == 0 && !artists.isEmpty {
                    results.append(.artist(artists[0]))
                }
                
                // Sprinkle in album after a few songs
                if index == 2 && !albums.isEmpty {
                    results.append(.album(albums[0]))
                }
            }
        }
        
        // Apply limit if specified
        if let limit = limit {
            return Array(results.prefix(limit))
        }
        
        return results
    }
    
    private func determinePrimaryType() -> ResultType {
        // Simple heuristic: what did we get the most of?
        // Apple Music's API already ranks results, so the first result is usually most relevant
        
        let songCount = songs.count
        let artistCount = artists.count
        let albumCount = albums.count
        
        // If we got artists and they're a good match, it's probably an artist search
        if artistCount > 0 && artistCount >= albumCount && artistCount >= songCount / 3 {
            return .artist
        }
        
        // If we got albums and not many artists, it's probably an album search
        if albumCount > 0 && albumCount > artistCount {
            return .album
        }
        
        // Default to song search
        return .song
    }
    
    enum ResultType {
        case song, artist, album
    }
}

enum SearchResultItem: Identifiable {
    case song(Song)
    case artist(ArtistSearchResult)
    case album(AlbumSearchResult)
    
    var id: String {
        switch self {
        case .song(let song): return "song-\(song.id)"
        case .artist(let artist): return "artist-\(artist.id)"
        case .album(let album): return "album-\(album.id)"
        }
    }
}

struct ArtistSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let imageURL: String?
}

struct AlbumSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let artworkURL: String?
}

// MARK: - Supporting Views

struct RecommendedSongCard: View {
    let song: Song
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            // Dismiss keyboard first
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // Then play song
            Task {
                await musicService.playSong(song)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Artwork
                ZStack(alignment: .bottomTrailing) {
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 140, height: 140)
                                    .cornerRadius(8)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.largeTitle)
                                            .foregroundColor(.white.opacity(0.7))
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
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                    
                    // Small speaker indicator when playing (like Spotify)
                    if musicService.currentSong?.id == song.id && musicService.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.green)
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .frame(width: 140, alignment: .leading)
                        .foregroundColor(.primary)
                    
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(width: 140, alignment: .leading)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
        }
    }
}

struct SearchSongRow: View {
    let song: Song
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            // Dismiss keyboard first
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // Then play song
            Task {
                await musicService.playSong(song)
            }
        }) {
            HStack(spacing: 12) {
                // Artwork
                ZStack(alignment: .bottomTrailing) {
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(6)
                            case .failure:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                    
                    // Play indicator
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.caption2)
                        Text("Song • \(song.artist)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle()) // Makes entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchArtistRow: View {
    let artist: ArtistSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Artist Photo
            if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.7)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(LinearGradient(
                                colors: [.pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(LinearGradient(
                        colors: [.pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("Artist")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SearchAlbumRow: View {
    let album: AlbumSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Artwork
            if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.7)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                    case .failure:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.fill")
                        .font(.caption2)
                    Text("Album • \(album.artist)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - New Discover Card Components

struct FriendListeningCard: View {
    let friendName: String
    let songTitle: String
    let artistName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friendName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(songTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(artistName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 100)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct GenreCard: View {
    let title: String
    let gradient: [Color]
    
    var body: some View {
        NavigationLink(destination: GenreDetailView(genreName: title, gradient: gradient)) {
            ZStack {
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .frame(height: 80)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrendingSongCard: View {
    let song: Song
    let rank: Int
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            Task {
                await musicService.playSong(song)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
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
                                    .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 120, height: 120)
                            }
                        }
                    }
                    
                    // Trending rank badge
                    Text("#\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(6)
                        .padding(8)
                    
                    // Playing indicator
                    if musicService.currentSong?.id == song.id && musicService.isPlaying {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                        }
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
                .frame(width: 120)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewReleaseCard: View {
    let song: Song
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            Task {
                await musicService.playSong(song)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: 140, height: 140)
                                    .cornerRadius(8)
                            default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 140, height: 140)
                            }
                        }
                    }
                    
                    // New badge
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .cornerRadius(4)
                        .padding(8)
                    
                    // Playing indicator
                    if musicService.currentSong?.id == song.id && musicService.isPlaying {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 140)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchDiscoverView()
}
