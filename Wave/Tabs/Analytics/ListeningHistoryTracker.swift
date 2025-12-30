//
//  ListeningHistoryTracker.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/23/25.
//

import Foundation
import SwiftUI

// MARK: - Listening Session Model

struct ListeningSession: Codable, Identifiable {
    let id: UUID
    let songTitle: String
    let artistName: String
    let albumTitle: String
    let timestamp: Date
    let duration: TimeInterval // in seconds
    
    init(id: UUID = UUID(), songTitle: String, artistName: String, albumTitle: String, timestamp: Date = Date(), duration: TimeInterval) {
        self.id = id
        self.songTitle = songTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.timestamp = timestamp
        self.duration = duration
    }
}

// MARK: - Listening History Tracker

@MainActor
class ListeningHistoryTracker: ObservableObject {
    static let shared = ListeningHistoryTracker()
    
    @Published var sessions: [ListeningSession] = []
    @Published var lastSyncDate: Date?
    
    private let sessionsKey = "listeningSessionsKey"
    private let lastSyncKey = "lastSyncDateKey"
    
    private init() {
        loadSessions()
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ListeningSession].self, from: data) {
            sessions = decoded
        }
        
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = lastSync
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    // MARK: - Track New Sessions
    
    func trackSession(_ session: ListeningSession) {
        sessions.append(session)
        saveSessions()
    }
    
    func trackMultipleSessions(_ newSessions: [ListeningSession]) {
        sessions.append(contentsOf: newSessions)
        saveSessions()
    }
    
    // MARK: - Sync with Apple Music
    
    func syncWithAppleMusic(recentSongs: [Song]) {
        // Convert recent songs to sessions if they're new
        let cutoffDate = lastSyncDate ?? Date.distantPast
        
        var newSessions: [ListeningSession] = []
        
        for song in recentSongs {
            // Create a session for each play (approximated)
            for _ in 0..<song.playCount {
                let session = ListeningSession(
                    songTitle: song.title,
                    artistName: song.artist,
                    albumTitle: song.album,
                    timestamp: Date(), // We don't have exact timestamp from MusicKit
                    duration: TimeInterval(song.totalMinutes * 60 / song.playCount)
                )
                newSessions.append(session)
            }
        }
        
        // Only add sessions we haven't tracked before
        let existingSongKeys = Set(sessions.map { "\($0.songTitle)-\($0.artistName)" })
        let uniqueNewSessions = newSessions.filter { session in
            !existingSongKeys.contains("\(session.songTitle)-\(session.artistName)")
        }
        
        if !uniqueNewSessions.isEmpty {
            trackMultipleSessions(uniqueNewSessions)
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            print("✅ Synced \(uniqueNewSessions.count) new listening sessions")
        }
    }
    
    // MARK: - Analytics from Local History
    
    func getTopSongs(limit: Int = 25, period: TimePeriod = .allTime) -> [Song] {
        let filteredSessions = filterSessions(by: period)
        
        // Count plays per song
        var songCounts: [String: (title: String, artist: String, album: String, count: Int, totalMinutes: Int)] = [:]
        
        for session in filteredSessions {
            let key = "\(session.songTitle)-\(session.artistName)"
            if var existing = songCounts[key] {
                existing.count += 1
                existing.totalMinutes += Int(session.duration / 60)
                songCounts[key] = existing
            } else {
                songCounts[key] = (session.songTitle, session.artistName, session.albumTitle, 1, Int(session.duration / 60))
            }
        }
        
        // Sort and convert
        return songCounts.values
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { data in
                Song(
                    title: data.title,
                    artist: data.artist,
                    album: data.album,
                    artworkURL: nil,
                    playCount: data.count,
                    totalMinutes: data.totalMinutes
                )
            }
    }
    
    func getTopArtists(limit: Int = 25, period: TimePeriod = .allTime) -> [Artist] {
        let filteredSessions = filterSessions(by: period)
        
        // Count plays per artist
        var artistCounts: [String: (name: String, count: Int, totalMinutes: Int, songs: Set<String>)] = [:]
        
        for session in filteredSessions {
            let artistName = session.artistName
            if var existing = artistCounts[artistName] {
                existing.count += 1
                existing.totalMinutes += Int(session.duration / 60)
                existing.songs.insert(session.songTitle)
                artistCounts[artistName] = existing
            } else {
                artistCounts[artistName] = (artistName, 1, Int(session.duration / 60), [session.songTitle])
            }
        }
        
        // Sort and convert
        return artistCounts.values
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { data in
                Artist(
                    name: data.name,
                    imageURL: nil,
                    playCount: data.count,
                    totalMinutes: data.totalMinutes,
                    topSongs: Array(data.songs.prefix(3))
                )
            }
    }
    
    func calculateStats(period: TimePeriod = .allTime) -> ListeningStats {
        let filteredSessions = filterSessions(by: period)
        
        let totalMinutes = filteredSessions.reduce(0) { $0 + Int($1.duration / 60) }
        let totalSongs = filteredSessions.count
        let uniqueArtists = Set(filteredSessions.map { $0.artistName }).count
        
        // Calculate session stats
        let sessionLengths = calculateSessionLengths(from: filteredSessions)
        let avgSession = sessionLengths.isEmpty ? 0 : sessionLengths.reduce(0, +) / sessionLengths.count
        let longestSession = sessionLengths.max() ?? 0
        
        return ListeningStats(
            totalMinutes: totalMinutes,
            totalSongs: totalSongs,
            totalArtists: uniqueArtists,
            topGenres: estimateGenresFromSessions(filteredSessions),
            averageSessionLength: avgSession,
            longestSession: longestSession
        )
    }
    
    func getDailyListening(days: Int = 30) -> [DailyListening] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group sessions by day
        var dailyMinutes: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.timestamp)
            dailyMinutes[day, default: 0] += Int(session.duration / 60)
        }
        
        // Create array for last N days
        return (0..<days).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let minutes = dailyMinutes[date] ?? 0
            return DailyListening(date: date, minutes: minutes)
        }
    }
    
    func getHourlyDistribution() -> [TimeDistribution] {
        var hourlyMinutes: [Int: Int] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.timestamp)
            hourlyMinutes[hour, default: 0] += Int(session.duration / 60)
        }
        
        return (0..<24).map { hour in
            TimeDistribution(hour: hour, minutes: hourlyMinutes[hour] ?? 0)
        }
    }
    
    // MARK: - Helper Functions
    
    private func filterSessions(by period: TimePeriod) -> [ListeningSession] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return sessions.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return sessions.filter { $0.timestamp >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return sessions.filter { $0.timestamp >= yearAgo }
        case .allTime:
            return sessions
        }
    }
    
    private func calculateSessionLengths(from sessions: [ListeningSession]) -> [Int] {
        // Group sessions that are close together (within 30 minutes)
        let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
        var sessionLengths: [Int] = []
        var currentSessionMinutes = 0
        var lastTimestamp: Date?
        
        for session in sortedSessions {
            if let last = lastTimestamp, session.timestamp.timeIntervalSince(last) > 1800 { // 30 min gap
                if currentSessionMinutes > 0 {
                    sessionLengths.append(currentSessionMinutes)
                }
                currentSessionMinutes = 0
            }
            currentSessionMinutes += Int(session.duration / 60)
            lastTimestamp = session.timestamp
        }
        
        if currentSessionMinutes > 0 {
            sessionLengths.append(currentSessionMinutes)
        }
        
        return sessionLengths
    }
    
    private func estimateGenresFromSessions(_ sessions: [ListeningSession]) -> [Genre] {
        // This is still estimated - we'd need additional data to determine genres
        // For now, return mock genres
        return [
            Genre(name: "Your Top Genre", percentage: 28, color: .purple),
            Genre(name: "Second Favorite", percentage: 24, color: .blue),
            Genre(name: "Third Choice", percentage: 20, color: .pink),
            Genre(name: "Fourth", percentage: 16, color: .orange),
            Genre(name: "Others", percentage: 12, color: .green)
        ]
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        sessions = []
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: sessionsKey)
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
        print("✅ Cleared all listening history")
    }
    
    enum TimePeriod {
        case week, month, year, allTime
    }
}
