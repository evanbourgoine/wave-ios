//
//  Song.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Song.swift
//  Wave
//
//  Song data model
//

import Foundation

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String
    let artworkURL: String?
    let playCount: Int
    let totalMinutes: Int
}
