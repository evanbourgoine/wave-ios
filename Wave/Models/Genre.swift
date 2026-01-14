//
//  Genre.swift
//  Wave
//
//  Created by Evan M Bourgoine on 12/30/25.
//

//
//  Genre.swift
//  Wave
//
//  Genre data model
//

import Foundation
import SwiftUI

struct Genre: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}
