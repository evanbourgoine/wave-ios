//
//  MusicKitService.swift
//  Wave
//
//  Service for interacting with Apple Music via MusicKit
//

import Foundation
import MusicKit
import SwiftUI

@MainActor
class MusicKitService: ObservableObject {
    static let shared = MusicKitService()
    
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var recentlyPlayedSongs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentSong: Song?
    
    // Cache for playlists to avoid re-fetching
    private var cachedPlaylists: [MusicKit.Playlist]?
    private var playlistsCacheTime: Date?
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    private let player = ApplicationMusicPlayer.shared
    
    private init() {
        authorizationStatus = MusicAuthorization.currentStatus
        isAuthorized = authorizationStatus == .authorized
        setupPlayerObserver()
    }
    
    // MARK: - Player Observer
    
    private func setupPlayerObserver() {
        // Poll player state periodically
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                let status = self.player.state.playbackStatus
                self.isPlaying = (status == .playing)
            }
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
        
        if isAuthorized {
            await loadInitialData()
        }
    }
    
    func checkAuthorization() {
        authorizationStatus = MusicAuthorization.currentStatus
        isAuthorized = authorizationStatus == .authorized
        
        print("🎵 Authorization Check:")
        print("   Status: \(authorizationStatus)")
        print("   Is Authorized: \(isAuthorized)")
    }
    
    // Test if MusicKit API is responding
    func testMusicKitConnection() async {
        print("🧪 Testing MusicKit API connection...")
        
        do {
            var request = MusicCatalogSearchRequest(term: "test", types: [MusicKit.Song.self])
            request.limit = 1
            
            print("   Sending test search request...")
            let response = try await request.response()
            
            print("✅ MusicKit API is working! Found \(response.songs.count) results")
        } catch {
            print("❌ MusicKit API test FAILED: \(error.localizedDescription)")
            print("   Error: \(error)")
        }
    }
    
    // MARK: - Load Initial Data
    
    private func loadInitialData() async {
        await fetchRecentlyPlayed()
    }
    
    // MARK: - Fetch Recently Played
    
    func fetchRecentlyPlayed(limit: Int = 50) async {
        guard isAuthorized else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Request recently played tracks
            var request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            request.limit = limit
            
            let response = try await request.response()
            
            // Convert MusicKit.Song to our Song model
            recentlyPlayedSongs = response.items.compactMap { musicKitSong in
                convertToSong(musicKitSong)
            }
            
            print("✅ Fetched \(recentlyPlayedSongs.count) recently played songs")
            
        } catch {
            print("❌ Error fetching recently played: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch User's Top Songs
    
    func fetchTopSongs(limit: Int = 25) async -> [Song] {
        guard isAuthorized else { return [] }
        
        do {
            // Apple Music API has a maximum limit of 30
            var heavyRotationRequest = MusicRecentlyPlayedRequest<MusicKit.Song>()
            heavyRotationRequest.limit = min(limit, 30) // Cap at 30
            
            let response = try await heavyRotationRequest.response()
            
            // Count plays and sort
            var songPlayCounts: [String: (song: MusicKit.Song, count: Int)] = [:]
            
            for song in response.items {
                let key = song.id.rawValue
                if let existing = songPlayCounts[key] {
                    songPlayCounts[key] = (song, existing.count + 1)
                } else {
                    songPlayCounts[key] = (song, 1)
                }
            }
            
            // Sort by play count and convert
            // Only include songs played more than once to filter out one-offs
            let topSongs = songPlayCounts.values
                .filter { $0.count > 1 } // Filter songs played multiple times
                .sorted { $0.count > $1.count }
                .prefix(limit)
                .map { convertToSong($0.song, playCount: $0.count) }
            
            print("✅ Found \(topSongs.count) top songs (played multiple times)")
            return topSongs
            
        } catch {
            print("❌ Error fetching top songs: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Fetch User's Top Artists
    
    func fetchTopArtists(limit: Int = 25) async -> [Artist] {
        guard isAuthorized else { return [] }
        
        do {
            // Apple Music API has a maximum limit of 30
            var request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            request.limit = 30 // Maximum allowed by Apple
            let response = try await request.response()
            
            // Count plays per artist
            var artistPlayCounts: [String: (name: String, count: Int, songs: Set<String>, totalDuration: Double)] = [:]
            
            for song in response.items {
                let artistName = song.artistName
                let duration = song.duration ?? 0
                
                if var existing = artistPlayCounts[artistName] {
                    existing.count += 1
                    existing.songs.insert(song.title)
                    existing.totalDuration += duration
                    artistPlayCounts[artistName] = existing
                } else {
                    artistPlayCounts[artistName] = (artistName, 1, [song.title], duration)
                }
            }
            
            // Sort and convert
            let topArtists = artistPlayCounts.values
                .filter { $0.count > 1 } // Only artists you've played multiple times
                .sorted { $0.count > $1.count }
                .prefix(limit)
                .map { data in
                    Artist(
                        name: data.name,
                        imageURL: nil,
                        playCount: data.count,
                        totalMinutes: Int(data.totalDuration / 60),
                        topSongs: Array(data.songs.prefix(3))
                    )
                }
            
            print("✅ Found \(topArtists.count) top artists")
            return topArtists
            
        } catch {
            print("❌ Error fetching top artists: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Calculate Listening Stats
    
    func calculateListeningStats() async -> ListeningStats {
        guard isAuthorized else {
            return MockDataService.shared.stats
        }
        
        do {
            let request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            let response = try await request.response()
            
            let totalSongs = response.items.count
            let uniqueArtists = Set(response.items.map { $0.artistName }).count
            
            // Estimate total minutes (average 3.5 min per song)
            let totalMinutes = totalSongs * 4
            
            // Calculate top genres (this is simplified - MusicKit doesn't easily expose genre data)
            let topGenres = estimateGenres(from: Array(response.items))
            
            return ListeningStats(
                totalMinutes: totalMinutes,
                totalSongs: totalSongs,
                totalArtists: uniqueArtists,
                topGenres: topGenres,
                averageSessionLength: 45, // Would need session tracking
                longestSession: 180 // Would need session tracking
            )
            
        } catch {
            print("❌ Error calculating stats: \(error.localizedDescription)")
            return MockDataService.shared.stats
        }
    }
    
    // MARK: - Search Music
    
    func searchSongs(query: String, limit: Int = 25) async -> [Song] {
        guard isAuthorized else {
            print("❌ Not authorized for search")
            return []
        }
        guard !query.isEmpty else { return [] }
        
        print("🔍 Searching songs: '\(query)'")
        
        do {
            var searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            searchRequest.limit = limit
            
            let response = try await searchRequest.response()
            let songs = response.songs.compactMap { convertToSong($0) }
            
            print("✅ Found \(songs.count) songs for '\(query)'")
            return songs
            
        } catch {
            print("❌ Error searching songs: \(error.localizedDescription)")
            print("   Full error: \(error)")
            return []
        }
    }
    
    func searchArtists(query: String, limit: Int = 25) async -> [MusicKit.Artist] {
        guard isAuthorized else {
            print("❌ Not authorized for search")
            return []
        }
        guard !query.isEmpty else { return [] }
        
        print("🔍 Searching artists: '\(query)'")
        
        do {
            var searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Artist.self])
            searchRequest.limit = limit
            
            let response = try await searchRequest.response()
            let artists = Array(response.artists)
            
            print("✅ Found \(artists.count) artists for '\(query)'")
            return artists
            
        } catch {
            print("❌ Error searching artists: \(error.localizedDescription)")
            print("   Full error: \(error)")
            return []
        }
    }
    
    func searchAlbums(query: String, limit: Int = 25) async -> [MusicKit.Album] {
        guard isAuthorized else {
            print("❌ Not authorized for search")
            return []
        }
        guard !query.isEmpty else { return [] }
        
        print("🔍 Searching albums: '\(query)'")
        
        // Cap limit to prevent API errors
        let cappedLimit = min(limit, 25)
        
        do {
            var searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
            searchRequest.limit = cappedLimit
            
            let response = try await searchRequest.response()
            let albums = Array(response.albums)
            
            print("✅ Found \(albums.count) albums for '\(query)'")
            return albums
            
        } catch {
            print("❌ Error searching albums: \(error.localizedDescription)")
            print("   Query: \(query), Limit: \(cappedLimit)")
            print("   Full error: \(error)")
            return []
        }
    }
    
    // MARK: - Helper Functions
    
    private func convertToSong(_ musicKitSong: MusicKit.Song, playCount: Int = 1) -> Song {
        Song(
            title: musicKitSong.title,
            artist: musicKitSong.artistName,
            album: musicKitSong.albumTitle ?? "Unknown Album",
            artworkURL: musicKitSong.artwork?.url(width: 300, height: 300)?.absoluteString,
            playCount: playCount,
            totalMinutes: Int((musicKitSong.duration ?? 0) / 60) * playCount
        )
    }
    
    // MARK: - Playback Controls
    
    func playSong(_ song: Song) async {
        print("🎵 playSong CALLED")
        print("   Song: \(song.title)")
        print("   Artist: \(song.artist)")
        print("   Authorization: \(isAuthorized)")
        
        do {
            // Check authorization
            guard isAuthorized else {
                print("❌ Not authorized to play music")
                await requestAuthorization()
                return
            }
            
            print("   Creating search request for: '\(song.title) \(song.artist)'")
            // Search for the song in Apple Music catalog
            var searchRequest = MusicCatalogSearchRequest(term: "\(song.title) \(song.artist)", types: [MusicKit.Song.self])
            searchRequest.limit = 1
            
            print("   Executing search request...")
            let searchResponse = try await searchRequest.response()
            
            print("   Search completed, found \(searchResponse.songs.count) results")
            
            guard let musicKitSong = searchResponse.songs.first else {
                print("❌ Could not find song in Apple Music catalog")
                return
            }
            
            print("   Found song: \(musicKitSong.title)")
            
            // Set the queue and play
            print("   Setting up player queue...")
            player.queue = ApplicationMusicPlayer.Queue(for: [musicKitSong], startingAt: musicKitSong)
            
            print("   Calling player.play()...")
            try await player.play()
            
            print("   Playback started successfully")
            
            await MainActor.run {
                self.isPlaying = true
                self.currentSong = song
            }
            
            print("▶️ Playing: \(song.title) by \(song.artist)")
            
            // Track activity in Firebase
            await trackSongPlay(song)
            
        } catch {
            print("❌ Error playing song: \(error.localizedDescription)")
            print("   Error domain: \((error as NSError).domain)")
            print("   Error code: \((error as NSError).code)")
            print("   Full error: \(error)")
        }
    }
    
    // Play songs directly from MusicKit tracks (for playlists)
    func playMusicKitTrack(_ track: MusicKit.Track, asSong song: Song) async {
        print("🎵 playMusicKitTrack CALLED")
        print("   Track: \(track.title)")
        print("   Artist: \(track.artistName)")
        print("   Falling back to playSong method...")
        
        // Just use the regular playSong method which works elsewhere
        await playSong(song)
    }
    
    func pausePlayback() {
        player.pause()
        isPlaying = false
    }
    
    func resumePlayback() async {
        do {
            try await player.play()
            isPlaying = true
        } catch {
            print("❌ Error resuming playback: \(error)")
        }
    }
    
    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
        } catch {
            print("❌ Error skipping to next: \(error)")
        }
    }
    
    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            print("❌ Error skipping to previous: \(error)")
        }
    }
    
    private func estimateGenres(from songs: [MusicKit.Song]) -> [Genre] {
        // This is a simplified estimation since genre data isn't easily accessible
        // In a production app, you might use the Apple Music API or analyze artist metadata
        
        // For now, return mock genres
        // You could enhance this by analyzing artist names, album titles, etc.
        return [
            Genre(name: "Pop", percentage: 28, color: .purple),
            Genre(name: "Rock", percentage: 22, color: .blue),
            Genre(name: "Hip-Hop", percentage: 18, color: .pink),
            Genre(name: "Electronic", percentage: 16, color: .orange),
            Genre(name: "R&B", percentage: 16, color: .green)
        ]
    }
    
    // MARK: - User Playlists
    
    func fetchUserPlaylists() async throws -> [MusicKit.Playlist] {
        guard isAuthorized else {
            print("❌ Not authorized to fetch playlists")
            return []
        }
        
        // Check cache first
        if let cached = cachedPlaylists,
           let cacheTime = playlistsCacheTime,
           Date().timeIntervalSince(cacheTime) < cacheExpiration {
            print("✅ Using cached playlists (\(cached.count) items)")
            return cached
        }
        
        print("🔄 Fetching fresh playlists from Apple Music...")
        
        do {
            // Request user's library playlists with tracks relationship
            var request = MusicLibraryRequest<MusicKit.Playlist>()
            request.limit = 25 // Limit to 25 playlists
            
            let response = try await request.response()
            
            // Fetch tracks for each playlist to get accurate count
            var playlistsWithTracks: [MusicKit.Playlist] = []
            
            for playlist in response.items {
                do {
                    // Request full playlist details with tracks
                    if let detailedPlaylist = try? await playlist.with([.tracks]) {
                        playlistsWithTracks.append(detailedPlaylist)
                    } else {
                        // If loading tracks fails, still include the playlist
                        playlistsWithTracks.append(playlist)
                    }
                } catch {
                    // Skip playlists that fail to load
                    print("⚠️ Skipping playlist: \(playlist.name)")
                    continue
                }
            }
            
            // Cache the results
            cachedPlaylists = playlistsWithTracks
            playlistsCacheTime = Date()
            
            print("✅ Fetched and cached \(playlistsWithTracks.count) playlists")
            return playlistsWithTracks
        } catch {
            print("❌ Error fetching playlists: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchPlaylistSongs(playlistId: String) async throws -> [Song] {
        print("🎼 fetchPlaylistSongs CALLED with ID: \(playlistId)")
        print("   Authorization status: \(isAuthorized)")
        
        guard isAuthorized else {
            print("❌ Not authorized to fetch playlist songs")
            return []
        }
        
        print("🔍 Fetching songs for playlist ID: \(playlistId)")
        
        do {
            print("   Step 1: Creating MusicItemID...")
            // Create a MusicItemID from the string
            let playlistMusicID = MusicItemID(playlistId)
            
            print("   Step 2: Creating MusicLibraryRequest...")
            // Request the specific playlist by ID
            var request = MusicLibraryRequest<MusicKit.Playlist>()
            request.filter(matching: \.id, equalTo: playlistMusicID)
            
            print("   Step 3: Executing request...")
            let response = try await request.response()
            
            print("📋 Found \(response.items.count) playlist(s)")
            
            guard let playlist = response.items.first else {
                print("❌ Playlist not found with ID: \(playlistId)")
                return []
            }
            
            print("✅ Found playlist: \(playlist.name)")
            
            // Load the playlist with tracks
            let detailedPlaylist = try await playlist.with([.tracks])
            
            // Get tracks from the playlist
            guard let tracks = detailedPlaylist.tracks else {
                print("⚠️ No tracks property in playlist")
                return []
            }
            
            print("📝 Playlist has \(tracks.count) tracks")
            
            // Convert MusicKit tracks to our Song model
            var songs: [Song] = []
            for (index, track) in tracks.enumerated() {
                let song = Song(
                    title: track.title,
                    artist: track.artistName,
                    album: track.albumTitle ?? "Unknown Album",
                    artworkURL: track.artwork?.url(width: 300, height: 300)?.absoluteString,
                    playCount: 0,
                    totalMinutes: Int((track.duration ?? 0) / 60)
                )
                songs.append(song)
                
                if index < 3 {
                    print("  - Song \(index + 1): \(track.title) by \(track.artistName)")
                }
            }
            
            print("✅ Loaded \(songs.count) songs from playlist")
            return songs
        } catch {
            print("❌ Error fetching playlist songs: \(error.localizedDescription)")
            print("Full error: \(error)")
            throw error
        }
    }
    
    // MARK: - Firebase Activity Tracking
    
    private func trackSongPlay(_ song: Song) async {
        guard let userId = FirebaseService.shared.currentUser?.id else { return }
        
        // Increment total songs played
        do {
            try await FirebaseService.shared.incrementSongPlay(userId: userId)
            
            // Log activity
            let activity = Activity(
                userId: userId,
                activityType: .played,
                itemId: song.id.uuidString, // Convert UUID to String
                itemTitle: song.title,
                itemSubtitle: song.artist,
                timestamp: Date()
            )
            try await FirebaseService.shared.logActivity(activity)
            
            print("✅ Tracked song play in Firebase")
        } catch {
            print("❌ Error tracking activity: \(error.localizedDescription)")
        }
    }
}
