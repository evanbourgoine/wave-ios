//
//  User.swift
//  Wave
//
//  User data model for Firebase
//

import Foundation
import FirebaseFirestore

// MARK: - User Model

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var realName: String?
    var email: String
    var profilePictureURL: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Stats
    var totalSongsPlayed: Int
    var uniqueArtistsCount: Int
    var totalListeningHours: Double
    var currentStreakDays: Int
    
    // Privacy
    var isProfilePublic: Bool
    var allowFriendRequests: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case realName = "real_name"
        case email
        case profilePictureURL = "profile_picture_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalSongsPlayed = "total_songs_played"
        case uniqueArtistsCount = "unique_artists_count"
        case totalListeningHours = "total_listening_hours"
        case currentStreakDays = "current_streak_days"
        case isProfilePublic = "is_profile_public"
        case allowFriendRequests = "allow_friend_requests"
    }
    
    // Default initializer
    init(
        id: String? = nil,
        username: String,
        realName: String? = nil,
        email: String,
        profilePictureURL: String? = nil,
        bio: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        totalSongsPlayed: Int = 0,
        uniqueArtistsCount: Int = 0,
        totalListeningHours: Double = 0.0,
        currentStreakDays: Int = 0,
        isProfilePublic: Bool = true,
        allowFriendRequests: Bool = true
    ) {
        self.id = id
        self.username = username
        self.realName = realName
        self.email = email
        self.profilePictureURL = profilePictureURL
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalSongsPlayed = totalSongsPlayed
        self.uniqueArtistsCount = uniqueArtistsCount
        self.totalListeningHours = totalListeningHours
        self.currentStreakDays = currentStreakDays
        self.isProfilePublic = isProfilePublic
        self.allowFriendRequests = allowFriendRequests
    }
}

// MARK: - Activity Model

struct Activity: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var activityType: ActivityType
    var itemId: String // Song/Album/Artist ID
    var itemTitle: String
    var itemSubtitle: String // Artist name or album name
    var timestamp: Date
    var friendId: String? // If activity is friend-related
    
    enum ActivityType: String, Codable {
        case played = "played"
        case loved = "loved"
        case rated = "rated"
        case shared = "shared"
        case friendPlayed = "friend_played"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case itemId = "item_id"
        case itemTitle = "item_title"
        case itemSubtitle = "item_subtitle"
        case timestamp
        case friendId = "friend_id"
    }
}

// MARK: - Rating Model

struct Rating: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var itemId: String
    var itemType: RatingItemType
    var itemTitle: String
    var itemSubtitle: String // Artist or album artist
    var rating: Double // 0.0 to 5.0, increments of 0.5
    var ratedAt: Date
    
    enum RatingItemType: String, Codable {
        case song = "song"
        case album = "album"
        case artist = "artist"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case itemTitle = "item_title"
        case itemSubtitle = "item_subtitle"
        case rating
        case ratedAt = "rated_at"
    }
}

// MARK: - Pinned Item Model

struct PinnedItem: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var itemId: String
    var itemType: PinnedItemType
    var itemTitle: String
    var itemSubtitle: String
    var artworkURL: String?
    var pinnedAt: Date
    
    enum PinnedItemType: String, Codable {
        case song = "song"
        case album = "album"
        case artist = "artist"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case itemTitle = "item_title"
        case itemSubtitle = "item_subtitle"
        case artworkURL = "artwork_url"
        case pinnedAt = "pinned_at"
    }
}

// MARK: - Top Artist Model

struct TopArtist: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var artistId: String
    var artistName: String
    var artistImageURL: String?
    var playCount: Int
    var timePeriod: TimePeriod
    var ranking: Int
    var updatedAt: Date
    
    enum TimePeriod: String, Codable {
        case week = "week"
        case month = "month"
        case year = "year"
        case allTime = "all_time"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case artistName = "artist_name"
        case artistImageURL = "artist_image_url"
        case playCount = "play_count"
        case timePeriod = "time_period"
        case ranking
        case updatedAt = "updated_at"
    }
}

// MARK: - Friendship Model

struct Friendship: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var friendId: String
    var friendUsername: String
    var friendProfilePictureURL: String?
    var status: FriendshipStatus
    var createdAt: Date
    
    enum FriendshipStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case blocked = "blocked"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case friendUsername = "friend_username"
        case friendProfilePictureURL = "friend_profile_picture_url"
        case status
        case createdAt = "created_at"
    }
}

// MARK: - User Listening Stats Model (Firebase)

struct UserListeningStats: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var timePeriod: TopArtist.TimePeriod
    var totalHours: Double
    var topGenre: String
    var topGenrePercentage: Double
    var mostPlayedSongId: String
    var mostPlayedSongTitle: String
    var mostPlayedSongArtist: String
    var mostPlayedSongCount: Int
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case timePeriod = "time_period"
        case totalHours = "total_hours"
        case topGenre = "top_genre"
        case topGenrePercentage = "top_genre_percentage"
        case mostPlayedSongId = "most_played_song_id"
        case mostPlayedSongTitle = "most_played_song_title"
        case mostPlayedSongArtist = "most_played_song_artist"
        case mostPlayedSongCount = "most_played_song_count"
        case updatedAt = "updated_at"
    }
}
