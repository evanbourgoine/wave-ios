//
//  Album.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Album.swift
//  Wave
//
//  Album data model
//

import Foundation

struct Album: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let artworkURL: String?
    let playCount: Int
}
