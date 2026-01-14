//
//  Analytics.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Analytics.swift
//  Wave
//
//  Analytics data models
//

import Foundation

// MARK: - Listening Stats

struct ListeningStats {
    let totalMinutes: Int
    let totalSongs: Int
    let totalArtists: Int
    let topGenres: [Genre]
    let averageSessionLength: Int // in minutes
    let longestSession: Int // in minutes
}

// MARK: - Time Distribution

struct TimeDistribution: Identifiable {
    let id = UUID()
    let hour: Int
    let minutes: Int
}

// MARK: - Daily Listening

struct DailyListening: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}
