//
//  Messaging.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Messaging.swift
//  Wave
//
//  Direct messaging data models
//

import Foundation
import FirebaseFirestore

// MARK: - Conversation Model

struct Conversation: Codable, Identifiable {
    @DocumentID var id: String?
    var participantIds: [String] // Array of user IDs
    var participantNames: [String: String] // userId: username mapping
    var participantProfilePictures: [String: String] // userId: profilePictureURL mapping
    var lastMessage: String?
    var lastMessageSenderId: String?
    var lastMessageTimestamp: Date?
    var unreadCount: [String: Int] // userId: unread count mapping
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case participantIds = "participant_ids"
        case participantNames = "participant_names"
        case participantProfilePictures = "participant_profile_pictures"
        case lastMessage = "last_message"
        case lastMessageSenderId = "last_message_sender_id"
        case lastMessageTimestamp = "last_message_timestamp"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Message Model

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var messageType: MessageType
    var content: String
    var mediaURL: String? // For images, audio, etc.
    var musicItemId: String? // For sharing songs/albums/artists
    var musicItemType: MusicItemType?
    var musicItemTitle: String?
    var musicItemArtist: String?
    var musicItemArtwork: String?
    var timestamp: Date
    var isRead: Bool
    var readAt: Date?
    
    enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case audio = "audio"
        case musicShare = "music_share" // Sharing songs/albums/artists
        case activityShare = "activity_share" // "I'm listening to..."
    }
    
    enum MusicItemType: String, Codable {
        case song = "song"
        case album = "album"
        case artist = "artist"
        case playlist = "playlist"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case messageType = "message_type"
        case content
        case mediaURL = "media_url"
        case musicItemId = "music_item_id"
        case musicItemType = "music_item_type"
        case musicItemTitle = "music_item_title"
        case musicItemArtist = "music_item_artist"
        case musicItemArtwork = "music_item_artwork"
        case timestamp
        case isRead = "is_read"
        case readAt = "read_at"
    }
}

// MARK: - Typing Indicator Model

struct TypingIndicator: Codable {
    var conversationId: String
    var userId: String
    var username: String
    var isTyping: Bool
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userId = "user_id"
        case username
        case isTyping = "is_typing"
        case timestamp
    }
}

// MARK: - Push Notification Token Model

struct PushToken: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var token: String
    var platform: Platform
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum Platform: String, Codable {
        case ios = "ios"
        case android = "android"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case token
        case platform
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Presence Model

struct UserPresence: Codable {
    var userId: String
    var status: PresenceStatus
    var lastSeen: Date
    var currentlyListeningTo: CurrentlyListening?
    
    enum PresenceStatus: String, Codable {
        case online = "online"
        case offline = "offline"
        case away = "away"
    }
    
    struct CurrentlyListening: Codable {
        var songTitle: String
        var artistName: String
        var artworkURL: String?
        var startedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case songTitle = "song_title"
            case artistName = "artist_name"
            case artworkURL = "artwork_url"
            case startedAt = "started_at"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case lastSeen = "last_seen"
        case currentlyListeningTo = "currently_listening_to"
    }
}
