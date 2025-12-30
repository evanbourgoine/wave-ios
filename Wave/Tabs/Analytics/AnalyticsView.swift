//
//  AnalyticsView.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var musicService = MusicKitService.shared
    @StateObject private var historyTracker = ListeningHistoryTracker.shared
    @State private var selectedPeriod: TimePeriod = .month
    @State private var stats: ListeningStats = MockDataService.shared.stats
    @State private var topSongs: [Song] = []
    @State private var topArtists: [Artist] = []
    @State private var dailyListening: [DailyListening] = []
    @State private var hourlyDistribution: [TimeDistribution] = []
    @State private var isLoadingData = false
    @State private var useLocalData = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    // Convert to tracker period
    private var trackerPeriod: ListeningHistoryTracker.TimePeriod {
        switch selectedPeriod {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        case .allTime: return .allTime
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Data Source Info
                    dataSourceInfo
                    
                    // Show loading or content
                    if isLoadingData {
                        ProgressView("Loading your stats...")
                            .padding(.top, 100)
                    } else {
                        // Overview Stats Cards
                        overviewStatsGrid
                        
                        // Listening Activity Chart
                        listeningActivitySection
                        
                        // Time of Day Chart
                        timeOfDaySection
                        
                        // Top Genres
                        topGenresSection
                        
                        // Top Songs
                        topSongsSection
                        
                        // Top Artists
                        topArtistsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadData()
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .onChange(of: selectedPeriod) { _ in
            Task {
                await loadData()
            }
        }
    }
    
    // MARK: - Data Source Info
    
    private var dataSourceInfo: some View {
        VStack(spacing: 8) {
            if !useLocalData && topSongs.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Loading your music data...")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Make sure you have an Apple Music subscription")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            } else if !useLocalData && !topSongs.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Showing recent listening • Charts are estimated for now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else if useLocalData {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Using comprehensive data (\(historyTracker.sessions.count) tracked sessions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Load Data
    
    private func loadData() async {
        guard musicService.isAuthorized else { return }
        
        isLoadingData = true
        defer { isLoadingData = false }
        
        // Always fetch from Apple Music first
        async let statsTask = musicService.calculateListeningStats()
        async let songsTask = musicService.fetchTopSongs(limit: 30) // Fetch all 30
        async let artistsTask = musicService.fetchTopArtists(limit: 30) // Fetch all artists
        
        stats = await statsTask
        topSongs = await songsTask
        topArtists = await artistsTask
        
        print("📊 Loaded \(topSongs.count) songs and \(topArtists.count) artists")
        
        // Check if we have local tracking data for charts
        useLocalData = historyTracker.sessions.count > 50
        
        if useLocalData {
            // Use local data for accurate charts
            dailyListening = historyTracker.getDailyListening(days: 30)
            hourlyDistribution = historyTracker.getHourlyDistribution()
            print("📊 Using local tracking for charts (\(historyTracker.sessions.count) sessions)")
        } else {
            // Use mock data for charts temporarily
            dailyListening = MockDataService.shared.getDailyListening()
            hourlyDistribution = MockDataService.shared.getHourlyDistribution()
            
            // Sync with local tracker to start building history
            historyTracker.syncWithAppleMusic(recentSongs: topSongs)
            print("📊 Using estimated charts (building local history: \(historyTracker.sessions.count) sessions)")
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Overview Stats
    
    private var overviewStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Minutes card - not tappable
            StatCard(
                title: "Minutes",
                value: formatNumber(stats.totalMinutes),
                subtitle: "\(stats.totalMinutes / 60) hours",
                icon: "clock.fill",
                color: .blue
            )
            
            // Songs card - tappable
            NavigationLink(destination: AllSongsView(songs: topSongs, period: selectedPeriod.rawValue)) {
                StatCard(
                    title: "Songs",
                    value: formatNumber(stats.totalSongs),
                    subtitle: "tap to view all",
                    icon: "music.note",
                    color: .purple
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Artists card - tappable
            NavigationLink(destination: AllArtistsView(artists: topArtists, period: selectedPeriod.rawValue)) {
                StatCard(
                    title: "Artists",
                    value: formatNumber(stats.totalArtists),
                    subtitle: "tap to view all",
                    icon: "person.2.fill",
                    color: .pink
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Avg Session card - not tappable
            StatCard(
                title: "Avg Session",
                value: "\(stats.averageSessionLength)",
                subtitle: "minutes",
                icon: "waveform",
                color: .orange
            )
        }
    }
    
    // MARK: - Listening Activity Section
    
    private var listeningActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Listening Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ChartCard {
                Chart(dailyListening) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)m")
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
            }
            
            if !useLocalData {
                Text("Daily breakdown will improve as you use Wave")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Time of Day Section
    
    private var timeOfDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Peak Listening Hours")
                .font(.headline)
                .padding(.horizontal)
            
            ChartCard {
                Chart(hourlyDistribution) { item in
                    AreaMark(
                        x: .value("Hour", item.hour),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .pink.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text(formatHour(hour))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)m")
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
            
            if useLocalData {
                let peakHour = hourlyDistribution.max(by: { $0.minutes < $1.minutes })?.hour ?? 21
                Text("You listen most around \(formatHour(peakHour))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Time patterns will improve as you use Wave")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Top Genres Section
    
    private var topGenresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Genres")
                .font(.headline)
                .padding(.horizontal)
            
            ChartCard {
                VStack(spacing: 12) {
                    ForEach(stats.topGenres) { genre in
                        HStack {
                            Text(genre.name)
                                .font(.subheadline)
                                .frame(width: 80, alignment: .leading)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(genre.color)
                                        .frame(width: geometry.size.width * (genre.percentage / 100))
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(Int(genre.percentage))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Top Songs Section
    
    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs")
                    .font(.headline)
                Spacer()
                if !topSongs.isEmpty {
                    NavigationLink(destination: AllSongsView(songs: topSongs, period: selectedPeriod.rawValue)) {
                        Text("See All")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
            
            ChartCard {
                VStack(spacing: 0) {
                    if topSongs.isEmpty {
                        Text("No songs data available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(topSongs.prefix(5).enumerated()), id: \.element.id) { index, song in
                            SongRow(song: song, rank: index + 1)
                            
                            if index < min(4, topSongs.count - 1) {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Top Artists Section
    
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Artists")
                    .font(.headline)
                Spacer()
                if !topArtists.isEmpty {
                    NavigationLink(destination: AllArtistsView(artists: topArtists, period: selectedPeriod.rawValue)) {
                        Text("See All")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
            
            ChartCard {
                VStack(spacing: 0) {
                    if topArtists.isEmpty {
                        Text("No artists data available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(topArtists.prefix(5).enumerated()), id: \.element.id) { index, artist in
                            ArtistRow(artist: artist, rank: index + 1)
                            
                            if index < min(4, topArtists.count - 1) {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12AM" }
        if hour < 12 { return "\(hour)AM" }
        if hour == 12 { return "12PM" }
        return "\(hour - 12)PM"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ChartCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }
}

struct SongRow: View {
    let song: Song
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Artwork
            if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 4)
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
                            .cornerRadius(4)
                    case .failure:
                        RoundedRectangle(cornerRadius: 4)
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
                RoundedRectangle(cornerRadius: 4)
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
            
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(song.playCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("plays")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ArtistRow: View {
    let artist: Artist
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Artist image placeholder
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
            
            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(formatMinutes(artist.totalMinutes)) • \(artist.playCount) plays")
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
        .padding(.vertical, 8)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    AnalyticsView()
}
