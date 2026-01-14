//
//  Rating.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Rating.swift
//  Wave
//
//  Rating data model for Firebase
//

import Foundation
import FirebaseFirestore

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
