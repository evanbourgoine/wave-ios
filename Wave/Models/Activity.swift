//
//  Activity.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Activity.swift
//  Wave
//
//  User activity data model for Firebase
//

import Foundation
import FirebaseFirestore

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
