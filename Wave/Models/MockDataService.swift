//
//  MockDataService.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  MockDataService.swift
//  Wave
//
//  Mock data for development and testing
//

import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    let stats = ListeningStats(
        totalMinutes: 12847,
        totalSongs: 2456,
        totalArtists: 342,
        topGenres: [
            Genre(name: "Indie", percentage: 32, color: .purple),
            Genre(name: "Electronic", percentage: 24, color: .blue),
            Genre(name: "R&B", percentage: 18, color: .pink),
            Genre(name: "Rock", percentage: 15, color: .orange),
            Genre(name: "Hip-Hop", percentage: 11, color: .green)
        ],
        averageSessionLength: 42,
        longestSession: 287
    )
    
    let topSongs: [Song] = [
        Song(title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", artworkURL: nil, playCount: 147, totalMinutes: 612),
        Song(title: "Redbone", artist: "Childish Gambino", album: "Awaken, My Love!", artworkURL: nil, playCount: 132, totalMinutes: 693),
        Song(title: "Electric Feel", artist: "MGMT", album: "Oracular Spectacular", artworkURL: nil, playCount: 128, totalMinutes: 537),
        Song(title: "Do I Wanna Know?", artist: "Arctic Monkeys", album: "AM", artworkURL: nil, playCount: 119, totalMinutes: 496),
        Song(title: "The Less I Know The Better", artist: "Tame Impala", album: "Currents", artworkURL: nil, playCount: 115, totalMinutes: 460)
    ]
    
    let topArtists: [Artist] = [
        Artist(name: "Tame Impala", imageURL: nil, playCount: 342, totalMinutes: 1428, topSongs: ["The Less I Know The Better", "Let It Happen", "Feels Like We Only Go Backwards"]),
        Artist(name: "Frank Ocean", imageURL: nil, playCount: 298, totalMinutes: 1243, topSongs: ["Ivy", "Nights", "Pink + White"]),
        Artist(name: "The Weeknd", imageURL: nil, playCount: 287, totalMinutes: 1197, topSongs: ["Blinding Lights", "Save Your Tears", "Die For You"]),
        Artist(name: "Arctic Monkeys", imageURL: nil, playCount: 256, totalMinutes: 1067, topSongs: ["Do I Wanna Know?", "505", "R U Mine?"]),
        Artist(name: "Childish Gambino", imageURL: nil, playCount: 234, totalMinutes: 976, topSongs: ["Redbone", "3005", "Sweatpants"])
    ]
    
    // Generate listening time distribution (by hour of day)
    func getHourlyDistribution() -> [TimeDistribution] {
        let hourlyData: [(Int, Int)] = [
            (0, 12), (1, 8), (2, 5), (3, 3), (4, 2), (5, 4),
            (6, 15), (7, 32), (8, 45), (9, 52), (10, 61), (11, 58),
            (12, 47), (13, 52), (14, 68), (15, 75), (16, 82), (17, 71),
            (18, 63), (19, 58), (20, 72), (21, 89), (22, 94), (23, 45)
        ]
        
        return hourlyData.map { TimeDistribution(hour: $0.0, minutes: $0.1) }
    }
    
    // Generate daily listening for the past 30 days
    func getDailyListening() -> [DailyListening] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let minutes = Int.random(in: 20...180)
            return DailyListening(date: date, minutes: minutes)
        }
    }
}
