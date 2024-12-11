//
//  Timestamp.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 11/12/2024.
//

import SwiftUI


struct Timestamp: Codable, Hashable {
    let _seconds: Int64
    let _nanoseconds: Int64
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(_seconds))
    }
}
