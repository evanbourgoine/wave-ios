//
//  GenreDetailView.swift
//  Wave
//
//  Shows songs and albums for a specific genre
//

import SwiftUI
import MusicKit

struct GenreDetailView: View {
    let genreName: String
    let gradient: [Color]
    
    @StateObject private var musicService = MusicKitService.shared
    @State private var genreSongs: [Song] = []
    @State private var genreAlbums: [AlbumSearchResult] = []
    @State private var isLoading = true
    @State private var selectedView: GenreViewType = .songs
    
    enum GenreViewType {
        case songs, albums
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Genre Header
                genreHeader
                
                // Toggle Control
                genreToggle
                
                // Content with slide animation
                if isLoading {
                    ProgressView("Loading \(genreName) music...")
                        .padding(.top, 40)
                } else {
                    ZStack {
                        // Songs View
                        if selectedView == .songs {
                            songsView
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                        
                        // Albums View
                        if selectedView == .albums {
                            albumsView
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedView)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGenreContent()
        }
    }
    
    // MARK: - Genre Toggle
    
    private var genreToggle: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Background
                Color(.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                
                HStack(spacing: 0) {
                    // Songs Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedView = .songs
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "music.note.list")
                                .font(.title3)
                            Text("Songs")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedView == .songs ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    
                    // Albums Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedView = .albums
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.stack")
                                .font(.title3)
                            Text("Albums")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedView == .albums ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                
                // Wave sliding indicator at bottom
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        WaveShape()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width / 2, height: 4)
                            .offset(x: selectedView == .songs ? 0 : geometry.size.width / 2)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedView)
                    }
                }
                .frame(height: 4)
            }
            .frame(height: 70)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Content Views
    
    private var songsView: some View {
        VStack(spacing: 32) {
            if !genreSongs.isEmpty {
                popularSongsSection
            } else {
                Text("No songs found")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            }
            
            // Bottom padding for mini player
            Color.clear
                .frame(height: musicService.currentSong != nil ? 80 : 40)
        }
        .padding()
    }
    
    private var albumsView: some View {
        VStack(spacing: 32) {
            if !genreAlbums.isEmpty {
                albumsSection
            } else {
                Text("No albums found")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            }
            
            // Bottom padding for mini player
            Color.clear
                .frame(height: musicService.currentSong != nil ? 80 : 40)
        }
        .padding()
    }
    
    // MARK: - Genre Header
    
    private var genreHeader: some View {
        ZStack {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 200)
            
            VStack(spacing: 8) {
                Image(systemName: genreIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text(genreName)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var genreIcon: String {
        switch genreName.lowercased() {
        case "pop": return "star.fill"
        case "hip-hop": return "waveform"
        case "rock": return "guitars.fill"
        case "electronic": return "waveform.path.ecg"
        case "country": return "music.note"
        case "jazz": return "music.quarternote.3"
        case "classical": return "music.note.list"
        case "r&b": return "music.mic"
        default: return "music.note"
        }
    }
    
    // MARK: - Popular Songs Section
    
    private var popularSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVStack(spacing: 0) {
                ForEach(Array(genreSongs.prefix(20).enumerated()), id: \.element.id) { index, song in
                    GenreSongRow(song: song, rank: index + 1)
                    
                    if index < min(19, genreSongs.count - 1) {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Albums Section
    
    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(genreAlbums.prefix(12)) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        GenreAlbumCard(album: album)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadGenreContent() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            var allSongs: [Song] = []
            var allAlbums: [AlbumSearchResult] = []
            
            // Strategy 1: Search for "top [genre]" and "popular [genre]"
            let topSearches = [
                "\(genreName) top hits 2024",
                "popular \(genreName) 2024",
                "best \(genreName) songs"
            ]
            
            for searchTerm in topSearches {
                let songs = await musicService.searchSongs(query: searchTerm, limit: 15)
                allSongs.append(contentsOf: songs)
                
                let albums = await musicService.searchAlbums(query: searchTerm, limit: 10)
                let albumResults = albums.map { album in
                    AlbumSearchResult(
                        title: album.title,
                        artist: album.artistName,
                        artworkURL: album.artwork?.url(width: 300, height: 300)?.absoluteString
                    )
                }
                allAlbums.append(contentsOf: albumResults)
            }
            
            // Strategy 2: Search top current artists in genre
            let topArtists = getCurrentTopArtists()
            for artist in topArtists.prefix(3) {
                let songs = await musicService.searchSongs(query: artist, limit: 8)
                allSongs.append(contentsOf: songs)
                
                let albums = await musicService.searchAlbums(query: artist, limit: 3)
                let albumResults = albums.map { album in
                    AlbumSearchResult(
                        title: album.title,
                        artist: album.artistName,
                        artworkURL: album.artwork?.url(width: 300, height: 300)?.absoluteString
                    )
                }
                allAlbums.append(contentsOf: albumResults)
            }
            
            // Remove duplicates by ID
            let uniqueSongs = Dictionary(grouping: allSongs, by: { $0.id })
                .compactMap { $0.value.first }
            
            let uniqueAlbums = Dictionary(grouping: allAlbums, by: { $0.id })
                .compactMap { $0.value.first }
            
            // Prioritize diversity - limit songs per artist
            var artistSongCount: [String: Int] = [:]
            genreSongs = uniqueSongs.filter { song in
                let count = artistSongCount[song.artist, default: 0]
                if count < 3 { // Max 3 songs per artist
                    artistSongCount[song.artist] = count + 1
                    return true
                }
                return false
            }.shuffled()
            
            // Prioritize diversity - limit albums per artist
            var artistAlbumCount: [String: Int] = [:]
            genreAlbums = uniqueAlbums.filter { album in
                let count = artistAlbumCount[album.artist, default: 0]
                if count < 2 { // Max 2 albums per artist
                    artistAlbumCount[album.artist] = count + 1
                    return true
                }
                return false
            }.shuffled()
        }
    }
    
    private func getCurrentTopArtists() -> [String] {
        // Returns currently trending/popular artists in each genre (updated for 2024-2025)
        switch genreName.lowercased() {
        case "pop":
            return ["Taylor Swift", "Sabrina Carpenter", "Olivia Rodrigo", "Ariana Grande", "Dua Lipa", "Billie Eilish"]
        case "hip-hop":
            return ["Drake", "Travis Scott", "21 Savage", "Metro Boomin", "Future", "Playboi Carti"]
        case "rock":
            return ["Sleep Token", "Foo Fighters", "Greta Van Fleet", "The 1975", "Arctic Monkeys", "boygenius"]
        case "electronic":
            return ["Fred again..", "Calvin Harris", "David Guetta", "Martin Garrix", "Disclosure", "Skrillex"]
        case "country":
            return ["Morgan Wallen", "Luke Combs", "Zach Bryan", "Jelly Roll", "Cody Johnson", "Kane Brown"]
        case "jazz":
            return ["Robert Glasper", "Kamasi Washington", "Esperanza Spalding", "Norah Jones", "Diana Krall", "Chris Botti"]
        case "classical":
            return ["Ludovico Einaudi", "Max Richter", "Ólafur Arnalds", "Yuja Wang", "Lang Lang", "Hilary Hahn"]
        case "r&b":
            return ["SZA", "Usher", "Summer Walker", "Bryson Tiller", "Victoria Monét", "Coco Jones"]
        default:
            return [genreName]
        }
    }
}

// MARK: - Supporting Views

struct GenreSongRow: View {
    let song: Song
    let rank: Int
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        Button(action: {
            Task {
                await musicService.playSong(song)
            }
        }) {
            HStack(spacing: 12) {
                // Rank or playing indicator
                if musicService.currentSong?.id == song.id && musicService.isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .frame(width: 40)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
                
                // Album artwork
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GenreAlbumCard: View {
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
                            .cornerRadius(8)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Wave Shape for Indicator

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create smooth wave using quadratic curves
        path.addQuadCurve(
            to: CGPoint(x: width * 0.25, y: height * 0.5),
            control: CGPoint(x: width * 0.125, y: 0)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.5),
            control: CGPoint(x: width * 0.375, y: height)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.5),
            control: CGPoint(x: width * 0.625, y: 0)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control: CGPoint(x: width * 0.875, y: height)
        )
        
        // Complete the wave shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    NavigationView {
        GenreDetailView(genreName: "Pop", gradient: [.pink, .purple])
    }
}
