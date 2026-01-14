//
//  PinnedItem.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  PinnedItem.swift
//  Wave
//
//  Pinned item data model for Firebase
//

import Foundation
import FirebaseFirestore

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
