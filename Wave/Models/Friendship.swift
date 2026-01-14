//
//  Friendship.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Friendship.swift
//  Wave
//
//  Friendship data model for Firebase
//

import Foundation
import FirebaseFirestore

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
