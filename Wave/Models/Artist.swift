//
//  Artist.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Artist.swift
//  Wave
//
//  Artist data model
//

import Foundation

struct Artist: Identifiable {
    let id = UUID()
    let name: String
    let imageURL: String?
    let playCount: Int
    let totalMinutes: Int
    let topSongs: [String]
}
